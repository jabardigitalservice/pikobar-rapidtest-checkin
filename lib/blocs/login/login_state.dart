part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState([List props = const <dynamic>[]]);

  @override
  List<Object> get props => <Object>[];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure({@required this.error});

  @override
  List<Object> get props => <Object>[error];
}
