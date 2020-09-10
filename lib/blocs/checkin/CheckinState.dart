import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinModel.dart';

abstract class CheckinState extends Equatable {
  const CheckinState([List props = const <dynamic>[]]);
}

class InitialCheckinState extends CheckinState {
  @override
  List<Object> get props => [];
}

class CheckinLoading extends CheckinState {
  @override
  String toString() {
    return 'State CheckinLoading';
  }

  @override
  List<Object> get props => [];
}

class CheckinLoaded extends CheckinState {
  final CheckinModel checkinModel;

  CheckinLoaded({this.checkinModel}) : super([checkinModel]);

  @override
  String toString() {
    return 'State CheckinLoaded';
  }

  @override
  List<Object> get props => [checkinModel];
}

class GetNameLoaded extends CheckinState {
  final String name,registrationCode, labCode, eventCode;

  GetNameLoaded({this.name,this.registrationCode,this.labCode,this.eventCode}) : super([name]);

  @override
  String toString() {
    return 'State CheckinLoaded';
  }

  @override
  List<Object> get props => [name,registrationCode,labCode,eventCode];
}

class  CheckinFailure extends  CheckinState {
  final String error;

   CheckinFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' Checkin { error: $error }';

  @override
  List<Object> get props => [error];
}


