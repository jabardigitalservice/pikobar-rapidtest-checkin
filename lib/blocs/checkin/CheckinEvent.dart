import 'package:equatable/equatable.dart';

abstract class CheckinEvent extends Equatable {
  const CheckinEvent([List props = const <dynamic>[]]);
}

class CheckinLoad extends CheckinEvent {
  final String nomorPendaftaran,eventCode;
  CheckinLoad({this.nomorPendaftaran,this.eventCode});

  @override
  String toString() {
    return 'Event CheckinLoad';
  }

  @override
  List<Object> get props => [nomorPendaftaran,eventCode];
}
