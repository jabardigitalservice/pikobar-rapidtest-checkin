import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/offline/list_checkin_offline/Bloc.dart';
import 'package:rapid_test/blocs/offline/send_checkin_data/Bloc.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:rapid_test/utilities/FormatDate.dart';

class CheckinList extends StatefulWidget {
  @override
  _CheckinListState createState() => _CheckinListState();
}

class _CheckinListState extends State<CheckinList> {
  ListCheckinOfflineBloc _listCheckin;
  SendCheckinDataBloc _sendCheckinDataBloc;
  OfflineRepository _offlineRepository = OfflineRepository();
  static const int sortEvent = 0;
  static const int sortRegistration = 1;
  static const int sortlabCodeSample = 2;
  static const int sortlocation = 3;
  static const int sortcreatedAt = 4;
  bool isAscending = true;
  int sortType = sortEvent;
  ListCheckinOfflineLoaded listCheckinOfflineLoaded;
  int lengthDataOffline = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tes Masif Checkin Offline Mode"),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, lengthDataOffline);
            }),
        actions: [
          IconButton(
              icon: (Icon(Icons.send)),
              onPressed: () {
                _buildConfirmDialog();
              })
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<ListCheckinOfflineBloc>(
              create: (BuildContext context) => _listCheckin =
                  ListCheckinOfflineBloc(repository: _offlineRepository)
                    ..add(ListCheckinOfflineLoad())),
          BlocProvider<SendCheckinDataBloc>(
              create: (BuildContext context) => _sendCheckinDataBloc =
                  SendCheckinDataBloc(repository: _offlineRepository)),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<SendCheckinDataBloc, SendCheckinDataState>(
              listener: (context, state) {
                if (state is SendCheckinDataFailure) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: state.error.toString(),
                            buttonText: "OK",
                            onOkPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              _listCheckin.add(ListCheckinOfflineLoad());
                            },
                          ));

                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is SendCheckinDataLoading) {
                  Navigator.of(context).pop();
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tunggu Sebentar...'),
                                  Container(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(),
                                  )
                                ],
                              ),
                            ),
                          ));
                } else if (state is SendCheckinDataSuccess) {
                  Navigator.of(context).pop();
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: state.message.toString(),
                            buttonText: "OK",
                            onOkPressed: () {
                              _listCheckin.add(ListCheckinOfflineLoad());
                              Navigator.of(context).pop();
                            },
                          ));

                  Scaffold.of(context).hideCurrentSnackBar();
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              },
            ),
            BlocListener<ListCheckinOfflineBloc, ListCheckinOfflineState>(
              listener: (context, state) {
                if (state is ListCheckinOfflineFailure) {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: state.error.toString(),
                            buttonText: "OK",
                            onOkPressed: () {
                              Navigator.of(context).pop();
                              _listCheckin.add(
                                  ListCheckinOfflineLoad()); // To close the dialog
                            },
                          ));

                  Scaffold.of(context).hideCurrentSnackBar();
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              },
            ),
          ],
          child: BlocBuilder<ListCheckinOfflineBloc, ListCheckinOfflineState>(
            builder: (
              BuildContext context,
              ListCheckinOfflineState state,
            ) {
              if (state is ListCheckinOfflineLoaded) {
                listCheckinOfflineLoaded = state as ListCheckinOfflineLoaded;
                lengthDataOffline =
                    listCheckinOfflineLoaded.checkinOfflineModel.length;
                return _getBodyWidget();
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _getBodyWidget() {
    return Container(
      child: HorizontalDataTable(
        leftHandSideColumnWidth: 100,
        rightHandSideColumnWidth: 600,
        isFixedHeader: true,
        headerWidgets: _getTitleWidget(),
        leftSideItemBuilder: _generateFirstColumnRow,
        rightSideItemBuilder: _generateRightHandSideColumnRow,
        itemCount: listCheckinOfflineLoaded.checkinOfflineModel.length,
        rowSeparatorWidget: const Divider(
          color: Colors.black54,
          height: 1.0,
          thickness: 0.0,
        ),
        rightHandSideColBackgroundColor: Color(0xFFFFFFFF),
      ),
    );
  }

  List<Widget> _getTitleWidget() {
    return [
      FlatButton(
        padding: EdgeInsets.all(0),
        child: _getTitleItemWidget(
            'Kode Kegiatan' +
                (sortType == sortEvent ? (isAscending ? ' ↓' : ' ↑') : ''),
            150),
        onPressed: () {
          setState(() {
            sortType = sortEvent;
            isAscending = !isAscending;
            if (isAscending) {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => a.eventCode.compareTo(b.eventCode));
            } else {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => b.eventCode.compareTo(a.eventCode));
            }
          });
        },
      ),
      FlatButton(
        padding: EdgeInsets.all(0),
        child: _getTitleItemWidget(
            'Kode Registrasi' +
                (sortType == sortRegistration
                    ? (isAscending ? ' ↓' : ' ↑')
                    : ''),
            150),
        onPressed: () {
          setState(() {
            sortType = sortRegistration;
            isAscending = !isAscending;
            if (isAscending) {
              listCheckinOfflineLoaded.checkinOfflineModel.sort(
                  (b, a) => a.registrationCode.compareTo(b.registrationCode));
            } else {
              listCheckinOfflineLoaded.checkinOfflineModel.sort(
                  (b, a) => b.registrationCode.compareTo(a.registrationCode));
            }
          });
        },
      ),
      FlatButton(
        padding: EdgeInsets.all(0),
        child: _getTitleItemWidget(
            'Kode Lab' +
                (sortType == sortlabCodeSample
                    ? (isAscending ? ' ↓' : ' ↑')
                    : ''),
            150),
        onPressed: () {
          setState(() {
            sortType = sortlabCodeSample;
            isAscending = !isAscending;
            if (isAscending) {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => a.labCodeSample.compareTo(b.labCodeSample));
            } else {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => b.labCodeSample.compareTo(a.labCodeSample));
            }
          });
        },
      ),
      FlatButton(
        padding: EdgeInsets.all(0),
        child: _getTitleItemWidget(
            'Lokasi' +
                (sortType == sortlocation ? (isAscending ? ' ↓' : ' ↑') : ''),
            150),
        onPressed: () {
          setState(() {
            sortType = sortlocation;
            isAscending = !isAscending;
            if (isAscending) {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => a.location.compareTo(b.location));
            } else {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => b.location.compareTo(a.location));
            }
          });
        },
      ),
      FlatButton(
        padding: EdgeInsets.all(0),
        child: _getTitleItemWidget(
            'Created At' +
                (sortType == sortcreatedAt ? (isAscending ? ' ↓' : ' ↑') : ''),
            150),
        onPressed: () {
          setState(() {
            sortType = sortcreatedAt;
            isAscending = !isAscending;
            if (isAscending) {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => a.createdAt.compareTo(b.createdAt));
            } else {
              listCheckinOfflineLoaded.checkinOfflineModel
                  .sort((b, a) => b.createdAt.compareTo(a.createdAt));
            }
          });
        },
      ),
    ];
  }

  Widget _getTitleItemWidget(String label, double width) {
    return Container(
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      width: width,
      height: 56,
      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.centerLeft,
    );
  }

  Widget _generateFirstColumnRow(BuildContext context, int i) {
    return Container(
      child: Text((i + 1).toString() +
          '. ' +
          listCheckinOfflineLoaded.checkinOfflineModel[i].eventCode),
      width: 150,
      height: 52,
      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.centerLeft,
    );
  }

  Widget _generateRightHandSideColumnRow(BuildContext context, int i) {
    return Row(
      children: <Widget>[
        Container(
          child: Text(
              listCheckinOfflineLoaded.checkinOfflineModel[i].registrationCode),
          width: 150,
          height: 52,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.centerLeft,
        ),
        Container(
          child: Text(
              listCheckinOfflineLoaded.checkinOfflineModel[i].labCodeSample),
          width: 100,
          height: 52,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.centerLeft,
        ),
        Container(
          child: Text(listCheckinOfflineLoaded.checkinOfflineModel[i].location),
          width: 150,
          height: 52,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.centerLeft,
        ),
        Container(
          child: Text(unixTimeStampToDateTime(
                  listCheckinOfflineLoaded.checkinOfflineModel[i].createdAt) ??
              ''),
          width: 200,
          height: 52,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.centerLeft,
        ),
      ],
    );
  }

  _buildConfirmDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.20,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                          'Data yang akan dikirim sebanyak ${listCheckinOfflineLoaded.checkinOfflineModel.length} \nPastikan koneksi stabil sebelum mengirim data'),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.height * 0.04,
                            child: RaisedButton(
                              splashColor: Colors.lightGreenAccent,
                              padding: EdgeInsets.all(0.0),
                              color: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                    fontFamily: FontsFamily.productSans,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.height * 0.04,
                            child: RaisedButton(
                              splashColor: Colors.lightGreenAccent,
                              padding: EdgeInsets.all(0.0),
                              color: ColorBase.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                'Kirim',
                                style: TextStyle(
                                    fontFamily: FontsFamily.productSans,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.white),
                              ),
                              onPressed: () {
                                _sendCheckinDataBloc.add(SendCheckinData());
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ));
  }

  @override
  void dispose() {
    _listCheckin.close();
    _sendCheckinDataBloc.close();
    super.dispose();
  }
}
