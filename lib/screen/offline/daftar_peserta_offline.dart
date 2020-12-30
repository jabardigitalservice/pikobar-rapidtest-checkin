import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/offline/list_checkin_offline/Bloc.dart';
import 'package:rapid_test/blocs/offline/list_participants_offline/Bloc.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/screen/offline/checkin_list.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';

class DaftarPesertaOfflinePage extends StatefulWidget {
  final KodeKegiatanModel kodeKegiatanModel;
  DaftarPesertaOfflinePage({this.kodeKegiatanModel});
  @override
  _DaftarPesertaOfflinePageState createState() =>
      _DaftarPesertaOfflinePageState();
}

class _DaftarPesertaOfflinePageState extends State<DaftarPesertaOfflinePage>
    with TickerProviderStateMixin {
  final OfflineRepository _offlineRepository = OfflineRepository();
  ListParticipantOfflineBloc _listParticipantBloc;
  TextEditingController _searchController = TextEditingController();
  String searchQuery;
  ScrollController _scrollController = ScrollController();
  int maxDataLength;
  int _page = 1;
  Timer _debounce;
  bool _hasChange = false;
  bool _isSearch = false;
  AnimationController _animationController;
  var containerWidth = 40.0;
  final _nodeOne = FocusNode();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  ListCheckinOfflineBloc _listCheckin;
  ListCheckinOfflineLoaded listCheckinOfflineLoaded;
  int lengthDataOffline = 0;

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
      appBar: CustomAppBar.bottomSearchAppBar(
          searchController: _searchController,
          title: 'Daftar Peserta',
          hintText: 'Cari Daftar Peserta',
          onSubmitted: updateSearchQuery,
          context: context),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ListParticipantOfflineBloc>(
            create: (BuildContext context) => _listParticipantBloc =
                ListParticipantOfflineBloc(repository: _offlineRepository)
                  ..add(ListParticipantOfflineLoad(
                      eventCode: widget.kodeKegiatanModel.data.eventCode)),
          ),
          BlocProvider<AuthenticationBloc>(
              create: (BuildContext context) => _authenticationBloc =
                  AuthenticationBloc(_authenticationRepository)),
          BlocProvider<ListCheckinOfflineBloc>(
              create: (BuildContext context) => _listCheckin =
                  ListCheckinOfflineBloc(repository: _offlineRepository)
                    ..add(ListCheckinOfflineLoad())),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<ListCheckinOfflineBloc, ListCheckinOfflineState>(
              listener: (context, state) {
                if (state is ListCheckinOfflineLoaded) {
                  listCheckinOfflineLoaded = state as ListCheckinOfflineLoaded;
                  lengthDataOffline =
                      listCheckinOfflineLoaded.checkinOfflineModel.length;
                  if (lengthDataOffline != 0) {
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Theme.of(context).primaryColor,
                        content: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Ada ${lengthDataOffline.toString()} Data Offline ',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Container(
                              height: 20,
                              width: 80,
                              child: RaisedButton(
                                color: ColorBase.green,
                                onPressed: () async {
                                  lengthDataOffline = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => CheckinList()));
                                  if (lengthDataOffline == 0) {
                                    Scaffold.of(context).hideCurrentSnackBar();
                                  }
                                },
                                child: Text(
                                  'Lihat',
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
            BlocListener<ListParticipantOfflineBloc,
                ListParticipantOfflineState>(listener: (context, state) {
              if (state is ListParticipantOfflineFailure) {
                if (state.error.toString().contains('Token Expired')) {
                  _authenticationBloc.add(UserLoggedOut());
                } else {
                  var split = state.error.split('Exception:');
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: split.last.toString(),
                            buttonText: "OK",
                            onOkPressed: () {
                              Navigator.of(context).pop();
                              _listParticipantBloc.add(
                                  ListParticipantOfflineLoad(
                                      eventCode: widget.kodeKegiatanModel.data
                                          .eventCode)); // To close the dialog
                            },
                          ));
                }
                Scaffold.of(context).hideCurrentSnackBar();
              }
              // else if (state is ListParticipantLoading) {
              //   Scaffold.of(context).showSnackBar(R
              //     SnackBar(
              //       backgroundColor: Theme.of(context).primaryColor,
              //       content: Row(
              //         children: <Widget>[
              //           CircularProgressIndicator(),
              //           Container(
              //             margin: EdgeInsets.only(left: 15.0),
              //             child: Text('Tunggu Sebentar'),
              //           )
              //         ],
              //       ),
              //     ),
              //   );
              // }
              // else {
              //   Scaffold.of(context).hideCurrentSnackBar();
              // }
            }),
            BlocListener<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) {
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
                // List<DataParticipant> invitationsList;

                // /// Checking search field
                // if (searchQuery != null) {
                //   /// Filtering data by search
                //   invitationsList = listParticipantLoaded
                //       .listParticipantModel
                //       .where((test) =>
                //           test.name
                //               .toLowerCase()
                //               .contains(searchQuery.toLowerCase()) ||
                //           test.registrationCode
                //               .toLowerCase()
                //               .contains(searchQuery.toLowerCase()))
                //       .toList();
                // } else {
                //   invitationsList =
                //       listParticipantLoaded.listParticipantModel;
                // }

                return SafeArea(
                    child: state.listParticipantOfflineModel.length == 0
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
                                    _listParticipantBloc.add(
                                        ListParticipantOfflineLoad(
                                            eventCode: widget.kodeKegiatanModel
                                                .data.eventCode));
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: state
                                        .listParticipantOfflineModel.length,
                                    itemBuilder: (context, i) {
                                      return Container(
                                        margin: EdgeInsets.only(
                                            bottom: 10,
                                            top: i == 0 ? 20 : 0,
                                            left: 20,
                                            right: 20),
                                        width:
                                            MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            color: state
                                                        .listParticipantOfflineModel[
                                                            i]
                                                        .attendedAt ==
                                                    null
                                                ? Colors.white
                                                : Colors.green[100],
                                            border: Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                width: 1)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            children: <Widget>[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(state
                                                      .listParticipantOfflineModel[
                                                          i]
                                                      .name),
                                                  Text(
                                                      state.listParticipantOfflineModel[i]
                                                                  .attendedAt ==
                                                              null
                                                          ? 'Tidak Hadir'
                                                          : 'Hadir'),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              SizedBox(
                                                height: 1,
                                                child: Container(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    'Nomor Registrasi: ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                      state
                                                                  .listParticipantOfflineModel[
                                                                      i]
                                                                  .registrationCode ==
                                                              null
                                                          ? ''
                                                          : state
                                                              .listParticipantOfflineModel[
                                                                  i]
                                                              .registrationCode,
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    'Kode Sampel: ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                      state
                                                                  .listParticipantOfflineModel[
                                                                      i]
                                                                  .labCode ==
                                                              null
                                                          ? ''
                                                          : state
                                                              .listParticipantOfflineModel[
                                                                  i]
                                                              .labCode,
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    'Tanggal Checkin: ',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                      state
                                                                  .listParticipantOfflineModel[
                                                                      i]
                                                                  .attendedAt ==
                                                              null
                                                          ? ''
                                                          : unixTimeStampToDateTime(
                                                              state
                                                                  .listParticipantOfflineModel[
                                                                      i]
                                                                  .attendedAt),
                                                      style: TextStyle(
                                                          fontSize: 12)),
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
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
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
    double tempPage = (records.length / 20);
    var listPage = tempPage.toString().split('.');
    if (int.parse(listPage[1]) < 50 && int.parse(listPage[1]) != 0) {
      _page = (tempPage + 0.95).round() + 1;
    } else {
      _page = (records.length / 20).round() + 1;
    }
    print(_page);
    await Preferences.setDataInt(kParticipantPage, _page);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _hasChange = true;
      print('masuk');
      _listParticipantBloc
          .add(ListParticipantSearchOffline(keyword: _searchController.text));
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
    _listParticipantBloc.add(ListParticipantOfflineLoad(
        eventCode: widget.kodeKegiatanModel.data.eventCode));
    _page = 1;
    await Preferences.setDataInt(kParticipantPage, 1);
  }

  void updateSearchQuery(String newQuery) {
    _onSearchChanged();
  }
}
