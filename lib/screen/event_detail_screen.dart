import 'package:app_settings/app_settings.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogRequestPermission.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/screen/offline/participant_list_offline_page.dart';
import 'package:rapid_test/screen/participant_list_page.dart';
import 'package:rapid_test/screen/qr_scanner.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:rapid_test/utilities/Validations.dart';

class EventDetailPage extends StatefulWidget {
  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  final OfflineRepository _offlineRepository = OfflineRepository();
  CheckinBloc _checkinBloc;
  TextEditingController _codeSampleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  bool closeAnnouncement = false;
  KodeKegiatanBloc _kodeKegiatanBloc;
  String activityCode = '';

  @override
  void initState() {
    getAcitivityCode();
    super.initState();
  }

  getAcitivityCode() async {
    activityCode = await Preferences.getDataString(kActivityCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: RaisedButton(
                color: Colors.red[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onPressed: () async {
                  _authenticationBloc.add(UserLoggedOut());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Text(Dictionary.logout,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: FontsFamily.lato,
                          fontSize: 16)),
                )),
          ),
        ),
        backgroundColor: Colors.white,
        appBar: CustomAppBar.defaultAppBar(
            title: Dictionary.testMasifCheckin,
            leading: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: GestureDetector(
                onTap: () {
                  _kodeKegiatanBloc.add(Logout());
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            )),
        body: MultiBlocProvider(
          providers: [
            BlocProvider<CheckinBloc>(
                create: (context) => _checkinBloc = CheckinBloc(
                    repository: _kegiatanDetailRepository,
                    offlineRepository: _offlineRepository)),
            BlocProvider<KodeKegiatanBloc>(
                create: (context) => _kodeKegiatanBloc = KodeKegiatanBloc(
                    repository: _kegiatanDetailRepository,
                    offlineRepository: _offlineRepository)
                  ..add(KodeKegiatanLoad())),
            BlocProvider<AuthenticationBloc>(
                create: (context) => _authenticationBloc =
                    AuthenticationBloc(_authenticationRepository)),
          ],
          child: MultiBlocListener(
            listeners: [
              BlocListener<CheckinBloc, CheckinState>(
                  listener: (BuildContext context, CheckinState state) {
                if (state is CheckinFailure) {
                  if (state.error
                      .toString()
                      .contains(Dictionary.tokenExpired)) {
                    Navigator.of(context).pop();
                    _authenticationBloc.add(UserLoggedOut());
                  } else {
                    final List<String> split =
                        state.error.split(Dictionary.exeption);
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
                            margin: const EdgeInsets.only(left: 15.0),
                            child: Text(Dictionary.pleaseWait),
                          )
                        ],
                      ),
                    ),
                  );
                } else if (state is CheckinLoaded) {
                  Navigator.of(context).pop();
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) => DialogTextOnly(
                            description: state.name + Dictionary.checkinSuccess,
                            buttonText: Dictionary.ok,
                            onOkPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pop(); // To close the dialog
                            },
                          ));
                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is GetNameLoaded) {
                  _buildConfirmDialog(state.registrationCode, state.labCode,
                      state.eventCode, state.name);
                  Scaffold.of(context).hideCurrentSnackBar();
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                }
              }),
              BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
                  listener: (BuildContext context, KodeKegiatanState state) {
                if (state is KodeKegiatanFailure) {
                  if (state.error
                      .toString()
                      .contains(Dictionary.tokenExpired)) {
                    _authenticationBloc.add(UserLoggedOut());
                  } else {
                    final List<String> split =
                        state.error.split(Dictionary.exeption);
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) => DialogTextOnly(
                              description: split.last.toString(),
                              buttonText: Dictionary.ok,
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
                  listener: (BuildContext context, AuthenticationState state) {
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
                final KodeKegiatanLoaded kodeKegiatanModel = state;
                return SafeArea(
                    child: ListView(
                  children: <Widget>[
                    ConnectivityWidgetWrapper(
                      stacked: false,
                      offlineWidget: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 50,
                        color: Colors.red,
                        child: Center(
                          child: Text(
                            Dictionary.offlineMode,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: FontsFamily.roboto,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                      ),
                      child: Container(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                      child: Column(
                        children: [
                          closeAnnouncement ? Container() : buildInfo(),
                          const SizedBox(
                            height: 10,
                          ),
                          buildDetailInformation(kodeKegiatanModel),
                          const SizedBox(
                            height: 20,
                          ),
                          BlocBuilder<CheckinBloc, CheckinState>(
                            builder: (
                              BuildContext context,
                              CheckinState state,
                            ) {
                              return buildButton(kodeKegiatanModel);
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
          ),
        ));
  }

  barcodeScan(KodeKegiatanLoaded kodeKegiatanModel) async {
    _codeSampleController.text = '';
    final ScanResult barcode = await BarcodeScanner.scan();
    if (barcode.rawContent != '') {
      showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
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
                        const SizedBox(
                          height: 10,
                        ),
                        Text(Dictionary.checkinDesc),
                        const SizedBox(
                          height: 10,
                        ),
                        BuildTextField(
                            title: Dictionary.labCode,
                            roundedBorder: 4,
                            controller: _codeSampleController,
                            hintText: Dictionary.labCodePlaceholder,
                            isEdit: true,
                            validation: Validations.sampleCodeValidation,
                            qrIcon: true,
                            textInputType: TextInputType.text),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 40.0,
                          child: RaisedButton(
                            splashColor: Colors.lightGreenAccent,
                            padding: const EdgeInsets.all(0.0),
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
                  padding: const EdgeInsets.all(10.0),
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
                      const SizedBox(
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
                      const SizedBox(
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
                      const SizedBox(
                        height: 10,
                      ),
                      Text(Dictionary.warningBeforeCheckin),
                      const SizedBox(
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
                              padding: const EdgeInsets.all(0.0),
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
                              padding: const EdgeInsets.all(0.0),
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

  Widget buildInfo() {
    return Container(
      width: (MediaQuery.of(context).size.width),
      decoration: BoxDecoration(
          color: ColorBase.announcementBackgroundColor,
          borderRadius: BorderRadius.circular(6.0)),
      child: Stack(
        children: <Widget>[
          Image.asset('${Environment.imageAssets}intersect.png', width: 60),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    Dictionary.infoParticipantList,
                    style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey[600],
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontsFamily.lato),
                  )
                ]),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  closeAnnouncement = true;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.close,
                  color: Colors.black.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildDetailInformation(KodeKegiatanLoaded kodeKegiatanModel) {
    return GestureDetector(
      onTap: () async {
        if (await ConnectivityWrapper.instance.isConnected) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ParticipantListPage(
                        kodeKegiatanModel: kodeKegiatanModel.kodeKegiatan,
                      )));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ParticipantListOfflinePage(
                        kodeKegiatanModel: kodeKegiatanModel.kodeKegiatan,
                      )));
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: Colors.blue[200].withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[700], width: 0.2)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                child: Text(
              kodeKegiatanModel.kodeKegiatan.data.eventName,
              textAlign: TextAlign.left,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: FontsFamily.roboto,
                  fontSize: 16),
            )),
            const SizedBox(
              height: 10,
            ),
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
                      DateTime.parse(
                              kodeKegiatanModel.kodeKegiatan.data.startAt)
                          .toLocal(),
                      DateTime.parse(kodeKegiatanModel.kodeKegiatan.data.endAt)
                          .toLocal())
                  ? unixTimeStampToDateWithoutHour(
                      kodeKegiatanModel.kodeKegiatan.data.startAt)
                  : "${unixTimeStampToDateWithoutHour(kodeKegiatanModel.kodeKegiatan.data.startAt)} - ${unixTimeStampToDateWithoutHour(kodeKegiatanModel.kodeKegiatan.data.endAt)}",
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: FontsFamily.roboto,
                  fontSize: 12),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              unixTimeStampToHour(kodeKegiatanModel.kodeKegiatan.data.startAt) +
                  ' - ' +
                  unixTimeStampToHour(
                      kodeKegiatanModel.kodeKegiatan.data.endAt) +
                  Dictionary.wib,
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: FontsFamily.roboto,
                  fontSize: 12),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              Dictionary.checkinLocation,
              style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontFamily: FontsFamily.roboto,
                  fontSize: 10),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              kodeKegiatanModel.location,
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: FontsFamily.roboto,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(KodeKegiatanLoaded kodeKegiatanModel) {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: () async {
            var permissionService = Permission.camera;
            if (await permissionService.status.isGranted) {
              // barcodeScan(kodeKegiatanModel);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => QRScannerScreen(
                            kodeKegiatanModel: kodeKegiatanModel.kodeKegiatan,
                          )));
            } else {
              showDialog(
                  context: context,
                  builder: (BuildContext context) => DialogRequestPermission(
                        image: Image.asset(
                          '${Environment.iconAssets}map_pin.png',
                          fit: BoxFit.contain,
                          color: Colors.white,
                        ),
                        description: Dictionary.scanQRPermission,
                        onOkPressed: () async {
                          Navigator.of(context).pop();
                          if (await permissionService.status.isDenied) {
                            await AppSettings.openLocationSettings();
                          } else {
                            permissionService.request().then((status) {
                              _onStatusRequested(
                                  context, status, kodeKegiatanModel);
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
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[700])),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('${Environment.iconAssets}scan_qr.png',
                      width: 27),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(Dictionary.scanQR,
                      style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w400,
                          fontFamily: FontsFamily.roboto,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
      ],
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
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => QRScannerScreen(
                    kodeKegiatanModel: kodeKegiatanModel.kodeKegiatan,
                  )));
    }
  }

  @override
  void dispose() {
    _codeSampleController.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
