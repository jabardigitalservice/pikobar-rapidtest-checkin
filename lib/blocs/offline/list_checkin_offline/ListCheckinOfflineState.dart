import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';

abstract class ListCheckinOfflineState extends Equatable {
  const ListCheckinOfflineState([List props = const <dynamic>[]]);
}

class InitialListCheckinOfflineState extends ListCheckinOfflineState {
  @override
  List<Object> get props => <Object>[];
}

class ListCheckinOfflineLoading extends ListCheckinOfflineState {
  @override
  String toString() {
    return 'State ListCheckinOfflineLoading';
  }

  @override
  List<Object> get props => <Object>[];
}

class ListCheckinOfflineLoaded extends ListCheckinOfflineState {
  final List<CheckinOfflineModel> checkinOfflineModel;
  const ListCheckinOfflineLoaded({this.checkinOfflineModel});

  @override
  String toString() {
    return 'State ListCheckinOfflineLoaded';
  }

  @override
  List<Object> get props => <Object>[checkinOfflineModel];
}

class ListCheckinOfflineDeleted extends ListCheckinOfflineState {
  @override
  String toString() {
    return 'State ListCheckinOfflineDeleted';
  }

  @override
  List<Object> get props => <Object>[];
}

class ListCheckinOfflineFailure extends ListCheckinOfflineState {
  final String error;

  ListCheckinOfflineFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' ListCheckinOffline { error: $error }';

  @override
  List<Object> get props => <Object>[error];
}
