import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/EventListModel.dart';

abstract class EventListState extends Equatable {
  const EventListState([List props = const <dynamic>[]]);
}

class InitialEventListState extends EventListState {
  @override
  List<Object> get props => [];
}

class EventListLoading extends EventListState {
  @override
  String toString() {
    return 'State EventListLoading';
  }

  @override
  List<Object> get props => [];
}

class EventListLoaded extends EventListState {
 final List<ListEvent> eventListModel;
 final int maxData;

  EventListLoaded({
    this.eventListModel,
    this.maxData,
  }) : super([eventListModel]);



  @override
  String toString() {
    return 'State EventListLoaded';
  }

  @override
  List<Object> get props => [eventListModel];
}

class EventListFailure extends EventListState {
  final String error;

  EventListFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' EventList { error: $error }';

  @override
  List<Object> get props => [error];
}