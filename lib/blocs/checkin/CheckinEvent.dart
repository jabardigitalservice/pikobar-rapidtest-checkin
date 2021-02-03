import 'package:equatable/equatable.dart';

abstract class CheckinEvent extends Equatable {
  const CheckinEvent([List props = const <dynamic>[]]);
}

class CheckinLoad extends CheckinEvent {
  final String nomorPendaftaran,eventCode,labCodeSample;
  const CheckinLoad({this.nomorPendaftaran,this.eventCode,this.labCodeSample});

  @override
  String toString() {
    return 'Event CheckinLoad';
  }

  @override
  List<Object> get props => [nomorPendaftaran,eventCode];
}

class GetNameLoad extends CheckinEvent {
  final String registrationCode, labCode, eventCode;
  const GetNameLoad({this.registrationCode, this.labCode, this.eventCode});

  @override
  String toString() {
    return 'Event CheckinLoad';
  }

  @override
  List<Object> get props => [registrationCode, labCode, eventCode];
}