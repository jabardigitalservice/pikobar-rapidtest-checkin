import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';

abstract class ListCheckinOfflineState extends Equatable {
  const ListCheckinOfflineState([List props = const <dynamic>[]]);
}

class InitialListCheckinOfflineState extends ListCheckinOfflineState {
  @override
  List<Object> get props => [];
}

class ListCheckinOfflineLoading extends ListCheckinOfflineState {
  @override
  String toString() {
    return 'State ListCheckinOfflineLoading';
  }

  @override
  List<Object> get props => [];
}

class ListCheckinOfflineLoaded extends ListCheckinOfflineState {
  final List<CheckinOfflineModel> checkinOfflineModel;
  ListCheckinOfflineLoaded({this.checkinOfflineModel});

  @override
  String toString() {
    return 'State ListCheckinOfflineLoaded';
  }

  @override
  List<Object> get props => [checkinOfflineModel];
}




class  ListCheckinOfflineFailure extends  ListCheckinOfflineState {
  final String error;

   ListCheckinOfflineFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' ListCheckinOffline { error: $error }';

  @override
  List<Object> get props => [error];
}


