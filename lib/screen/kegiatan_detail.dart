import 'package:app_settings/app_settings.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/components/DialogRequestPermission.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/screen/daftar_peserta.dart';
import 'package:rapid_test/screen/input_nomor.dart';
import 'package:rapid_test/utilities/FormatDate.dart';

class KegiatanPage extends StatefulWidget {
  KodeKegiatanModel kodeKegiatanModel;
  KegiatanPage({this.kodeKegiatanModel});
  @override
  _KegiatanPageState createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  CheckinBloc _checkinBloc;
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("RDT Checkin")),
      body: BlocProvider<CheckinBloc>(
        create: (BuildContext context) =>
            _checkinBloc = CheckinBloc(repository: _kegiatanDetailRepository),
        child: BlocListener<CheckinBloc, CheckinState>(
            listener: (context, state) {
              if (state is CheckinFailure) {
                showDialog(
                    context: context,
                    builder: (BuildContext context) => DialogTextOnly(
                          description: state.error.toString(),
                          buttonText: "OK",
                          onOkPressed: () {
                            Navigator.of(context).pop(); // To close the dialog
                          },
                        ));
                Scaffold.of(context).hideCurrentSnackBar();
              } else if (state is CheckinLoading) {
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
                    duration: Duration(seconds: 5),
                  ),
                );
              } else if (state is CheckinLoaded) {
                CheckinLoaded checkinLoaded = state as CheckinLoaded;
                showDialog(
                    context: context,
                    builder: (BuildContext context) => DialogTextOnly(
                          description: checkinLoaded.checkinModel.data.name +
                              ' berhasil checkin',
                          buttonText: "OK",
                          onOkPressed: () {
                            Navigator.of(context).pop(); // To close the dialog
                          },
                        ));
                Scaffold.of(context).hideCurrentSnackBar();
              } else {
                Scaffold.of(context).hideCurrentSnackBar();
              }
            },
            child: SafeArea(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: <Widget>[
                      Text('Nama Kegiatan Test : '),
                      Text(widget.kodeKegiatanModel.data.eventName),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: <Widget>[
                      Text('Waktu : '),
                      Text(unixTimeStampToDateTime(
                              widget.kodeKegiatanModel.data.startAt) +
                          ' - ' +
                          unixTimeStampToHour(
                              widget.kodeKegiatanModel.data.endAt) +
                          ' WIB'),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Tempat : '),
                      Container(
                          width: 300,
                          child: Text(
                              widget.kodeKegiatanModel.data.eventLocation)),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: MaterialButton(
                        color: Theme.of(context).primaryColor,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DaftarPesertaPage(
                                    kodeKegiatanModel:
                                    widget.kodeKegiatanModel,
                                  )));
                        },
                        child: Text('Lihat Daftar Peserta', style: TextStyle(color: Colors.white))
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: MaterialButton(
                        color: Colors.red,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Logout', style: TextStyle(color: Colors.white)))
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  BlocBuilder<CheckinBloc, CheckinState>(
                    builder: (
                      BuildContext context,
                      CheckinState state,
                    ) {
                      if (state is InitialCheckinState ||
                          state is CheckinLoading ||
                          state is CheckinFailure ||
                          state is CheckinLoaded) {
                        return Column(
                          children: <Widget>[
                            InkWell(
                              onTap: () async {
                                var permissionService = Permission.camera;
                                if (await permissionService.status.isGranted) {
                                  barcodeScan();
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          DialogRequestPermission(
                                            image: Image.asset(
                                              '${Environment.iconAssets}map_pin.png',
                                              fit: BoxFit.contain,
                                              color: Colors.white,
                                            ),
                                            description:
                                                'Untuk scan QR Code izinkan mengakses kamera',
                                            onOkPressed: () async {
                                              Navigator.of(context).pop();
                                              if (await permissionService
                                                  .status.isDenied) {
                                                await AppSettings
                                                    .openLocationSettings();
                                              } else {
                                                permissionService
                                                    .request()
                                                    .then((status) {
                                                  _onStatusRequested(
                                                      context, status);
                                                });
                                              }
                                            },
                                            onCancelPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ));
                                }
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.blue
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text('Scan QR Code', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Center(child: Text('Atau')),
                            SizedBox(
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => InputNomor(
                                              kodeKegiatanModel:
                                                  widget.kodeKegiatanModel,
                                            )));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                    color: Colors.green
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text('Input Nomor Pendaftaran', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            )
                          ],
                        );
                      } else {
                        return Container();
                      }
                    },
                  )
                ],
              ),
            ))),
      ),
    );
  }

  barcodeScan() async {
    var barcode = await BarcodeScanner.scan();
    if (barcode.rawContent != '') {
      print('print');
      print(barcode.rawContent);
      print(barcode.format);
      print(barcode.formatNote);
      print(barcode.type);
      _checkinBloc.add(CheckinLoad(
          nomorPendaftaran: barcode.rawContent,
          eventCode: widget.kodeKegiatanModel.data.eventCode));
    }
  }

  void _onStatusRequested(
      BuildContext context, PermissionStatus statuses) async {
    if (statuses.isGranted) {
      barcodeScan();
    } else {}
  }

  @override
  void dispose() {
    _checkinBloc.close();

    super.dispose();
  }
}
