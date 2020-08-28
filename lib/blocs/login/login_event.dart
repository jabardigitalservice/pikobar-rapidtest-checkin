part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String username;
  final String password;

  LoginSubmitted({@required this.username, @required this.password});

  @override
  List<Object> get props => [username, password];
}
