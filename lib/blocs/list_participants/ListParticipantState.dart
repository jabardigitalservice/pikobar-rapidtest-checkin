import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/blocs/list_participants/Bloc.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';

abstract class ListParticipantState extends Equatable {
  const ListParticipantState([List props = const <dynamic>[]]);
}

class InitialListParticipantState extends ListParticipantState {
  @override
  List<Object> get props => [];
}

class ListParticipantLoading extends ListParticipantState {
  @override
  String toString() {
    return 'State ListParticipantLoading';
  }

  @override
  List<Object> get props => [];
}

class ListParticipantLoaded extends ListParticipantState {
 final List<DataParticipant> listParticipantModel;
 final int maxData;

  ListParticipantLoaded({
    this.listParticipantModel,
    this.maxData,
  }) : super([listParticipantModel]);



  @override
  String toString() {
    return 'State ListParticipantLoaded';
  }

  @override
  List<Object> get props => [listParticipantModel];
}

class ListParticipantFailure extends ListParticipantState {
  final String error;

  ListParticipantFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' ListParticipant { error: $error }';

  @override
  List<Object> get props => [error];
}