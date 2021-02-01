import 'package:barcode_scan/barcode_scan.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/utilities/Validations.dart';

import 'login_screen.dart';

class InputNomor extends StatefulWidget {
  final KodeKegiatanModel kodeKegiatanModel;
  InputNomor({this.kodeKegiatanModel});
  @override
  _InputNomorState createState() => _InputNomorState();
}

class _InputNomorState extends State<InputNomor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  CheckinBloc _checkinBloc;
  final _codeActivity = TextEditingController();
  final _codeSampleController = TextEditingController();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  final OfflineRepository _offlineRepository = OfflineRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(Dictionary.inputRegistrationCOde)),
        body: MultiBlocProvider(
          providers: [
            BlocProvider<CheckinBloc>(
              create: (BuildContext context) => _checkinBloc = CheckinBloc(
                  repository: _kegiatanDetailRepository,
                  offlineRepository: _offlineRepository),
            ),
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
                      _authenticationBloc.add(UserLoggedOut());
                    } else {
                      var split = state.error.split('Exception:');
                      showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) => DialogTextOnly(
                                description: split.last.toString(),
                                buttonText: Dictionary.ok,
                                onOkPressed: () {
                                  Navigator.of(context)
                                      .pop(); // To close the dialog
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
                              child: Text(Dictionary.pleaseWait),
                            )
                          ],
                        ),
                      ),
                    );
                  } else if (state is CheckinLoaded) {
                    CheckinLoaded checkinLoaded = state as CheckinLoaded;
                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) => DialogTextOnly(
                              description: checkinLoaded.name +
                                  Dictionary.checkinSuccess,
                              buttonText: Dictionary.ok,
                              onOkPressed: () {
                                _codeActivity.text = '';
                                _codeSampleController.text = '';
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
                },
              ),
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
            child: BlocBuilder<CheckinBloc, CheckinState>(
              builder: (
                BuildContext context,
                CheckinState state,
              ) {
                return Form(
                  key: _formKey,
                  child: Column(
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ),
                        ),
                        child: Container(),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BuildTextField(
                                  title: Dictionary.registrationCode,
                                  controller: _codeActivity,
                                  hintText:
                                      Dictionary.registrationCodePlaceholder,
                                  isEdit: true,
                                  validation: Validations.kodeValidation,
                                  textInputType: TextInputType.text),
                              SizedBox(
                                height: 10,
                              ),
                              BuildTextField(
                                  title: Dictionary.labCode,
                                  controller: _codeSampleController,
                                  validation: Validations.kodeSampleValidation,
                                  hintText: Dictionary.labCodePlaceholder,
                                  isEdit: true,
                                  qrIcon: true,
                                  textInputType: TextInputType.text),
                              SizedBox(
                                height: 20,
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
                                          registrationCode: _codeActivity.text,
                                          eventCode: widget
                                              .kodeKegiatanModel.data.eventCode,
                                          labCode: _codeSampleController.text));
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ));
  }

  _buildConfirmDialog(String registrationCode, labCode, eventCode, name) {
    showDialog(
        barrierDismissible: false,
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

  @override
  void dispose() {
    _codeActivity.dispose();
    _codeSampleController.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
