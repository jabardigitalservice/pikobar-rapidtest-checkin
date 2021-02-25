import 'dart:async';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/list_participants/Bloc.dart';
import 'package:rapid_test/blocs/offline/list_checkin_offline/Bloc.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/components/EmptyData.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/repositories/ListParticipantRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';

import 'offline/checkin_list.dart';

class ParticipantListPage extends StatefulWidget {
  final KodeKegiatanModel kodeKegiatanModel;
  ParticipantListPage({Key key, this.kodeKegiatanModel}) : super(key: key);
  @override
  _ParticipantListPageState createState() => _ParticipantListPageState();
}

class _ParticipantListPageState extends State<ParticipantListPage> {
  final ListParticipantRepository _listParticipantRepository =
      ListParticipantRepository();
  ListParticipantBloc _listParticipantBloc;
  TextEditingController _searchController = TextEditingController();
  String searchQuery;
  ScrollController _scrollController = ScrollController();
  int maxDataLength;
  int _page = 1;
  Timer _debounce;
  var containerWidth = 40.0;
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  final OfflineRepository _offlineRepository = OfflineRepository();
  int lengthDataOffline = 0;

  @override
  void initState() {
    _initialize();

    _scrollController.addListener(() {
      _scrollListener();
    });
    AnalyticsHelper.setLogEvent(Analytics.listParticipantScreen);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.bottomSearchAppBar(
          customBackButton: true,
          searchController: _searchController,
          title: Dictionary.listParticipant,
          hintText: Dictionary.searchListParticipant,
          onSubmitted: updateSearchQuery,
          context: context),
      backgroundColor: Colors.white,
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ListParticipantBloc>(
            create: (context) => _listParticipantBloc =
                ListParticipantBloc(repository: _listParticipantRepository)
                  ..add(ListParticipantLoad(
                      eventCode: widget.kodeKegiatanModel.data.eventCode,
                      page: _page,
                      keyword: '',
                      isFirstLoad: true)),
          ),
          BlocProvider<AuthenticationBloc>(
              create: (context) => _authenticationBloc =
                  AuthenticationBloc(_authenticationRepository)),
          BlocProvider<ListCheckinOfflineBloc>(
              create: (context) =>
                  ListCheckinOfflineBloc(repository: _offlineRepository)
                    ..add(ListCheckinOfflineLoad())),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<ListCheckinOfflineBloc, ListCheckinOfflineState>(
              listener: (BuildContext context, ListCheckinOfflineState state) {
                if (state is ListCheckinOfflineLoaded) {
                  lengthDataOffline = state.checkinOfflineModel.length;
                  if (lengthDataOffline != 0) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Theme.of(context).primaryColor,
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Ada ${lengthDataOffline.toString()} Data Offline ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: FontsFamily.roboto),
                            ),
                            Container(
                              height: 20,
                              width: 80,
                              child: RaisedButton(
                                color: Colors.blue,
                                onPressed: () async {
                                  lengthDataOffline = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CheckinList()));
                                  if (lengthDataOffline == 0) {
                                    Scaffold.of(context).hideCurrentSnackBar();
                                    _listParticipantBloc.add(
                                        ListParticipantLoad(
                                            eventCode: widget.kodeKegiatanModel
                                                .data.eventCode,
                                            page: 1,
                                            keyword: _searchController.text));
                                  }
                                },
                                child: Text(
                                  Dictionary.check,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                          ],
                        ),
                        duration: Duration(minutes: 2),
                      ),
                    );
                  }
                }
              },
            ),
            BlocListener<ListParticipantBloc, ListParticipantState>(
                listener: (BuildContext context, ListParticipantState state) {
              if (state is ListParticipantFailure) {
                if (state.error.toString().contains(Dictionary.tokenExpired)) {
                  _authenticationBloc.add(UserLoggedOut());
                } else {
                  final List<String> split =
                      state.error.split(Dictionary.exeption);
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => DialogTextOnly(
                            description: split.last.toString(),
                            buttonText: Dictionary.ok,
                            onOkPressed: () {
                              Navigator.of(context).pop();
                              _listParticipantBloc.add(ListParticipantLoad(
                                  eventCode:
                                      widget.kodeKegiatanModel.data.eventCode,
                                  page: 1,
                                  keyword: '')); // To close the dialog
                            },
                          ));
                }
                Scaffold.of(context).hideCurrentSnackBar();
              }
            }),
            BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (BuildContext context, AuthenticationState state) {
              if (state is AuthenticationNotAuthenticated) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
                AnalyticsHelper.setLogEvent(Analytics.userTimeOut);
              }
            })
          ],
          child: BlocBuilder<ListParticipantBloc, ListParticipantState>(
            builder: (
              BuildContext context,
              ListParticipantState state,
            ) {
              if (state is ListParticipantLoaded) {
                _updatePage(state.listParticipantModel);
                maxDataLength = state.maxData;
                return buildItem(state);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildItem(ListParticipantLoaded state) {
    return SafeArea(
      child: ConnectivityWidgetWrapper(
          stacked: false,
          offlineWidget: EmptyData(
            message: Dictionary.errorConnection,
            desc: Dictionary.errorConnectionDesc,
            image: "${Environment.imageAssets}not_found.png",
          ),
          child: state.listParticipantModel.length == 0
              ? Center(
                  child: Text(Dictionary.emptyDataParticipant),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: LiquidPullToRefresh(
                        showChildOpacityTransition: false,
                        height: 50,
                        color: ColorBase.green,
                        onRefresh: () async {
                          _listParticipantBloc.add(ListParticipantLoad(
                              eventCode:
                                  widget.kodeKegiatanModel.data.eventCode,
                              page: 1,
                              keyword: _searchController.text));
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: state.listParticipantModel.length + 1,
                          itemBuilder: (BuildContext context, int i) {
                            if (i == state.listParticipantModel.length) {
                              if (state.listParticipantModel.length > 15 &&
                                  maxDataLength !=
                                      state.listParticipantModel.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20.0, bottom: 20.0),
                                  child: Column(
                                    children: <Widget>[
                                      CupertinoActivityIndicator(),
                                      const SizedBox(
                                        height: 5.0,
                                      ),
                                      Text(Dictionary.dataParticipantLoading),
                                    ],
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            }

                            return Column(
                              children: [
                                i == 0
                                    ? Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 10,
                                            top: 5,
                                            left: 20,
                                            right: 20),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 10),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                                '${Environment.imageAssets}group_people.png',
                                                width: 120),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(children: [
                                                  /// Set Text content section
                                                  TextSpan(
                                                    text: Dictionary
                                                        .listParticipantDescription,
                                                    style: TextStyle(
                                                        color: Colors.black
                                                            .withOpacity(0.6),
                                                        fontFamily:
                                                            FontsFamily.roboto,
                                                        fontSize: 14),
                                                  ),
                                                  TextSpan(
                                                      text: widget
                                                          .kodeKegiatanModel
                                                          .data
                                                          .eventName,
                                                      style: TextStyle(
                                                          color: Colors.black
                                                              .withOpacity(0.6),
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontFamily:
                                                              FontsFamily
                                                                  .roboto,
                                                          fontSize: 14)),
                                                ]),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    : Container(),
                                Container(
                                  margin: EdgeInsets.only(
                                      bottom: i ==
                                              state.listParticipantModel
                                                      .length -
                                                  1
                                          ? 20
                                          : 0,
                                      top: i == 0 ? 5 : 0,
                                      left: 20,
                                      right: 20),
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(i ==
                                                  state.listParticipantModel
                                                          .length -
                                                      1
                                              ? 6
                                              : 0),
                                          bottomRight: Radius.circular(
                                              i == state.listParticipantModel.length - 1
                                                  ? 6
                                                  : 0),
                                          topLeft:
                                              Radius.circular(i == 0 ? 6 : 0),
                                          topRight:
                                              Radius.circular(i == 0 ? 6 : 0)),
                                      color: state.listParticipantModel[i]
                                                  .attendedAt ==
                                              null
                                          ? Colors.white
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: Colors.grey[300],
                                        width: 1,
                                      )),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Image.asset(
                                                    '${Environment.iconAssets}people_icon.png',
                                                    width: 13),
                                                const SizedBox(
                                                  width: 15,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.4,
                                                      child: Text(
                                                          state
                                                              .listParticipantModel[
                                                                  i]
                                                              .name,
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.8),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontFamily:
                                                                  FontsFamily
                                                                      .roboto,
                                                              fontSize: 16)),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    Text(
                                                        state
                                                            .listParticipantModel[
                                                                i]
                                                            .registrationCode,
                                                        style:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.6),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontFamily:
                                                                    FontsFamily
                                                                        .roboto,
                                                                fontSize: 12)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 7),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color:
                                                      state.listParticipantModel[i]
                                                                  .attendedAt ==
                                                              null
                                                          ? ColorBase.yellow700
                                                          : ColorBase.green2),
                                              child: Text(
                                                state.listParticipantModel[i]
                                                            .attendedAt ==
                                                        null
                                                    ? Dictionary.absent
                                                    : Dictionary.present,
                                                style: TextStyle(
                                                    fontFamily:
                                                        FontsFamily.roboto,
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const SizedBox(
                                              width: 28,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    Dictionary.labCode,
                                                    style: TextStyle(
                                                        color: Colors.black
                                                            .withOpacity(0.6),
                                                        fontFamily:
                                                            FontsFamily.roboto,
                                                        fontSize: 10),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    state
                                                                .listParticipantModel[
                                                                    i]
                                                                .labCodeSample ==
                                                            null
                                                        ? '-'
                                                        : state
                                                            .listParticipantModel[
                                                                i]
                                                            .labCodeSample,
                                                    style: TextStyle(
                                                        color: Colors.black
                                                            .withOpacity(0.8),
                                                        fontFamily:
                                                            FontsFamily.roboto,
                                                        fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  Dictionary.checkinDate,
                                                  style: TextStyle(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      fontFamily:
                                                          FontsFamily.roboto,
                                                      fontSize: 10),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  state.listParticipantModel[i]
                                                              .attendedAt ==
                                                          null
                                                      ? '-'
                                                      : unixTimeStampToDateTime(
                                                              state
                                                                  .listParticipantModel[
                                                                      i]
                                                                  .attendedAt) +
                                                          Dictionary.wib,
                                                  style: TextStyle(
                                                      color: Colors.black
                                                          .withOpacity(0.8),
                                                      fontFamily:
                                                          FontsFamily.roboto,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )),
    );
  }

  void _initialize() async {
    _page = await Preferences.getDataInt(kParticipantPage) != null
        ? await Preferences.getDataInt(kParticipantPage)
        : 1;
    maxDataLength = await Preferences.getDataInt(kTotalCount) != null
        ? await Preferences.getDataInt(kTotalCount)
        : 0;
  }

  void _updatePage(List<DataParticipant> records) async {
    final double tempPage = (records.length / 20);
    final List<String> listPage = tempPage.toString().split('.');
    if (int.parse(listPage[1]) < 50 && int.parse(listPage[1]) != 0) {
      _page = (tempPage + 0.95).round() + 1;
    } else {
      _page = (records.length / 20).round() + 1;
    }
    await Preferences.setDataInt(kParticipantPage, _page);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _listParticipantBloc.add(ListParticipantLoadMore(
        eventCode: widget.kodeKegiatanModel.data.eventCode,
        page: _page,
        keyword: _searchController.text,
      ));
      // }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _listParticipantBloc.add(ListParticipantLoad(
        eventCode: widget.kodeKegiatanModel.data.eventCode,
        page: 1,
        keyword: _searchController.text,
      ));
      AnalyticsHelper.setLogEvent(Analytics.tappedSearchParticipant);
    });
  }

  void updateSearchQuery(String newQuery) {
    _onSearchChanged();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _authenticationBloc.close();
    _listParticipantBloc.close();
    super.dispose();
  }
}
