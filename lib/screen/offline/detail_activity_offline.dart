import 'package:app_settings/app_settings.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/blocs/offline/checkin_offline/Bloc.dart';
import 'package:rapid_test/components/DialogRequestPermission.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/screen/offline/checkin_list.dart';
import 'package:rapid_test/screen/offline/input_checkin_offline.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:rapid_test/utilities/Validations.dart';

class ActivityOfflinePage extends StatefulWidget {
  final String codeActivity, location;
  ActivityOfflinePage(this.codeActivity, this.location);

  @override
  _ActivityOfflinePageState createState() => _ActivityOfflinePageState();
}

class _ActivityOfflinePageState extends State<ActivityOfflinePage> {
  CheckinOfflineBloc _checkinBloc;
  final _codeSampleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  OfflineRepository _offlineRepository = OfflineRepository();
  KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  AuthenticationBloc _authenticationBloc;

  KodeKegiatanBloc _kodeKegiatanBloc;
  var activityCode = '';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Preferences.clearData('activityCode');
        Navigator.pop(context);
      },
      child: Scaffold(
          appBar: AppBar(title: Text(Dictionary.testMasifOffline)),
          body: MultiBlocProvider(
            providers: [
              BlocProvider<CheckinOfflineBloc>(
                  create: (BuildContext context) => _checkinBloc =
                      CheckinOfflineBloc(repository: _offlineRepository)),
            ],
            child: MultiBlocListener(
                listeners: [
                  BlocListener<CheckinOfflineBloc, CheckinOfflineState>(
                      listener: (context, state) {
                    if (state is CheckinOfflineFailure) {
                      var split = state.error.split('Exception:');
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) => DialogTextOnly(
                                description: split.last.toString(),
                                buttonText: Dictionary.ok,
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

                      Scaffold.of(context).hideCurrentSnackBar();
                    } else if (state is CheckinOfflineLoading) {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Theme.of(context).primaryColor,
                          content: Row(
                            children: <Widget>[
                              CircularProgressIndicator(),
                              Container(
                                margin: EdgeInsets.only(left: 15.0),
                                child: Text(Dictionary.pleaseWait),
                              )
                            ],
                          ),
                        ),
                      );
                    } else if (state is CheckinOfflineLoaded) {
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => DialogTextOnly(
                                description: Dictionary.checkinSuccessOffline,
                                buttonText: Dictionary.ok,
                                onOkPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context)
                                      .pop(); // To close the dialog
                                },
                              ));
                      Scaffold.of(context).hideCurrentSnackBar();
                    } else if (state is GetNameLoaded) {
                      GetNameLoaded getNameLoaded = state as GetNameLoaded;
                      _buildConfirmDialog(getNameLoaded.labCode,
                          getNameLoaded.registrationCode, getNameLoaded.name);
                      Scaffold.of(context).hideCurrentSnackBar();
                    } else {
                      Scaffold.of(context).hideCurrentSnackBar();
                    }
                  }),
                ],
                child: SafeArea(
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
                          Text(Dictionary.activityCodeTitle),
                          Expanded(
                              child: Text(widget.codeActivity,
                                  textAlign: TextAlign.right,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(Dictionary.checkinLocation),
                          Expanded(
                              child: Text(widget.location,
                                  textAlign: TextAlign.right,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                      ),
                      BlocBuilder<CheckinOfflineBloc, CheckinOfflineState>(
                        builder: (
                          BuildContext context,
                          CheckinOfflineState state,
                        ) {
                          return Column(
                            children: <Widget>[
                              InkWell(
                                onTap: () async {
                                  var permissionService = Permission.camera;
                                  if (await permissionService
                                      .status.isGranted) {
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
                                                  Dictionary.scanQRPermission,
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
                                                    );
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
                                    child: Text(Dictionary.scanQR,
                                        style: TextStyle(color: Colors.white)),
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
                                          builder: (context) =>
                                              InputCheckinOffline()));
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration:
                                      BoxDecoration(color: Colors.green),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                        Dictionary.inputRegistrationCode,
                                        style: TextStyle(color: Colors.white)),
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
                                      builder: (context) => CheckinList()));
                            },
                            child: Text(Dictionary.listDataCheckin,
                                style: TextStyle(color: Colors.white))),
                      ),
                    ],
                  ),
                ))),
          )),
    );
  }

  barcodeScan() async {
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
                            Text(Dictionary.yourRegistrationCode),
                            Expanded(
                                child: Text(barcode.rawContent,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(Dictionary.checkinDesc),
                        SizedBox(
                          height: 10,
                        ),
                        buildTextField(
                            title: Dictionary.labCode,
                            controller: _codeSampleController,
                            hintText: Dictionary.labCodePlaceholder,
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
                              Dictionary.checkin,
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

  _buildConfirmDialog(String labCode, registrationCode, name) {
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
                          Text(Dictionary.name),
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
                          Text(Dictionary.yourRegistrationCode),
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
                          Text(Dictionary.labCodeInput),
                          Expanded(
                              child: Text(labCode,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(Dictionary.warningBeforeCheckin),
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
                                Dictionary.cancel,
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
                                Dictionary.submit,
                                style: TextStyle(
                                    fontFamily: FontsFamily.productSans,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                    color: Colors.white),
                              ),
                              onPressed: () {
                                _checkinBloc.add(CheckinOfflineLoad(
                                    labCodeSample: labCode,
                                    nomorPendaftaran: registrationCode));
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

  void _onStatusRequested(
    BuildContext context,
    PermissionStatus statuses,
  ) async {
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
