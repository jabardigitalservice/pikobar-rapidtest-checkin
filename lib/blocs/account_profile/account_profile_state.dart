part of 'account_profile_bloc.dart';

abstract class AccountProfileState extends Equatable {
  const AccountProfileState();

  @override
  List<Object> get props => [];
}

class AccountProfileInitial extends AccountProfileState {}

class AccountProfileLoading extends AccountProfileState {}

class AccountProfileLoaded extends AccountProfileState {
  final UserModel user;

  const AccountProfileLoaded({@required this.user});

  @override
  List<Object> get props => [user];
}

class AccountProfileFailure extends AccountProfileState {
  final String message;

  const AccountProfileFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
