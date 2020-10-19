part of 'account_profile_bloc.dart';

abstract class AccountProfileEvent extends Equatable {
  const AccountProfileEvent();

  @override
  List<Object> get props => [];
}

class AccountProfileLoad extends AccountProfileEvent {}
