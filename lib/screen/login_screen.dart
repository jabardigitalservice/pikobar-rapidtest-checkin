import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/login/login_bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/event_list.dart';
import 'package:rapid_test/screen/home.dart';
import 'package:rapid_test/utilities/Validations.dart';

class LoginScreen extends StatelessWidget {
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  @override
  Widget build(BuildContext context) {
    final authenticationRepository = AuthenticationRepository();
    return BlocProvider<LoginBloc>(
        create: (context) => LoginBloc(
            BlocProvider.of<AuthenticationBloc>(context),
            authenticationRepository,
            _kegiatanDetailRepository),
        child: Scaffold(
          appBar: AppBar(
            title: Text(Dictionary.loginScreen),
          ),
          body: LoginForm(),
        ));
  }
}

class LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<LoginForm> {
  LoginBloc _loginBloc;
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController _location = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _loginBloc = BlocProvider.of<LoginBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _loginSubmitted() {
      _loginBloc.add(LoginSubmitted(
          username: nameController.text,
          password: passwordController.text,
          location: _location.text));
    }

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginFailure) {
          var split = state.error.split('Exception:');
          showDialog(
              context: context,
              builder: (BuildContext context) => DialogTextOnly(
                    description: split.last.toString(),
                    buttonText: Dictionary.ok,
                    onOkPressed: () {
                      Navigator.of(context).pop(); // To close the dialog
                    },
                  ));
          Scaffold.of(context).hideCurrentSnackBar();
        } else if (state is LoginSuccess) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => EventListPage()));
        } else if (state is LoginLoading) {
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
        } else {
          Scaffold.of(context).hideCurrentSnackBar();
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: ListView(
                children: <Widget>[
                  BuildTextField(
                    title: Dictionary.username,
                    controller: nameController,
                    hintText: Dictionary.usernamePlaceholder,
                    textCapitalization: TextCapitalization.none,
                    textInputType: TextInputType.emailAddress,
                    isEdit: true,
                    validation: Validations.usernameValidation,
                  ),
                  SizedBox(height: 15),
                  BuildTextField(
                    title: Dictionary.password,
                    controller: passwordController,
                    hintText: Dictionary.passwordPlaceholder,
                    textCapitalization: TextCapitalization.none,
                    isEdit: true,
                    obsecureText: true,
                    validation: Validations.passwordValidation,
                  ),
                  SizedBox(height: 15),
                  BuildTextField(
                    title: Dictionary.location,
                    controller: _location,
                    hintText: Dictionary.locationPlaceholder,
                    isEdit: true,
                    textCapitalization: TextCapitalization.characters,
                    validation: Validations.locationValidation,
                  ),
                  SizedBox(height: 15),
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
                        Dictionary.login,
                        style: TextStyle(
                            fontFamily: FontsFamily.productSans,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            color: Colors.white),
                      ),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          FocusScope.of(context).unfocus();
                          _loginSubmitted();
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(child: Text(Dictionary.or)),
                  SizedBox(
                    height: 20,
                  ),
                  FlatButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyHomePage()));
                      },
                      child: Text(
                        Dictionary.inputActivityCode,
                        style: TextStyle(color: Colors.blue),
                      )),
                  SizedBox(
                    height: 20,
                  ),
                  // Center(child: Text('Atau')),
                  // SizedBox(
                  //   height: 20,
                  // ),
                  // FlatButton(
                  //     onPressed: () {
                  //       Navigator.push(
                  //           context,
                  //           MaterialPageRoute(
                  //               builder: (context) => InputActivityCodeOffline()));
                  //     },
                  //     child: Text(
                  //       'Offline Mode',
                  //       style: TextStyle(color: Colors.blue),
                  //     ))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showError(String error) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(error),
      backgroundColor: Theme.of(context).errorColor,
    ));
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
