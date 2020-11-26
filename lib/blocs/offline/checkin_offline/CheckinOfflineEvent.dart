import 'package:equatable/equatable.dart';

abstract class CheckinOfflineEvent extends Equatable {
  const CheckinOfflineEvent([List props = const <dynamic>[]]);
}

class CheckinOfflineLoad extends CheckinOfflineEvent {
  final String nomorPendaftaran,eventCode,labCodeSample;
  CheckinOfflineLoad({this.nomorPendaftaran,this.eventCode,this.labCodeSample});

  @override
  String toString() {
    return 'Event CheckinOfflineLoad';
  }

  @override
  List<Object> get props => [nomorPendaftaran,eventCode];
}

class GetNameLoad extends CheckinOfflineEvent {
  final String registrationCode, labCode, eventCode;
  GetNameLoad({this.registrationCode, this.labCode, this.eventCode});

  @override
  String toString() {
    return 'Event CheckinOfflineLoad';
  }

  @override
  List<Object> get props => [registrationCode, labCode, eventCode];
}