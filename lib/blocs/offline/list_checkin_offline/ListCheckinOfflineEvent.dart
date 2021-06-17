import 'package:equatable/equatable.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';

abstract class ListCheckinOfflineEvent extends Equatable {
  const ListCheckinOfflineEvent([List props = const <dynamic>[]]);
}

class ListCheckinOfflineLoad extends ListCheckinOfflineEvent {
  @override
  String toString() {
    return 'Event ListCheckinOfflineLoad';
  }

  @override
  List<Object> get props => <Object>[];
}

class ListCheckinOfflineDelete extends ListCheckinOfflineEvent {
  final CheckinOfflineModel checkinOfflineModel;
  const ListCheckinOfflineDelete(this.checkinOfflineModel);
  @override
  String toString() {
    return 'Event ListCheckinOfflineDelete';
  }

  @override
  List<Object> get props => <Object>[checkinOfflineModel];
}
