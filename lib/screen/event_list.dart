import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/event_list/Bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/model/EventListModel.dart';
import 'package:rapid_test/repositories/EventListRepository.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/kegiatan_detail.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';

import 'login_screen.dart';

class EventListPage extends StatefulWidget {
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
    //   _searchController.addListener((() {
    //   _onSearchChanged();
    // }));

    _scrollController.addListener(() {
      _scrollListener();
    });
    super.initState();
  }
  // void onScroll() {
  //   double maxScroll = _scrollController.position.maxScrollExtent;
  //   double currentScroll = _scrollController.position.pixels;
  //   if (currentScroll == maxScroll) {
  //     _listParticipantBloc.add(ListParticipantLoadMore(
  //         eventCode: widget.kodeKegiatanModel.data.eventCode,
  //         page: 2,
  //         keyword: ''));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // _scrollController.addListener(onScroll);
    return Scaffold(
      appBar: AppBar(
        title: Text("Daftar Event"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                _authenticationBloc.add(UserLoggedOut());
              })
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<EventListBloc>(
              create: (BuildContext context) => _eventListBloc =
                  EventListBloc(repository: _eventListRepository)
                    ..add(EventListLoad(page: _page, isFirstLoad: true))),
          BlocProvider<AuthenticationBloc>(
              create: (BuildContext context) => _authenticationBloc =
                  AuthenticationBloc(_authenticationRepository)),
          BlocProvider<KodeKegiatanBloc>(
            create: (BuildContext context) =>
                _kodeKegiatanBloc = KodeKegiatanBloc(
                    repository: _kegiatanDetailRepository,
                    offlineRepository: _offlineRepository)
                  ..add(AppStart()),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<EventListBloc, EventListState>(
              listener: (context, state) {
                if (state is EventListFailure) {
                  if (state.error.toString().contains('Token Expired')) {
                    _authenticationBloc.add(UserLoggedOut());
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => DialogTextOnly(
                              description: state.error.toString(),
                              buttonText: "OK",
                              onOkPressed: () {
                                Navigator.of(context).pop();
                                _eventListBloc.add(EventListLoad(
                                  page: 1,
                                )); // To close the dialog
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
              listener: (context, state) {
                if (state is AuthenticationNotAuthenticated) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }
              },
            ),
            BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
                listener: (context, state) {
              if (state is KodeKegiatanFailure) {
                if (state.error.toString().contains('Token Expired')) {
                  _authenticationBloc.add(UserLoggedOut());
                } else {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                          description: state.error.toString(),
                          buttonText: "OK",
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
                          margin: EdgeInsets.only(left: 15.0),
                          child: Text('Tunggu Sebentar'),
                        )
                      ],
                    ),
                  ),
                );
              } else if (state is KodeKegiatanSuccessMovePage) {
                Scaffold.of(context).hideCurrentSnackBar();
                
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => KegiatanPage(
                              
                            )));
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
        child: listEvent.length == 0
            ? Center(
                child: Text('Tidak ada data daftar peserta'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: LiquidPullToRefresh(
                      showChildOpacityTransition: false,
                      height: 50,
                      color: ColorBase.green,
                      onRefresh: () {
                        _eventListBloc.add(EventListLoad(
                          page: 1,
                        ));
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: listEvent.length + 1,
                        itemBuilder: (context, i) {
                          if (i == listEvent.length) {
                            if (listEvent.length > 10 &&
                                maxDataLength != listEvent.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    top: 20.0, bottom: 20.0),
                                child: Column(
                                  children: <Widget>[
                                    CupertinoActivityIndicator(),
                                    SizedBox(
                                      height: 5.0,
                                    ),
                                    Text('Sedang mengambil data ...'),
                                  ],
                                ),
                              );
                            } else {
                              return Container();
                            }
                          }
                          return Container(
                            margin: EdgeInsets.only(
                                bottom: 10,
                                top: i == 0 ? 20 : 0,
                                left: 20,
                                right: 20),
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: unixTimeStampToDateWithoutHour(
                                            DateTime.now().toString()) ==
                                        unixTimeStampToDateWithoutHour(
                                            listEvent[i].endAt)
                                    ? Colors.white
                                    : (DateTime.now()
                                            .difference(
                                                DateTime.parse(listEvent[i].endAt)
                                                    .toLocal())
                                            .isNegative)
                                        ? Colors.white
                                        : Colors.grey[300],
                                border: Border.all(
                                    color: unixTimeStampToDateWithoutHour(
                                                DateTime.now().toString()) ==
                                            unixTimeStampToDateWithoutHour(
                                                listEvent[i].endAt)
                                        ? Theme.of(context).primaryColor
                                        : (DateTime.now()
                                                .difference(DateTime.parse(
                                                        listEvent[i].endAt)
                                                    .toLocal())
                                                .isNegative)
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                    width: 1)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    listEvent[i].hostName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          child: Text(listEvent[i].eventName)),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.2,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.04,
                                        child: RaisedButton(
                                          onPressed: () {
                                            if (unixTimeStampToDateWithoutHour(
                                                    DateTime.now()
                                                        .toString()) ==
                                                unixTimeStampToDateWithoutHour(
                                                    listEvent[i].endAt)) {
                                              _kodeKegiatanBloc.add(
                                                  KodeKegiatanMovePage(
                                                      kodeKegiatan: listEvent[i]
                                                          .eventCode,
                                                      isFromLogin: true));
                                            } else {
                                              if (DateTime.now()
                                                  .difference(DateTime.parse(
                                                          listEvent[i].endAt)
                                                      .toLocal())
                                                  .isNegative) {
                                                _kodeKegiatanBloc.add(
                                                    KodeKegiatanMovePage(
                                                        kodeKegiatan:
                                                            listEvent[i]
                                                                .eventCode,
                                                        isFromLogin: true));
                                              } else {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext
                                                            context) =>
                                                        DialogTextOnly(
                                                            description:
                                                                'Event Sudah Berakhir',
                                                            buttonText: "OK",
                                                            onOkPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(); // To close the dialog
                                                            }));
                                              }
                                            }
                                          },
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          color: unixTimeStampToDateWithoutHour(
                                                      DateTime.now()
                                                          .toString()) ==
                                                  unixTimeStampToDateWithoutHour(
                                                      listEvent[i].endAt)
                                              ? Theme.of(context).primaryColor
                                              : (DateTime.now()
                                                      .difference(
                                                          DateTime.parse(
                                                                  listEvent[i]
                                                                      .endAt)
                                                              .toLocal())
                                                      .isNegative)
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.grey,
                                          child: Text(
                                            'Pilih',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  SizedBox(
                                    height: 1,
                                    child: Container(
                                      color: unixTimeStampToDateWithoutHour(
                                                  DateTime.now().toString()) ==
                                              unixTimeStampToDateWithoutHour(
                                                  listEvent[i].endAt)
                                          ? Theme.of(context).primaryColor
                                          : (DateTime.now()
                                                  .difference(DateTime.parse(
                                                          listEvent[i].endAt)
                                                      .toLocal())
                                                  .isNegative)
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Tanggal: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Expanded(
                                        child: Text(
                                            checkingSameDate(
                                                    DateTime.parse(listEvent[i]
                                                            .startAt)
                                                        .toLocal(),
                                                    DateTime.parse(
                                                            listEvent[i].endAt)
                                                        .toLocal())
                                                ? unixTimeStampToDateWithoutHour(
                                                    listEvent[i].startAt)
                                                : "${unixTimeStampToDateWithoutHour(listEvent[i].startAt)} - ${unixTimeStampToDateWithoutHour(listEvent[i].endAt)}",
                                            textAlign: TextAlign.right,
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        'Waktu: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                          unixTimeStampToHour(
                                                  listEvent[i].startAt) +
                                              ' - ' +
                                              unixTimeStampToHour(
                                                  listEvent[i].endAt) +
                                              ' WIB',
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        'Jumlah Peserta: ',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                          listEvent[i]
                                              .invitationsCount
                                              .toString(),
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ));
  }

  bool checkingSameDate(DateTime startAt, endAt) {
    return startAt.year == endAt.year &&
        startAt.month == endAt.month &&
        startAt.day == endAt.day;
  }

  void _initialize() async {
    _page = await Preferences.getParticipantPage() != null
        ? await Preferences.getParticipantPage()
        : 1;
    maxDataLength = await Preferences.getTotalCount() != null
        ? await Preferences.getTotalCount()
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
    await Preferences.setParticipantPage(_page);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _eventListBloc.add(EventListLoadMore(
        page: _page,
      ));
      // }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _hasChange = true;
      _eventListBloc.add(EventListLoad(
        page: 1,
      ));
    });
  }

  void _searchPressed() {
    return setState(() {
      _isSearch = !_isSearch;
      _animationController.forward(from: 0.0);
      _showSearch();
    });
  }

  void _showSearch() {
    if (!_isSearch) {
      if (_hasChange) {
        _hasChange = false;
        _refresh();
      }
      containerWidth = 50.0;
      FocusScope.of(context).unfocus();
    } else {
      containerWidth = MediaQuery.of(context).size.width;
      FocusScope.of(context).requestFocus(_nodeOne);
    }
    _searchController.clear();
  }

  Future<void> _refresh() async {
    _eventListBloc.add(EventListLoad(
      page: 1,
    ));
    _page = 1;
    await Preferences.setParticipantPage(1);
  }

  void updateSearchQuery(String newQuery) {
    _onSearchChanged();
  }
}
