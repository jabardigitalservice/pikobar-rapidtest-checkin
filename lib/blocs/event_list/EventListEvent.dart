import 'package:equatable/equatable.dart';

abstract class EventListEvent extends Equatable {
  const EventListEvent([List props = const <dynamic>[]]);
}

class EventListLoad extends EventListEvent {
  final int page;
  final bool isFirstLoad;
  final String keyword;
  const EventListLoad({this.page, this.isFirstLoad = false, this.keyword});

  @override
  String toString() {
    return 'Event EventListLoad';
  }

  @override
  List<Object> get props => [page, isFirstLoad, keyword];
}

class EventListLoadMore extends EventListEvent {
  final int page;
  final bool isFirstLoad;
  final String keyword;

  const EventListLoadMore({this.page, this.isFirstLoad = false, this.keyword});

  @override
  String toString() {
    return 'Event EventListLoadMore';
  }

  @override
  List<Object> get props => [page, isFirstLoad, keyword];
}

class EventListSearch extends EventListEvent {
  final String eventCode, keyword;
  final int page;

  const EventListSearch({this.eventCode, this.keyword, this.page});

  @override
  String toString() {
    return 'Event EventListSearch';
  }

  @override
  List<Object> get props => [eventCode, keyword, page];
}
