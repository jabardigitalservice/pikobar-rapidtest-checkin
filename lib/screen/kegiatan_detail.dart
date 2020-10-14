import 'package:app_settings/app_settings.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/DialogRequestPermission.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/daftar_peserta.dart';
import 'package:rapid_test/screen/home.dart';
import 'package:rapid_test/screen/input_nomor.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/Validations.dart';

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
  final _codeSampleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;

  KodeKegiatanBloc _kodeKegiatanBloc;
  var activityCode = '';
  @override
  void initState() {
    getAcitivityCode();
    super.initState();
  }

  getAcitivityCode() async {
    activityCode = await _kegiatanDetailRepository.getActivityCode();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        _kodeKegiatanBloc.add(Logout());
      },
      child: Scaffold(
          appBar: AppBar(title: Text("Tes Masif Checkin")),
          body: MultiBlocProvider(
            providers: [
              BlocProvider<CheckinBloc>(
                  create: (BuildContext context) => _checkinBloc =
                      CheckinBloc(repository: _kegiatanDetailRepository)),
              BlocProvider<KodeKegiatanBloc>(
                  create: (BuildContext context) => _kodeKegiatanBloc =
                      KodeKegiatanBloc(repository: _kegiatanDetailRepository)
                        ..add(KodeKegiatanLoad())),
              BlocProvider<AuthenticationBloc>(
                  create: (BuildContext context) => _authenticationBloc =
                      AuthenticationBloc(_authenticationRepository)),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<CheckinBloc, CheckinState>(
                    listener: (context, state) {
                  if (state is CheckinFailure) {
                    if (state.error.toString().contains('Token Expired')) {
                      Navigator.of(context).pop();
                      _authenticationBloc.add(UserLoggedOut());
                    } else {
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) => DialogTextOnly(
                                description: state.error.toString(),
                                buttonText: "OK",
                                onOkPressed: () {
                                  if (state.error
                                      .toString()
                                      .contains('sudah berakhir')) {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                    _kodeKegiatanBloc.add(Logout());
                                  } else {
                                    Navigator.of(context)
                                        .pop(); // To close the dialog
                                  }
                                },
                              ));
                    }
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
                      ),
                    );
                  } else if (state is CheckinLoaded) {
                    CheckinLoaded checkinLoaded = state as CheckinLoaded;
                    Navigator.of(context).pop();
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => DialogTextOnly(
                              description:
                                  checkinLoaded.checkinModel.data.name +
                                      ' berhasil checkin',
                              buttonText: "OK",
                              onOkPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context)
                                    .pop(); // To close the dialog
                              },
                            ));
                    Scaffold.of(context).hideCurrentSnackBar();
                  } else if (state is GetNameLoaded) {
                    GetNameLoaded getNameLoaded = state as GetNameLoaded;
                    _buildConfirmDialog(
                        getNameLoaded.registrationCode,
                        getNameLoaded.labCode,
                        getNameLoaded.eventCode,
                        getNameLoaded.name);
                    Scaffold.of(context).hideCurrentSnackBar();
                  } else {
                    Scaffold.of(context).hideCurrentSnackBar();
                  }
                }),
                BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
                    listener: (context, state) {
                  if (state is KodeKegiatanFailure) {
                    if (state.error.toString().contains('Token Expired')) {
                      _authenticationBloc.add(UserLoggedOut());
                    } else {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) => DialogTextOnly(
                                description: state.error.toString(),
                                buttonText: "OK",
                                onOkPressed: () {
                                  if (state.error
                                          .toString()
                                          .contains('sudah berakhir') ||
                                      state.error.toString().contains(
                                          ErrorException.notFoundEvent)) {
                                    Navigator.of(context).pop();
                                    _kodeKegiatanBloc.add(Logout());
                                  } else {
                                    Navigator.of(context)
                                        .pop(); // To close the dialog
                                    _kodeKegiatanBloc.add(KodeKegiatanLoad());
                                  }
                                },
                              ));
                    }
                    Scaffold.of(context).hideCurrentSnackBar();
                  } else if (state is KodeKegiatanUnauthenticated) {
                    Navigator.of(context).pop();
                  } else {
                    Scaffold.of(context).hideCurrentSnackBar();
                  }
                }),
                BlocListener<AuthenticationBloc, AuthenticationState>(
                    listener: (context, state) {
                  if (state is AuthenticationNotAuthenticated) {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => LoginScreen()));
                  }
                })
              ],
              child: BlocBuilder<KodeKegiatanBloc, KodeKegiatanState>(builder: (
                BuildContext context,
                KodeKegiatanState state,
              ) {
                if (state is KodeKegiatanLoaded) {
                  KodeKegiatanLoaded kodeKegiatanModel =
                      state as KodeKegiatanLoaded;

                  return SafeArea(
                      child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ListView(
                      children: <Widget>[
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Nama Kegiatan Test : '),
                            Expanded(
                                child: Text(
                                    kodeKegiatanModel
                                        .kodeKegiatan.data.eventName,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Waktu : '),
                            Expanded(
                              child: Text(
                                  checkingSameDate(
                                          DateTime.parse(kodeKegiatanModel
                                                  .kodeKegiatan.data.startAt)
                                              .toLocal(),
                                          DateTime.parse(kodeKegiatanModel
                                                  .kodeKegiatan.data.endAt)
                                              .toLocal())
                                      ? unixTimeStampToDateTime(
                                              kodeKegiatanModel
                                                  .kodeKegiatan.data.startAt) +
                                          ' - ' +
                                          unixTimeStampToHour(kodeKegiatanModel
                                              .kodeKegiatan.data.endAt) +
                                          ' WIB'
                                      : "${unixTimeStampToDateWithoutHour(kodeKegiatanModel.kodeKegiatan.data.startAt)} - ${unixTimeStampToDateWithoutHour(kodeKegiatanModel.kodeKegiatan.data.endAt)}",
                                  textAlign: TextAlign.right,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        // Row(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: <Widget>[
                        //     Text('Tempat : '),
                        //     Container(
                        //         width: 300,
                        //         child: Text(
                        //             kodeKegiatanModel
                        //                 .kodeKegiatan.data.eventLocation,
                        //             style: TextStyle(
                        //                 fontWeight: FontWeight.bold))),
                        //   ],
                        // ),
                        // SizedBox(
                        //   height: 5,
                        // ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Tempat Checkin : '),
                            Expanded(
                                child: Text(kodeKegiatanModel.location,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        BlocBuilder<CheckinBloc, CheckinState>(
                          builder: (
                            BuildContext context,
                            CheckinState state,
                          ) {
                            return Column(
                              children: <Widget>[
                                InkWell(
                                  onTap: () async {
                                    var permissionService = Permission.camera;
                                    if (await permissionService
                                        .status.isGranted) {
                                      barcodeScan(kodeKegiatanModel);
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
                                                          context,
                                                          status,
                                                          kodeKegiatanModel);
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
                                    decoration:
                                        BoxDecoration(color: Colors.green),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text('Scan QR Code',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ),
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
                                                      kodeKegiatanModel
                                                          .kodeKegiatan,
                                                )));
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration:
                                        BoxDecoration(color: Colors.green),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text('Input Nomor Pendaftaran',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                        SizedBox(
                          height: 80,
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
                                                  kodeKegiatanModel
                                                      .kodeKegiatan,
                                            )));
                              },
                              child: Text('Lihat Daftar Peserta',
                                  style: TextStyle(color: Colors.white))),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                            width: MediaQuery.of(context).size.width,
                            child: MaterialButton(
                                color: Colors.red,
                                onPressed: () {
                                  _authenticationBloc.add(UserLoggedOut());
                                },
                                child: Text('Logout',
                                    style: TextStyle(color: Colors.white)))),
                      ],
                    ),
                  ));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              }),
            ),
          )),
    );
  }

  barcodeScan(KodeKegiatanLoaded kodeKegiatanModel) async {
    _codeSampleController.text = '';
    var barcode = await BarcodeScanner.scan();
    if (barcode.rawContent != '') {
      print('print');
      print(barcode.rawContent);
      print(barcode.format);
      print(barcode.formatNote);
      print(barcode.type);
      showDialog(
          context: context,
          builder: (BuildContext context) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('No Registrasi anda : '),
                            Expanded(
                                child: Text(barcode.rawContent,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                            'Masukan kode sampel terlebih dahulu atau langsung tekan checkin'),
                        SizedBox(
                          height: 10,
                        ),
                        buildTextField(
                            title: 'Kode Sampel',
                            controller: _codeSampleController,
                            hintText: 'Masukan atau scan kode sampel',
                            isEdit: true,
                            validation: Validations.kodeSampleValidation,
                            qrIcon: true,
                            textInputType: TextInputType.text),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 40.0,
                          child: RaisedButton(
                            splashColor: Colors.lightGreenAccent,
                            padding: EdgeInsets.all(0.0),
                            color: ColorBase.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              'Checkin',
                              style: TextStyle(
                                  fontFamily: FontsFamily.productSans,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                  color: Colors.white),
                            ),
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                FocusScope.of(context).unfocus();
                                _checkinBloc.add(GetNameLoad(
                                    registrationCode: barcode.rawContent,
                                    eventCode: kodeKegiatanModel
                                        .kodeKegiatan.data.eventCode,
                                    labCode: _codeSampleController.text));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
    }
  }

  _buildConfirmDialog(String registrationCode, labCode, eventCode, name) {
    showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.30,
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Nama : '),
                          Expanded(
                              child: Text(name,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('No Registrasi Anda : '),
                          Expanded(
                              child: Text(registrationCode,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Kode Sample : '),
                          Expanded(
                              child: Text(labCode,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                          'Pastikan data sudah benar sebelum menekan tombol submit'),
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
                                'Cancel',
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
                                'Submit',
                                style: TextStyle(
                                    fontFamily: FontsFamily.productSans,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.white),
                              ),
                              onPressed: () {
                                _checkinBloc.add(CheckinLoad(
                                    nomorPendaftaran: registrationCode,
                                    eventCode: eventCode,
                                    labCodeSample: labCode));
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

  Widget buildTextField(
      {String title,
      TextEditingController controller,
      String hintText,
      validation,
      TextInputType textInputType,
      TextStyle textStyle,
      bool isEdit,
      int maxLines,
      bool qrIcon = false}) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 14.0, color: Color(0xff828282)),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  maxLines: maxLines != null ? maxLines : 1,
                  style: isEdit
                      ? TextStyle(
                          color: Colors.black,
                        )
                      : TextStyle(color: Color(0xffBDBDBD)),
                  enabled: isEdit,
                  validator: validation,
                  textCapitalization: TextCapitalization.characters,
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: hintText,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xffE0E0E0), width: 1.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Color(0xffE0E0E0), width: 1.5))),
                  keyboardType: textInputType != null
                      ? textInputType
                      : TextInputType.text,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              qrIcon
                  ? Container(
                      height: 60,
                      width: 60,
                      child: RaisedButton(
                        elevation: 0,
                        color: Colors.white,
                        shape: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Color(0xffE0E0E0), width: 1.5)),
                        onPressed: () async {
                          var barcode = await BarcodeScanner.scan();
                          if (barcode.rawContent != '') {
                            setState(() {
                              controller.text = barcode.rawContent;
                            });
                          }
                        },
                        child: Icon(
                          FontAwesomeIcons.qrcode,
                          color: ColorBase.green,
                        ),
                      ),
                    )
                  : Container()
            ],
          )
        ],
      ),
    );
  }

  bool checkingSameDate(DateTime startAt, endAt) {
    return startAt.year == endAt.year &&
        startAt.month == endAt.month &&
        startAt.day == endAt.day;
  }

  void _onStatusRequested(BuildContext context, PermissionStatus statuses,
      KodeKegiatanLoaded kodeKegiatanModel) async {
    if (statuses.isGranted) {
      barcodeScan(kodeKegiatanModel);
    } else {}
  }

  @override
  void dispose() {
    _checkinBloc.close();

    super.dispose();
  }
}
