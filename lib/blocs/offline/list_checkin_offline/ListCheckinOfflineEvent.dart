import 'package:equatable/equatable.dart';

abstract class ListCheckinOfflineEvent extends Equatable {
  const ListCheckinOfflineEvent([List props = const <dynamic>[]]);
}

class ListCheckinOfflineLoad extends ListCheckinOfflineEvent {
 

  @override
  String toString() {
    return 'Event ListCheckinOfflineLoad';
  }

  @override
  List<Object> get props => [];
}
