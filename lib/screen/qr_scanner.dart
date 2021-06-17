import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/Dimens.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/input_lab_code_screen.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/Validations.dart';
import 'package:scan_preview/scan_preview_widget.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class QRScannerScreen extends StatefulWidget {
  final KodeKegiatanModel kodeKegiatanModel;
  QRScannerScreen({Key key, this.kodeKegiatanModel}) : super(key: key);
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  TextEditingController _codeActivity = TextEditingController();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  final OfflineRepository _offlineRepository = OfflineRepository();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  CheckinBloc _checkinBloc;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    AnalyticsHelper.setLogEvent(Analytics.scanQRScreen);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RaisedButton(
              color: _codeActivity.text.isEmpty
                  ? ColorBase.disableText
                  : ColorBase.green800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  FocusScope.of(context).unfocus();
                  _checkinBloc.add(GetNameLoad(
                      registrationCode: _codeActivity.text,
                      eventCode: widget.kodeKegiatanModel.data.eventCode,
                      labCode: ''));
                  AnalyticsHelper.setLogEvent(
                      Analytics.tappedInputRegistrationCode);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(Dictionary.checkin,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: FontsFamily.lato,
                        fontSize: 16)),
              )),
        ),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<CheckinBloc>(
            create: (context) => _checkinBloc = CheckinBloc(
                repository: _kegiatanDetailRepository,
                offlineRepository: _offlineRepository),
          ),
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
                                if (split.last.toString().contains(
                                    Dictionary.alreadyCheckinMessageOffline)) {
                                  Navigator.of(context)
                                      .pop(); // To close the dialog
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => QRScannerScreen(
                                                kodeKegiatanModel:
                                                    widget.kodeKegiatanModel,
                                              )));
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
                            margin: const EdgeInsets.only(left: 15),
                            child: Text(Dictionary.pleaseWait),
                          )
                        ],
                      ),
                    ),
                  );
                } else if (state is CheckinLoaded) {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => DialogTextOnly(
                            description: state.name + Dictionary.checkinSuccess,
                            buttonText: Dictionary.ok,
                            onOkPressed: () {
                              _codeActivity.text = '';
                              Navigator.of(context).pop();
                              Navigator.of(context)
                                  .pop(); // To close the dialog
                            },
                          ));
                  Scaffold.of(context).hideCurrentSnackBar();
                } else if (state is GetNameLoaded) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => QRScannerScreen(
                                kodeKegiatanModel: widget.kodeKegiatanModel,
                              )));
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InputLabCodePage(
                                getNameLoaded: state,
                              )));
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
                Navigator.of(context).pop();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
                AnalyticsHelper.setLogEvent(Analytics.userTimeOut);
              }
            })
          ],
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                SlidingUpPanel(
                  minHeight: MediaQuery.of(context).size.height * 0.45,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  panel: buildBottomSheets(),
                  body: buildScanArea(),
                ),
                Positioned(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 25,
                      height: 25,
                      padding: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 17,
                      ),
                    ),
                  ),
                  left: 30,
                  top: MediaQuery.of(context).size.height * 05,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBottomSheets() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                  bottom: Dimens.padding, top: Dimens.padding),
              height: 6,
              width: 60,
              decoration: BoxDecoration(
                  color: ColorBase.menuBorderColor,
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            Dictionary.inputRegistrationCOde,
            style: TextStyle(
                fontFamily: FontsFamily.roboto,
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(
            height: 10,
          ),
          buildInfo(),
          const SizedBox(
            height: 10,
          ),
          BuildTextField(
              title: '',
              controller: _codeActivity,
              roundedBorder: 6,
              hintText: Dictionary.registrationCodePlaceholder,
              isEdit: true,
              validation: Validations.registrationCodeValidation,
              textInputType: TextInputType.text),
        ],
      ),
    );
  }

  Widget buildScanArea() {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.62,
          child: ScanPreviewWidget(
            borderColor: 0xffE0BC3D,
            onScanResult: (result) {
              setState(() {
                _codeActivity.text = result;
              });
              _checkinBloc.add(GetNameLoad(
                  registrationCode: result,
                  eventCode: widget.kodeKegiatanModel.data.eventCode,
                  labCode: ''));
              AnalyticsHelper.setLogEvent(Analytics.scanQR);
            },
          ),
        ),
      ],
    );
  }

  Widget buildInfo() {
    return Container(
      width: (MediaQuery.of(context).size.width),
      decoration: BoxDecoration(
          color: ColorBase.announcementBackgroundColor,
          borderRadius: BorderRadius.circular(6)),
      child: Stack(
        children: <Widget>[
          Image.asset('${Environment.imageAssets}intersect.png', width: 60),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    Dictionary.scanQrInfo,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        fontFamily: FontsFamily.lato),
                  )
                ]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeActivity.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
