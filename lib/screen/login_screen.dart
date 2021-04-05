import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/blocs/login/login_bloc.dart';
import 'package:rapid_test/components/BuildTextField.dart';
import 'package:rapid_test/components/DialogTextOnly.dart';
import 'package:rapid_test/constants/Analytics.dart';
import 'package:rapid_test/constants/Colors.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/environment/environment/Environment.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/event_list.dart';
import 'package:rapid_test/screen/input_event_code.dart';
import 'package:rapid_test/utilities/AnalyticsHelper.dart';
import 'package:rapid_test/utilities/Validations.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key key}) : super(key: key);
  final KegiatanDetailRepository _kegiatanDetailRepository =
      KegiatanDetailRepository();
  @override
  Widget build(BuildContext context) {
    AuthenticationRepository authenticationRepository =
        AuthenticationRepository();
    return BlocProvider<LoginBloc>(
        create: (BuildContext context) => LoginBloc(
            BlocProvider.of<AuthenticationBloc>(context),
            authenticationRepository,
            _kegiatanDetailRepository),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: LoginForm(),
        ));
  }
}

class LoginForm extends StatefulWidget {
  LoginForm({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<LoginForm> {
  LoginBloc _loginBloc;
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _loginBloc = BlocProvider.of<LoginBloc>(context);
    AnalyticsHelper.setLogEvent(Analytics.loginScreen);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
        listener: (BuildContext context, LoginState state) {
          if (state is LoginFailure) {
            final List<String> split = state.error.split(Dictionary.exeption);
            showDialog(
                context: context,
                builder: (context) => DialogTextOnly(
                      description: split.last
                              .toString()
                              .contains(Dictionary.unauthorizedText)
                          ? Dictionary.unauthorized
                          : split.last.toString(),
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
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ListView(
              children: <Widget>[
                buildHeader(),
                SizedBox(height: 20),
                buildContent(),
                SizedBox(height: 30),
                buildButton(),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ));
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
            SizedBox(
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
                  SizedBox(
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

  Widget buildContent() {
    return Column(
      children: [
        BuildTextField(
          title: Dictionary.username,
          roundedBorder: 4,
          controller: nameController,
          hintText: Dictionary.usernamePlaceholder,
          textCapitalization: TextCapitalization.none,
          textInputType: TextInputType.emailAddress,
          isEdit: true,
          validation: Validations.usernameValidation,
          descriptionText: Dictionary.usernameDescription,
        ),
        SizedBox(height: 15),
        BuildTextField(
          title: Dictionary.location,
          roundedBorder: 4,
          controller: _location,
          hintText: Dictionary.locationPlaceholder,
          isEdit: true,
          textCapitalization: TextCapitalization.words,
          validation: Validations.locationValidation,
          descriptionText: Dictionary.locationDescription,
        ),
        SizedBox(height: 15),
        BuildTextField(
          title: Dictionary.password,
          controller: passwordController,
          roundedBorder: 4,
          hintText: Dictionary.passwordPlaceholder,
          textCapitalization: TextCapitalization.none,
          isEdit: true,
          obsecureText: true,
          validation: Validations.passwordValidation,
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
            padding: EdgeInsets.all(0.0),
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
                _loginBloc.add(LoginSubmitted(
                    username: nameController.text,
                    password: passwordController.text,
                    location: _location.text));
              }
            },
          ),
        ),
        SizedBox(
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
              padding: EdgeInsets.symmetric(horizontal: 10),
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
        SizedBox(
          height: 20,
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          height: 50.0,
          child: RaisedButton(
            splashColor: Colors.lightGreenAccent,
            elevation: 0,
            padding: EdgeInsets.all(0.0),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              Dictionary.activityCode,
              style: TextStyle(
                  fontFamily: FontsFamily.lato,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0,
                  color: Colors.black),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => InputEventCodePage()));
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    _location.dispose();
    super.dispose();
  }
}
