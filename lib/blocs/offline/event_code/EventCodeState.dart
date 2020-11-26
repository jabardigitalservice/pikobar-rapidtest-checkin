import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class EventCodeState extends Equatable {
  const EventCodeState([List props = const <dynamic>[]]);
}

class InitialEventCodeState extends EventCodeState {
  @override
  List<Object> get props => [];
}

class EventCodeLoading extends EventCodeState {
  @override
  String toString() {
    return 'State EventCodeLoading';
  }

  @override
  List<Object> get props => [];
}

class EventCodeAuthenticated extends EventCodeState {
  @override
  String toString() {
    return 'State EventCodeAuthenticated';
  }

  @override
  List<Object> get props => [];
}

class EventCodeUnauthenticated extends EventCodeState {
  @override
  String toString() {
    return 'State EventCodeUnauthenticated';
  }

  @override
  List<Object> get props => [];
}

class EventCodeLoaded extends EventCodeState {
 
  final String eventCode;
  final String location;

  EventCodeLoaded({ this.eventCode, this.location})
      : super([ eventCode, location]);

  @override
  String toString() {
    return 'State EventCodeLoaded';
  }

  @override
  List<Object> get props => [eventCode, location];
}

class EventCodeFailure extends EventCodeState {
  final String error;

  EventCodeFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' EventCode { error: $error }';

  @override
  List<Object> get props => [error];
}
