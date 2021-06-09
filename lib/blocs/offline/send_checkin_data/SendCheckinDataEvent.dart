import 'package:equatable/equatable.dart';

abstract class SendCheckinDataEvent extends Equatable {
  const SendCheckinDataEvent([List props = const <dynamic>[]]);
}

class SendCheckinData extends SendCheckinDataEvent {
  @override
  String toString() {
    return 'Event SendCheckinData';
  }

  @override
  List<Object> get props => <Object>[];
}
