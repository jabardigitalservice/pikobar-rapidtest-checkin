import 'package:equatable/equatable.dart';

abstract class ListParticipantOfflineEvent extends Equatable {
  const ListParticipantOfflineEvent([List props = const <dynamic>[]]);
}

class ListParticipantOfflineLoad extends ListParticipantOfflineEvent {
  @override
  String toString() {
    return 'Event ListParticipantOfflineLoad';
  }

  @override
  List<Object> get props => [];
}

class ListParticipantSearchOffline extends ListParticipantOfflineEvent {
  final String keyword;

  const ListParticipantSearchOffline({this.keyword});

  @override
  String toString() {
    return 'Event ListParticipantSearch';
  }

  @override
  List<Object> get props => [keyword];
}
