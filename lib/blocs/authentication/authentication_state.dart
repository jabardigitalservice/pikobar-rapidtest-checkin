part of 'authentication_bloc.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];
}

class AuthenticationInitial extends AuthenticationState {}

class AuthenticationLoading extends AuthenticationState {}

class AuthenticationNotAuthenticated extends AuthenticationState {}

class AuthenticationAuthenticated extends AuthenticationState {
  final accessToken;

  const AuthenticationAuthenticated({@required this.accessToken});

  @override
  List<Object> get props => [accessToken];
}

class AuthenticationFailure extends AuthenticationState {
  final String message;

  const AuthenticationFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
