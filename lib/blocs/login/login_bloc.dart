import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/blocs/authentication/authentication_bloc.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/authentication_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthenticationBloc _authenticationBloc;
  final AuthenticationRepository _authenticationRepository;
  final KegiatanDetailRepository kegiatanDetailrepository;

  LoginBloc(
      AuthenticationBloc authenticationBloc,
      AuthenticationRepository authenticationRepository,
      this.kegiatanDetailrepository)
      : assert(authenticationBloc != null),
        assert(authenticationRepository != null),
        _authenticationBloc = authenticationBloc,
        _authenticationRepository = authenticationRepository;

  @override
  LoginState get initialState => LoginInitial();

  @override
  Stream<LoginState> mapEventToState(
    LoginEvent event,
  ) async* {
    if (event is LoginSubmitted) {
      yield* _mapLoginSubmitted(event);
    }
  }

  Stream<LoginState> _mapLoginSubmitted(LoginSubmitted event) async* {
    yield LoginLoading();
    try {
      await _authenticationRepository.clearActivityCode();
      await kegiatanDetailrepository.setIsFromLogin(true);
      await kegiatanDetailrepository.setLocation(event.location);
      final token = await _authenticationRepository.loginUser(
          event.username, event.password);
      if (token != null) {
        // bool isGranted = await _authenticationRepository.isAccessGranted();
        // if (isGranted) {
        // push new authentication event
        _authenticationBloc.add(UserLoggedIn(accessToken: token.accessToken));

        yield LoginSuccess();
        yield LoginInitial();
        // } else {
        //   await _authenticationRepository.clearActivityCode();
        //   await _authenticationRepository.deleteTokens();
        //   await _authenticationRepository.clearIsFromLogin();
        //   yield LoginFailure(
        //       error:
        //           'Hak akses ditolak, silahkan hubungi admin untuk meminta hak akses');
        // }
      } else {
        yield LoginFailure(error: 'Something very weird just happened');
      }
    } catch (err) {
      yield LoginFailure(error: err.toString());
    }
  }
}
