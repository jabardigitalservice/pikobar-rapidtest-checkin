import 'dart:async';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/offline/list_checkin_offline/Bloc.dart';
import 'package:rapid_test/blocs/offline/list_participants_offline/Bloc.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/screen/offline/checkin_list.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/FormatDate.dart';

class ParticipantListOfflinePage extends StatefulWidget {
  final KodeKegiatanModel kodeKegiatanModel;
  ParticipantListOfflinePage({Key key, this.kodeKegiatanModel})
      : super(key: key);
  @override
  _ParticipantListOfflinePageState createState() =>
      _ParticipantListOfflinePageState();
}

class _ParticipantListOfflinePageState
    extends State<ParticipantListOfflinePage> {
  final OfflineRepository _offlineRepository = OfflineRepository();
  ListParticipantOfflineBloc _listParticipantBloc;
  TextEditingController _searchController = TextEditingController();
  String searchQuery;
  ScrollController _scrollController = ScrollController();
  int maxDataLength;
  Timer _debounce;
  double containerWidth = 40.0;

  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  int lengthDataOffline = 0;

  @override
  void initState() {
    AnalyticsHelper.setLogEvent(Analytics.listParticipantOfflineScreen);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.bottomSearchAppBar(
          customBackButton: true,
          searchController: _searchController,
          title: Dictionary.listParticipant,
          hintText: Dictionary.searchListParticipant,
          onSubmitted: updateSearchQuery,
          context: context),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ListParticipantOfflineBloc>(
            create: (context) => _listParticipantBloc =
                ListParticipantOfflineBloc(repository: _offlineRepository)
                  ..add(ListParticipantOfflineLoad()),
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
                                    _listParticipantBloc
                                        .add(ListParticipantOfflineLoad());
                                  }
                                },
                                child: Text(
                                  Dictionary.check,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: FontsFamily.roboto),
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
            BlocListener<ListParticipantOfflineBloc,
                    ListParticipantOfflineState>(
                listener:
                    (BuildContext context, ListParticipantOfflineState state) {
              if (state is ListParticipantOfflineFailure) {
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
                              _listParticipantBloc.add(
                                  ListParticipantOfflineLoad()); // To close the dialog
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
              }
            })
          ],
          child: BlocBuilder<ListParticipantOfflineBloc,
              ListParticipantOfflineState>(
            builder: (
              BuildContext context,
              ListParticipantOfflineState state,
            ) {
              if (state is ListParticipantOfflineLoaded) {
                return SafeArea(
                    child: state.listParticipantOfflineModel.length == 0
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
                                    _listParticipantBloc
                                        .add(ListParticipantOfflineLoad());
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: state
                                        .listParticipantOfflineModel.length,
                                    itemBuilder: (context, i) {
                                      return Column(
                                        children: [
                                          i == 0
                                              ? Column(
                                                  children: [
                                                    ConnectivityWidgetWrapper(
                                                      stacked: false,
                                                      offlineWidget: Container(
                                                        width: MediaQuery.of(
                                                                context)
                                                            .size
                                                            .width,
                                                        height: 50,
                                                        color: Colors.red,
                                                        child: Center(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .symmetric(
                                                                    horizontal:
                                                                        10),
                                                            child: Text(
                                                              lengthDataOffline !=
                                                                      0
                                                                  ? Dictionary
                                                                          .offlineModeListParticipant +
                                                                      Dictionary
                                                                          .pleaseSendOfflineData
                                                                  : Dictionary
                                                                      .offlineModeListParticipant,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      FontsFamily
                                                                          .roboto,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Container(),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 10,
                                                              top: 5,
                                                              left: 20,
                                                              right: 20),
                                                      width:
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          vertical: 15,
                                                          horizontal: 10),
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
                                                              text: TextSpan(
                                                                  children: [
                                                                    /// Set Text content section
                                                                    TextSpan(
                                                                      text: Dictionary
                                                                          .listParticipantDescription,
                                                                      style: TextStyle(
                                                                          color: Colors.black.withOpacity(
                                                                              0.6),
                                                                          fontFamily: FontsFamily
                                                                              .roboto,
                                                                          fontSize:
                                                                              14),
                                                                    ),
                                                                    TextSpan(
                                                                        text: widget
                                                                            .kodeKegiatanModel
                                                                            .data
                                                                            .eventName,
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black.withOpacity(0.6),
                                                                            fontWeight: FontWeight.w700,
                                                                            fontFamily: FontsFamily.roboto,
                                                                            fontSize: 14)),
                                                                  ]),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Container(),
                                          Container(
                                            margin: EdgeInsets.only(
                                                bottom: i ==
                                                        state.listParticipantOfflineModel
                                                                .length -
                                                            1
                                                    ? 20
                                                    : 0,
                                                top: i == 0 ? 5 : 0,
                                                left: 20,
                                                right: 20),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                    bottomLeft: Radius.circular(
                                                        i == state.listParticipantOfflineModel.length - 1
                                                            ? 6
                                                            : 0),
                                                    bottomRight: Radius.circular(
                                                        i == state.listParticipantOfflineModel.length - 1
                                                            ? 6
                                                            : 0),
                                                    topLeft: Radius.circular(
                                                        i == 0 ? 6 : 0),
                                                    topRight: Radius.circular(
                                                        i == 0 ? 6 : 0)),
                                                color: state.listParticipantOfflineModel[i]
                                                            .attendedAt ==
                                                        null
                                                    ? Colors.white
                                                    : Colors.grey[50],
                                                border: Border.all(
                                                  color: Colors.grey[300],
                                                  width: 1,
                                                )),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(20.0),
                                              child: Column(
                                                children: <Widget>[
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: <Widget>[
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Image.asset(
                                                              '${Environment.iconAssets}people_icon.png',
                                                              width: 13),
                                                          const SizedBox(
                                                            width: 15,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.4,
                                                                child: Text(
                                                                    state
                                                                        .listParticipantOfflineModel[
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
                                                                        fontSize:
                                                                            16)),
                                                              ),
                                                              const SizedBox(
                                                                height: 5,
                                                              ),
                                                              Text(state.listParticipantOfflineModel[i].registrationCode,
                                                                  style: TextStyle(
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
                                                                      fontSize:
                                                                          12)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 12,
                                                                vertical: 7),
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            color: state
                                                                        .listParticipantOfflineModel[
                                                                            i]
                                                                        .attendedAt ==
                                                                    null
                                                                ? ColorBase
                                                                    .yellow700
                                                                : ColorBase
                                                                    .green2),
                                                        child: Text(
                                                          state.listParticipantOfflineModel[i]
                                                                      .attendedAt ==
                                                                  null
                                                              ? Dictionary.absent
                                                              : Dictionary.present,
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  FontsFamily
                                                                      .roboto,
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: <Widget>[
                                                      const SizedBox(
                                                        width: 28,
                                                      ),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              Dictionary
                                                                  .labCode,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.6),
                                                                  fontFamily:
                                                                      FontsFamily
                                                                          .roboto,
                                                                  fontSize: 10),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Text(
                                                              state
                                                                          .listParticipantOfflineModel[
                                                                              i]
                                                                          .labCode ==
                                                                      null
                                                                  ? '-'
                                                                  : state
                                                                      .listParticipantOfflineModel[
                                                                          i]
                                                                      .labCode,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.8),
                                                                  fontFamily:
                                                                      FontsFamily
                                                                          .roboto,
                                                                  fontSize: 12),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            Dictionary
                                                                .checkinDate,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.6),
                                                                fontFamily:
                                                                    FontsFamily
                                                                        .roboto,
                                                                fontSize: 10),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            state
                                                                        .listParticipantOfflineModel[
                                                                            i]
                                                                        .attendedAt ==
                                                                    null
                                                                ? '-'
                                                                : unixTimeStampToDateTime(state
                                                                        .listParticipantOfflineModel[
                                                                            i]
                                                                        .attendedAt) +
                                                                    Dictionary
                                                                        .wib,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.8),
                                                                fontFamily:
                                                                    FontsFamily
                                                                        .roboto,
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _listParticipantBloc
          .add(ListParticipantSearchOffline(keyword: _searchController.text));
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
