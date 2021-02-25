import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/checkin/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/CustomAppBar.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/Validations.dart';

import 'login_screen.dart';

class InputLabCodePage extends StatefulWidget {
  final GetNameLoaded getNameLoaded;
  InputLabCodePage({Key key, this.getNameLoaded}) : super(key: key);
  @override
  _InputLabCodePageState createState() => _InputLabCodePageState();
}

class _InputLabCodePageState extends State<InputLabCodePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  CheckinBloc _checkinBloc;
  TextEditingController _codeActivity = TextEditingController();
  TextEditingController _codeSampleController = TextEditingController();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  AuthenticationBloc _authenticationBloc;
  final OfflineRepository _offlineRepository = OfflineRepository();
  @override
  void initState() {
    AnalyticsHelper.setLogEvent(Analytics.labCodeScreen);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar.defaultAppBar(
            title: Dictionary.inputlabCode,
            leading: Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
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
                                  if (split.last.toString() ==
                                      Dictionary.alreadyCheckinMessage) {
                                    Navigator.of(context)
                                        .pop(); // To close the dialog
                                    Navigator.of(context)
                                        .pop(); // Exit to scan qr screen
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
                              description:
                                  state.name + Dictionary.checkinSuccess,
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
                    _buildConfirmDialog(state.registrationCode, state.labCode,
                        state.eventCode, state.name);
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
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                  AnalyticsHelper.setLogEvent(Analytics.userTimeOut);
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
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
                        Container(
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: ColorBase.lightGrey, width: 1)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 15),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Image.asset(
                                                '${Environment.iconAssets}people_icon.png',
                                                width: 15),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(widget.getNameLoaded.name,
                                                style: TextStyle(
                                                    color: Colors.black
                                                        .withOpacity(0.8),
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily:
                                                        FontsFamily.roboto,
                                                    fontSize: 16)),
                                          ],
                                        )
                                      ],
                                    )),
                                SizedBox(
                                  height: 1,
                                  child: Container(
                                    color: ColorBase.lightGrey,
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0, horizontal: 15),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 25,
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  Dictionary.numberRegistration,
                                                  style: TextStyle(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontFamily:
                                                          FontsFamily.roboto,
                                                      fontSize: 14)),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Text(
                                                  widget.getNameLoaded
                                                      .registrationCode,
                                                  style: TextStyle(
                                                      color: Colors.black
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontFamily:
                                                          FontsFamily.roboto,
                                                      fontSize: 16)),
                                            ],
                                          ),
                                        ),
                                        Image.asset(
                                            '${Environment.iconAssets}check_circle.png',
                                            width: 30),
                                      ],
                                    )),
                              ],
                            )),
                        const SizedBox(
                          height: 20,
                        ),
                        buildInfo(),
                        const SizedBox(
                          height: 10,
                        ),
                        BuildTextField(
                            title: '',
                            controller: _codeSampleController,
                            roundedBorder: 6,
                            descriptionText: Dictionary.labSampleDescription,
                            validation: Validations.sampleCodeValidation,
                            hintText: Dictionary.labCodePlaceholder,
                            isEdit: true,
                            qrIcon: false,
                            textInputType: TextInputType.text),
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: RaisedButton(
                              color: _codeSampleController.text.isEmpty
                                  ? ColorBase.disableText
                                  : ColorBase.green800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState.validate()) {
                                  _checkinBloc.add(CheckinLoad(
                                      nomorPendaftaran:
                                          widget.getNameLoaded.registrationCode,
                                      eventCode: widget.getNameLoaded.eventCode,
                                      labCodeSample:
                                          _codeSampleController.text));
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15.0),
                                child: Text(Dictionary.submit,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: FontsFamily.lato,
                                        fontSize: 16)),
                              )),
                        ),
                      ],
                    ),
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
        builder: (context) => Dialog(
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
                    Dictionary.sampleNumberInfo,
                    style: TextStyle(
                        fontSize: 12.0,
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
    _codeSampleController.dispose();
    _checkinBloc.close();
    super.dispose();
  }
}
