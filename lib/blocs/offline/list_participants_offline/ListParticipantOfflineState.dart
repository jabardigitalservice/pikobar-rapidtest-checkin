import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';

abstract class ListParticipantOfflineState extends Equatable {
  const ListParticipantOfflineState([List props = const <dynamic>[]]);
}

class InitialListParticipantOfflineState extends ListParticipantOfflineState {
  @override
  List<Object> get props => <Object>[];
}

class ListParticipantOfflineLoading extends ListParticipantOfflineState {
  @override
  String toString() {
    return 'State ListParticipantOfflineLoading';
  }

  @override
  List<Object> get props => <Object>[];
}

class ListParticipantOfflineLoaded extends ListParticipantOfflineState {
  final List<ListParticipantOfflineModel> listParticipantOfflineModel;

  ListParticipantOfflineLoaded({
    this.listParticipantOfflineModel,
  }) : super([listParticipantOfflineModel]);

  @override
  String toString() {
    return 'State ListParticipantOfflineLoaded';
  }

  @override
  List<Object> get props => <Object>[listParticipantOfflineModel];
}

class ListParticipantOfflineFailure extends ListParticipantOfflineState {
  final String error;

  ListParticipantOfflineFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' ListParticipantOffline { error: $error }';

  @override
  List<Object> get props => <Object>[error];
}
