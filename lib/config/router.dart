import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rapid_test/constants/route_paths.dart' as routes;
import 'package:rapid_test/screen/login_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case routes.kLoginRoute:
      return MaterialPageRoute(builder: (context) => LoginScreen());
    default:
      return MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Text('No path for ${settings.name}'),
          ),
        ),
      );
  }
}
