import 'package:equatable/equatable.dart';

abstract class EventCodeEvent extends Equatable {
  const EventCodeEvent([List props = const <dynamic>[]]);
}

class EventCodeLoad extends EventCodeEvent {
  final String eventCode, location;
  final bool isFromLogin;
  EventCodeLoad({this.eventCode, this.location, this.isFromLogin = false});

  @override
  String toString() {
    return 'Event EventCodeLoad';
  }

  @override
  List<Object> get props => [];
}

class AppStart extends EventCodeEvent {
  @override
  String toString() {
    return 'Event EventCodeLoad';
  }

  @override
  List<Object> get props => [];
}

class Logout extends EventCodeEvent {
  @override
  String toString() {
    return 'Event Logout';
  }

  @override
  List<Object> get props => [];
}
