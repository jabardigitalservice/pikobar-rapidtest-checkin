import 'package:equatable/equatable.dart';

abstract class ListParticipantOfflineEvent extends Equatable {
  const ListParticipantOfflineEvent([List props = const <dynamic>[]]);
}

class ListParticipantOfflineLoad extends ListParticipantOfflineEvent {
  final String eventCode;

  ListParticipantOfflineLoad({this.eventCode});

  @override
  String toString() {
    return 'Event ListParticipantOfflineLoad';
  }

  @override
  List<Object> get props => [eventCode];
}

class ListParticipantSearchOffline extends ListParticipantOfflineEvent {
  final String keyword;

  ListParticipantSearchOffline({ this.keyword});

  @override
  String toString() {
    return 'Event ListParticipantSearch';
  }

  @override
  List<Object> get props => [ keyword];
}


