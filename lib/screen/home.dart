import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rapid_test/blocs/account_profile/account_profile_bloc.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/kode_kegiatan/Bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/kegiatan_detail.dart';
import 'package:rapid_test/utilities/Validations.dart';

import 'login_screen.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _codeActivity = TextEditingController();
  final _location = TextEditingController();

// init repositories
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  final OfflineRepository _offlineRepository = OfflineRepository();

  // init bloc
  AccountProfileBloc _accountProfileBloc;
  KodeKegiatanBloc _kodeKegiatanBloc;
  AuthenticationBloc _authenticationBloc;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    initializeDateFormatting();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(Dictionary.testMasifCheckin)),
        body: MultiBlocProvider(
          providers: [
            // bloc get account user
            BlocProvider<AccountProfileBloc>(
              create: (BuildContext context) => _accountProfileBloc =
                  AccountProfileBloc(_authenticationRepository)
                    ..add(AccountProfileLoad()),
            ),

            // bloc kegiatan
            BlocProvider<KodeKegiatanBloc>(
              create: (BuildContext context) =>
                  _kodeKegiatanBloc = KodeKegiatanBloc(
                      repository: _kegiatanDetailRepository,
                      offlineRepository: _offlineRepository)
                    ..add(AppStart()),
            ),

            // bloc auth
            BlocProvider<AuthenticationBloc>(
                create: (BuildContext context) => _authenticationBloc =
                    AuthenticationBloc(_authenticationRepository)),
          ],
          child: BlocListener<AuthenticationBloc, AuthenticationState>(
            listener: (context, state) {
              if (state is AuthenticationNotAuthenticated) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              }
            },
            child: BlocListener<KodeKegiatanBloc, KodeKegiatanState>(
                listener: (context, state) {
                  if (state is KodeKegiatanFailure) {
                    if (state.error.toString().contains('Token Expired')) {
                      _authenticationBloc.add(UserLoggedOut());
                    } else {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => DialogTextOnly(
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
                              margin: EdgeInsets.only(left: 15.0),
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
                            builder: (context) => KegiatanPage()));
                  } else {
                    Scaffold.of(context).hideCurrentSnackBar();
                  }
                },
                child: _buildContent()),
          ),
        ));
  }

  _buildContent() {
    return BlocBuilder<KodeKegiatanBloc, KodeKegiatanState>(
      builder: (
        BuildContext context,
        KodeKegiatanState state,
      ) {
        if (state is InitialKodeKegiatanState ||
            state is KodeKegiatanLoading ||
            state is KodeKegiatanFailure ||
            state is KodeKegiatanSuccessMovePage ||
            state is KodeKegiatanUnauthenticated) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BuildTextField(
                    title: Dictionary.activityCode,
                    controller: _codeActivity,
                    hintText: Dictionary.activityCodePlaceholder,
                    isEdit: true,
                    validation: Validations.kodeValidation,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  BuildTextField(
                    title: Dictionary.location,
                    controller: _location,
                    hintText: Dictionary.locationPlaceholder,
                    isEdit: true,
                    validation: Validations.locationValidation,
                  ),
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
                        Dictionary.submit,
                        style: TextStyle(
                            fontFamily: FontsFamily.productSans,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
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
                  SizedBox(
                    height: 20,
                  ),
                  FlatButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                      child: Center(
                        child: Text(
                          Dictionary.backToLogin,
                          style: TextStyle(color: Colors.blue),
                        ),
                      ))
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
