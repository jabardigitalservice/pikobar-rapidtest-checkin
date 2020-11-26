import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class CheckinOfflineState extends Equatable {
  const CheckinOfflineState([List props = const <dynamic>[]]);
}

class InitialCheckinOfflineState extends CheckinOfflineState {
  @override
  List<Object> get props => [];
}

class CheckinOfflineLoading extends CheckinOfflineState {
  @override
  String toString() {
    return 'State CheckinOfflineLoading';
  }

  @override
  List<Object> get props => [];
}

class CheckinOfflineLoaded extends CheckinOfflineState {
  

  @override
  String toString() {
    return 'State CheckinOfflineLoaded';
  }

  @override
  List<Object> get props => [];
}

class GetNameLoaded extends CheckinOfflineState {
  final String name,registrationCode, labCode, eventCode;

  GetNameLoaded({this.name,this.registrationCode,this.labCode,this.eventCode}) : super([name]);

  @override
  String toString() {
    return 'State CheckinOfflineLoaded';
  }

  @override
  List<Object> get props => [name,registrationCode,labCode,eventCode];
}


class  CheckinOfflineFailure extends  CheckinOfflineState {
  final String error;

   CheckinOfflineFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' CheckinOffline { error: $error }';

  @override
  List<Object> get props => [error];
}


