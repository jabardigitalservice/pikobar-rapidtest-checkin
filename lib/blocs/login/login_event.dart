part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class  LoginSubmitted extends LoginEvent {
  final String username;
  final String password;
  final String location;

  LoginSubmitted({@required this.username, @required this.password,@required this.location});

  @override
  List<Object> get props => [username, password,location];
}
