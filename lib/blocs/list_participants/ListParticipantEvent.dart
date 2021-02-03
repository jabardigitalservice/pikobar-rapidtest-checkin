import 'package:equatable/equatable.dart';

abstract class ListParticipantEvent extends Equatable {
  const ListParticipantEvent([List props = const <dynamic>[]]);
}

class ListParticipantLoad extends ListParticipantEvent {
  final String eventCode, keyword;
  final int page;
  final bool isFirstLoad;

  const ListParticipantLoad(
      {this.eventCode, this.keyword, this.page, this.isFirstLoad = false});

  @override
  String toString() {
    return 'Event ListParticipantLoad';
  }

  @override
  List<Object> get props => [eventCode, keyword, page, isFirstLoad];
}

class ListParticipantLoadMore extends ListParticipantEvent {
  final String eventCode, keyword;
  final int page;
  final bool isFirstLoad;

  const ListParticipantLoadMore(
      {this.eventCode, this.keyword, this.page, this.isFirstLoad = false});

  @override
  String toString() {
    return 'Event ListParticipantLoadMore';
  }

  @override
  List<Object> get props => [eventCode, keyword, page, isFirstLoad];
}

class ListParticipantSearch extends ListParticipantEvent {
  final String eventCode, keyword;
  final int page;

  const ListParticipantSearch({this.eventCode, this.keyword, this.page});

  @override
  String toString() {
    return 'Event ListParticipantSearch';
  }

  @override
  List<Object> get props => [eventCode, keyword, page];
}
