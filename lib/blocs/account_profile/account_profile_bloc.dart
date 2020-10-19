import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rapid_test/model/UserModel.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';

part 'account_profile_event.dart';
part 'account_profile_state.dart';

class AccountProfileBloc
    extends Bloc<AccountProfileEvent, AccountProfileState> {
  final AuthenticationRepository _authenticationRepository;

  AccountProfileBloc(AuthenticationRepository authenticationRepository)
      : assert(authenticationRepository != null),
        _authenticationRepository = authenticationRepository;

  @override
  AccountProfileState get initialState => AccountProfileInitial();

  @override
  Stream<AccountProfileState> mapEventToState(
    AccountProfileEvent event,
  ) async* {
    if (event is AccountProfileLoad) {
      yield* _mapAccountProfileLoadToState(event);
    }
  }

  Stream<AccountProfileState> _mapAccountProfileLoadToState(
      AccountProfileLoad event) async* {
    yield AccountProfileLoading();
    try {
      // get info user
      final UserModel user = await _authenticationRepository.userInfo();
      yield AccountProfileLoaded(user: user);
    } catch (e) {
      yield AccountProfileFailure(message: e.message);
    }
  }
}
