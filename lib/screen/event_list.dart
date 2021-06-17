import 'dart:async';

import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/event_list/Bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/components/EmptyData.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/EventListModel.dart';
import 'package:rapid_test/repositories/EventListRepository.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/event_detail_screen.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';

import 'login_screen.dart';

class EventListPage extends StatefulWidget {
  EventListPage({Key key}) : super(key: key);
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage>
    with TickerProviderStateMixin {
  final EventListRepository _eventListRepository = EventListRepository();
  EventListBloc _eventListBloc;
  TextEditingController _searchController = TextEditingController();
  String searchQuery;
  ScrollController _scrollController = ScrollController();
  int maxDataLength;
  int _page = 1;
  Timer _debounce;
  bool _hasChange = false;
  bool _isSearch = false;
  bool isEventExpired = false;
  AnimationController _animationController;
  var containerWidth = 40.0;
  final _nodeOne = FocusNode();
  AuthenticationBloc _authenticationBloc;
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  KodeKegiatanBloc _kodeKegiatanBloc;
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  final OfflineRepository _offlineRepository = OfflineRepository();

  @override
  void initState() {
    _initialize();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scrollController.addListener(() {
      _scrollListener();
    });
    AnalyticsHelper.setLogEvent(Analytics.listEventScreen);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar.bottomSearchAppBar(
          searchController: _searchController,
          title: Dictionary.eventList,
          hintText: Dictionary.searchListEvent,
          onSubmitted: updateSearchQuery,
          context: context),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<EventListBloc>(
              create: (context) => _eventListBloc =
                  EventListBloc(repository: _eventListRepository)
                    ..add(EventListLoad(
                        page: _page, isFirstLoad: true, keyword: ''))),
          BlocProvider<AuthenticationBloc>(
              create: (context) => _authenticationBloc =
                  AuthenticationBloc(_authenticationRepository)),
          BlocProvider<KodeKegiatanBloc>(
            create: (context) => _kodeKegiatanBloc = KodeKegiatanBloc(
                repository: _kegiatanDetailRepository,
                offlineRepository: _offlineRepository)
              ..add(AppStart()),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<EventListBloc, EventListState>(
              listener: (BuildContext context, EventListState state) {
                if (state is EventListFailure) {
                  if (state.error
                      .toString()
                      .contains(Dictionary.tokenExpired)) {
                    _authenticationBloc.add(UserLoggedOut());
                  } else {
                    final List<String> split =
                        state.error.split(Dictionary.exeption);
                    showDialog(
                        context: context,
                        builder: (context) => DialogTextOnly(
                              description: split.last.toString(),
                              buttonText: Dictionary.ok,
                              onOkPressed: () {
                                Navigator.of(context).pop();
                                _eventListBloc.add(EventListLoad(
                                    page: 1,
                                    keyword: '')); // To close the dialog
                              },
                            ));
                  }
                  Scaffold.of(context).hideCurrentSnackBar();
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              },
            ),
            BlocListener<AuthenticationBloc, AuthenticationState>(
              listener: (BuildContext context, AuthenticationState state) {
                if (state is AuthenticationNotAuthenticated) {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                  AnalyticsHelper.setLogEvent(Analytics.userTimeOut);
                }
              },
            ),
            BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
                listener: (BuildContext context, KodeKegiatanState state) {
              if (state is KodeKegiatanFailure) {
                if (state.error.toString().contains(Dictionary.tokenExpired)) {
                  _authenticationBloc.add(UserLoggedOut());
                } else {
                  final List<String> split =
                      state.error.split(Dictionary.exeption);
                  showDialog(
                      context: context,
                      builder: (context) => DialogTextOnly(
                          description: split.last.toString(),
                          buttonText: Dictionary.ok,
                          onOkPressed: () {
                            Navigator.of(context).pop(); // To close the dialog
                          }));
                }
                Scaffold.of(context).hideCurrentSnackBar();
              } else if (state is KodeKegiatanLoading) {
                Scaffold.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Theme.of(context).primaryColor,
                    content: Row(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: Text(Dictionary.pleaseWait),
                        )
                      ],
                    ),
                  ),
                );
              } else if (state is KodeKegiatanSuccessMovePage) {
                Scaffold.of(context).hideCurrentSnackBar();

                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => EventDetailPage()));
              } else {
                Scaffold.of(context).hideCurrentSnackBar();
              }
            }),
          ],
          child: BlocBuilder<EventListBloc, EventListState>(
            builder: (
              BuildContext context,
              EventListState state,
            ) {
              if (state is EventListLoaded ||
                  state is KodeKegiatanUnauthenticated) {
                EventListLoaded eventListLoaded = state as EventListLoaded;
                _updatePage(eventListLoaded.eventListModel);

                maxDataLength = eventListLoaded.maxData;
                return buildContent(eventListLoaded.eventListModel);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildContent(List<ListEvent> listEvent) {
    return SafeArea(
      child: ConnectivityWidgetWrapper(
          stacked: false,
          offlineWidget: EmptyData(
            message: Dictionary.errorConnection,
            desc: Dictionary.errorConnectionDesc,
            image: "${Environment.imageAssets}not_found.png",
          ),
          child: listEvent.length == 0
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
                          _eventListBloc.add(EventListLoad(
                              page: 1, keyword: _searchController.text));
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: listEvent.length + 1,
                          itemBuilder: (BuildContext context, int i) {
                            if (i == listEvent.length) {
                              if (listEvent.length > 10 &&
                                  maxDataLength != listEvent.length) {
                                return buildLoading();
                              } else {
                                return Container();
                              }
                            }
                            return buildItem(listEvent, i);
                          },
                        ),
                      ),
                    ),
                  ],
                )),
    );
  }

  Widget buildLoading() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        children: <Widget>[
          CupertinoActivityIndicator(),
          const SizedBox(
            height: 5,
          ),
          Text(
            Dictionary.dataParticipantLoading,
            style: TextStyle(fontFamily: FontsFamily.roboto),
          ),
        ],
      ),
    );
  }

  Widget buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 0, top: 10, left: 20, right: 20),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ColorBase.lightGrey, width: 1)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Dictionary.welome,
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: FontsFamily.roboto,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    Dictionary.welcomeTextEventList,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.6),
                        fontFamily: FontsFamily.roboto,
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Image.asset(
              '${Environment.iconAssets}tes_masif.png',
              height: MediaQuery.of(context).size.height * 0.10,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(List<ListEvent> listEvent, int i) {
    return Column(
      children: [
        i == 0 ? buildWelcomeHeader() : Container(),
        GestureDetector(
          onTap: () async {
            if (unixTimeStampToDateWithoutHour(DateTime.now().toString()) ==
                    unixTimeStampToDateWithoutHour(listEvent[i].endAt) ||
                DateTime.now()
                    .difference(DateTime.parse(listEvent[i].endAt).toLocal())
                    .isNegative) {
              if (await ConnectivityWrapper.instance.isConnected) {
                _kodeKegiatanBloc.add(KodeKegiatanMovePage(
                    kodeKegiatan: listEvent[i].eventCode, isFromLogin: true));
              } else {
                showDialog(
                    context: context,
                    builder: (context) => DialogTextOnly(
                        description: Dictionary.errorConnection,
                        buttonText: Dictionary.ok,
                        onOkPressed: () {
                          Navigator.of(context).pop(); // To close the dialog
                        }));
              }
            } else {
              showDialog(
                  context: context,
                  builder: (context) => DialogTextOnly(
                      description: Dictionary.eventExpired,
                      buttonText: Dictionary.ok,
                      onOkPressed: () {
                        Navigator.of(context).pop(); // To close the dialog
                      }));
            }
          },
          child: Container(
            margin: EdgeInsets.only(
                bottom: 10, top: i == 0 ? 10 : 0, left: 20, right: 20),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ColorBase.lightGrey, width: 1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, top: 15, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        listEvent[i].hostName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: FontsFamily.roboto,
                            fontSize: 16),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Dictionary.time,
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                      fontFamily: FontsFamily.roboto,
                                      fontSize: 10),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  checkingSameDate(
                                          DateTime.parse(listEvent[i].startAt)
                                              .toLocal(),
                                          DateTime.parse(listEvent[i].endAt)
                                              .toLocal())
                                      ? unixTimeStampToDateWithoutHour(
                                          listEvent[i].startAt)
                                      : "${unixTimeStampToDateWithoutHour(listEvent[i].startAt)} - ${unixTimeStampToDateWithoutHour(listEvent[i].endAt)}",
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontFamily: FontsFamily.roboto,
                                      fontSize: 12),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  unixTimeStampToHour(listEvent[i].startAt) +
                                      ' - ' +
                                      unixTimeStampToHour(listEvent[i].endAt) +
                                      Dictionary.wib,
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontFamily: FontsFamily.roboto,
                                      fontSize: 12),
                                )
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Dictionary.totalParticipant,
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.6),
                                    fontFamily: FontsFamily.roboto,
                                    fontSize: 10),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                listEvent[i].invitationsCount.toString() +
                                    Dictionary.people,
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.8),
                                    fontFamily: FontsFamily.roboto,
                                    fontSize: 12),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 1,
                  child: Container(
                    color: ColorBase.lightGrey,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listEvent[i].eventName,
                          style: TextStyle(
                              color: ColorBase.strongBlue,
                              fontWeight: FontWeight.w600,
                              fontFamily: FontsFamily.roboto,
                              fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: unixTimeStampToDateWithoutHour(
                                        DateTime.now().toString()) ==
                                    unixTimeStampToDateWithoutHour(
                                        listEvent[i].endAt)
                                ? ColorBase.yellow700
                                : (DateTime.now()
                                        .difference(
                                            DateTime.parse(listEvent[i].endAt)
                                                .toLocal())
                                        .isNegative)
                                    ? ColorBase.yellow700
                                    : ColorBase.green2),
                        child: Text(
                          unixTimeStampToDateWithoutHour(
                                      DateTime.now().toString()) ==
                                  unixTimeStampToDateWithoutHour(
                                      listEvent[i].endAt)
                              ? Dictionary.eventOnProgress
                              : (DateTime.now()
                                      .difference(
                                          DateTime.parse(listEvent[i].endAt)
                                              .toLocal())
                                      .isNegative)
                                  ? Dictionary.eventOnProgress
                                  : Dictionary.eventDone,
                          style: TextStyle(
                              fontFamily: FontsFamily.roboto,
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool checkingSameDate(DateTime startAt, endAt) {
    return startAt.year == endAt.year &&
        startAt.month == endAt.month &&
        startAt.day == endAt.day;
  }

  void _initialize() async {
    _page = await Preferences.getDataInt(kParticipantPage) != null
        ? await Preferences.getDataInt(kParticipantPage)
        : 1;
    maxDataLength = await Preferences.getDataInt(kTotalCount) != null
        ? await Preferences.getDataInt(kTotalCount)
        : 0;
  }

  void _updatePage(List<ListEvent> records) async {
    double tempPage = (records.length / 15);
    var listPage = tempPage.toString().split('.');
    if (int.parse(listPage[1]) < 50 && int.parse(listPage[1]) != 0) {
      _page = (tempPage + 0.95).round() + 1;
    } else {
      _page = (records.length / 15).round() + 1;
    }
    print(_page);
    await Preferences.setDataInt(kParticipantPage, _page);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _eventListBloc
          .add(EventListLoadMore(page: _page, keyword: _searchController.text));
      // }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _hasChange = true;
      _eventListBloc
          .add(EventListLoad(page: 1, keyword: _searchController.text));
      AnalyticsHelper.setLogEvent(Analytics.tappedSearchEvent);
    });
  }

  void _searchPressed() {
    return setState(() {
      _isSearch = !_isSearch;
      _animationController.forward(from: 0);
      _showSearch();
    });
  }

  void _showSearch() {
    if (!_isSearch) {
      if (_hasChange) {
        _hasChange = false;
        _refresh();
      }
      containerWidth = 50;
      FocusScope.of(context).unfocus();
    } else {
      containerWidth = MediaQuery.of(context).size.width;
      FocusScope.of(context).requestFocus(_nodeOne);
    }
    _searchController.clear();
  }

  Future<void> _refresh() async {
    _eventListBloc.add(EventListLoad(page: 1, keyword: ''));
    _page = 1;
    await Preferences.setDataInt(kParticipantPage, 1);
  }

  void updateSearchQuery(String newQuery) {
    _onSearchChanged();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kodeKegiatanBloc.close();
    _authenticationBloc.close();
    _eventListBloc.close();
    super.dispose();
  }
}
