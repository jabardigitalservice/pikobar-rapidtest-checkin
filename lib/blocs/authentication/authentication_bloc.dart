import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/constants/storageKeys.dart';
import 'package:rapid_test/model/UserModel.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:rapid_test/utilities/secure_store.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository _authenticationRepository;

  AuthenticationBloc(AuthenticationRepository authenticationRepository)
      : assert(authenticationRepository != null),
        _authenticationRepository = authenticationRepository;

  @override
  AuthenticationState get initialState => AuthenticationInitial();

  @override
  Stream<AuthenticationState> mapEventToState(
    AuthenticationEvent event,
  ) async* {
    if (event is AppLoaded) {
      yield* _mapAppLoadedToState(event);
    }

    if (event is UserLoggedIn) {
      yield* _mapUserLoggedInToState(event);
    }

    if (event is UserLoggedOut) {
      yield* _mapUserLoggedOutToState(event);
    }
  }

  Stream<AuthenticationState> _mapAppLoadedToState(AppLoaded event) async* {
    yield AuthenticationLoading(); // to display splash screen
    try {
      // get access token
      String accessToken = await SecureStore().readValue(key: kAccessTokenKey);

      if (accessToken != null) {
        yield AuthenticationAuthenticated(accessToken: accessToken);
      } else {
        yield AuthenticationNotAuthenticated();
      }
    } catch (e) {
      yield AuthenticationFailure(
          message: e.message ?? 'An unknown error occurred');
    }
  }

  Stream<AuthenticationState> _mapUserLoggedInToState(
      UserLoggedIn event) async* {
    yield AuthenticationAuthenticated(accessToken: event.accessToken);
  }

  Stream<AuthenticationState> _mapUserLoggedOutToState(
      UserLoggedOut event) async* {
    await Preferences.clearData(kActivityCode);
    await _authenticationRepository.deleteTokens();
    await Preferences.clearData(kIsFromLogin);
    yield AuthenticationNotAuthenticated();
  }
}
