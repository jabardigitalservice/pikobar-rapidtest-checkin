import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/FontsFamily.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/screen/login_screen.dart';
import 'package:rapid_test/utilities/http.dart'; // make dio as global variable
import 'package:rapid_test/utilities/logging_interceptors.dart';
import 'package:rapid_test/utilities/navigation_service.dart';
import 'package:rapid_test/config/router.dart' as router;

import 'config/FlavorConfig.dart';
import 'environment/environment/Environment.dart';
import 'screen/event_list.dart';

void main() {
  FlavorConfig(
    flavor: Flavor.STAGING,
    color: Colors.blue,
    values: FlavorValues(
        baseUrl: Environment.stagingUrl,
        clientId: Environment.stagingclientId,
        loginUrl: Environment.loginStagingUrl),
  );

  // init DIO options
  dio.options.connectTimeout = 50000;
  dio.options.receiveTimeout = 50000;
  dio.options.contentType = "application/json";

  // add interceptors
  dio.interceptors.add(LoggingInterceptors());

  runApp(
    BlocProvider<AuthenticationBloc>(
      create: (BuildContext context) {
        AuthenticationRepository authenticationRepository =
            AuthenticationRepository();
        return AuthenticationBloc(authenticationRepository)..add(AppLoaded());
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    return ConnectivityAppWrapper(
      app: MaterialApp(
        title: Dictionary.pikobarTestMasif,
        theme: ThemeData(
            primaryColor: Colors.blue,
            primaryColorBrightness: Brightness.dark,
            fontFamily: FontsFamily.sourceSansPro),
        debugShowCheckedModeBanner: true,
        navigatorKey: NavigationService.navigationKey,
        onGenerateRoute: router.generateRoute,
        home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (BuildContext context, AuthenticationState state) {
          if (state is AuthenticationAuthenticated) {
            // show home page
            return EventListPage();
          } else if (state is AuthenticationLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            // otherwise show login page
            return LoginScreen();
          }
        }),
        // home: MyHomePage(),
      ),
    );
  }
}
