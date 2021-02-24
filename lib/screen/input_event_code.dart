import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/event_detail_screen.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/Validations.dart';

import 'login_screen.dart';

class InputEventCodePage extends StatefulWidget {
  InputEventCodePage({Key key}) : super(key: key);
  @override
  _InputEventCodePageState createState() => _InputEventCodePageState();
}

class _InputEventCodePageState extends State<InputEventCodePage> {
  TextEditingController _codeActivity = TextEditingController();
  TextEditingController _location = TextEditingController();

// init repositories
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  final OfflineRepository _offlineRepository = OfflineRepository();

  // init bloc
  KodeKegiatanBloc _kodeKegiatanBloc;
  AuthenticationBloc _authenticationBloc;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    initializeDateFormatting();
    AnalyticsHelper.setLogEvent(Analytics.activityCodeScreen);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
          backgroundColor: Colors.white,
          body: MultiBlocProvider(
            providers: [
              // bloc kegiatan
              BlocProvider<KodeKegiatanBloc>(
                create: (context) => _kodeKegiatanBloc = KodeKegiatanBloc(
                    repository: _kegiatanDetailRepository,
                    offlineRepository: _offlineRepository)
                  ..add(AppStart()),
              ),

              // bloc auth
              BlocProvider<AuthenticationBloc>(
                  create: (context) => _authenticationBloc =
                      AuthenticationBloc(_authenticationRepository)),
            ],
            child: BlocListener<AuthenticationBloc, AuthenticationState>(
              listener: (BuildContext context, AuthenticationState state) {
                if (state is AuthenticationNotAuthenticated) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }
              },
              child: BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
                  listener: (BuildContext context, KodeKegiatanState state) {
                    if (state is KodeKegiatanFailure) {
                      if (state.error
                          .toString()
                          .contains(Dictionary.tokenExpired)) {
                        _authenticationBloc.add(UserLoggedOut());
                      } else {
                        showDialog(
                            context: context,
                            builder: (context) => DialogTextOnly(
                                description: state.error.toString(),
                                buttonText: Dictionary.ok,
                                onOkPressed: () {
                                  Navigator.of(context)
                                      .pop(); // To close the dialog
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
                                margin: const EdgeInsets.only(left: 15.0),
                                child: Text(Dictionary.pleaseWait),
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
                              builder: (context) => EventDetailPage()));
                    } else {
                      Scaffold.of(context).hideCurrentSnackBar();
                    }
                  },
                  child: _buildContent()),
            ),
          )),
    );
  }

  _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: <Widget>[
          buildHeader(),
          const SizedBox(height: 20),
          buildContentTextField(),
          const SizedBox(height: 30),
          buildButton(),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Image.asset(
              '${Environment.iconAssets}login_icon.png',
              height: MediaQuery.of(context).size.height * 0.22,
            ),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Dictionary.login,
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: FontsFamily.roboto,
                        color: ColorBase.green900,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    Dictionary.welcomeText,
                    style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        fontFamily: FontsFamily.roboto,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget buildContentTextField() {
    return Column(
      children: [
        BuildTextField(
          title: Dictionary.activityCode,
          roundedBorder: 4,
          controller: _codeActivity,
          hintText: Dictionary.activityCodePlaceholder,
          isEdit: true,
          validation: Validations.eventCodeValidation,
        ),
        const SizedBox(
          height: 10,
        ),
        BuildTextField(
          roundedBorder: 4,
          title: Dictionary.location,
          controller: _location,
          hintText: Dictionary.locationPlaceholder,
          textCapitalization: TextCapitalization.words,
          isEdit: true,
          validation: Validations.locationValidation,
          descriptionText: Dictionary.locationDescription,
        ),
      ],
    );
  }

  Widget buildButton() {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: 50.0,
          child: RaisedButton(
            splashColor: Colors.lightGreenAccent,
            elevation: 0,
            padding: const EdgeInsets.all(0.0),
            color: ColorBase.green800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              Dictionary.loginButton,
              style: TextStyle(
                  fontFamily: FontsFamily.lato,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                  color: Colors.white),
            ),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                FocusScope.of(context).unfocus();
                _kodeKegiatanBloc.add(KodeKegiatanMovePage(
                    kodeKegiatan: _codeActivity.text,
                    location: _location.text,
                    isFromLogin: false));
              }
            },
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Container(
              height: 0.5,
              color: Colors.black,
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                Dictionary.or,
                style: TextStyle(
                    fontFamily: FontsFamily.lato,
                    fontSize: 11.0,
                    color: Colors.black),
              ),
            ),
            Expanded(
                child: Container(
              height: 0.5,
              color: Colors.black,
            )),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: 50.0,
          child: RaisedButton(
            splashColor: Colors.lightGreenAccent,
            elevation: 0,
            padding: const EdgeInsets.all(0.0),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              Dictionary.login,
              style: TextStyle(
                  fontFamily: FontsFamily.lato,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                  color: Colors.black),
            ),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeActivity.dispose();
    _location.dispose();
    _kodeKegiatanBloc.close();
    _authenticationBloc.close();
    super.dispose();
  }
}
