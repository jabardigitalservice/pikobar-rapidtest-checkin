import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class SendCheckinDataState extends Equatable {
  const SendCheckinDataState([List props = const <dynamic>[]]);
}

class InitialSendCheckinDataState extends SendCheckinDataState {
  @override
  List<Object> get props => <Object>[];
}

class SendCheckinDataLoading extends SendCheckinDataState {
  @override
  String toString() {
    return 'State SendCheckinDataLoading';
  }

  @override
  List<Object> get props => <Object>[];
}

class SendCheckinDataSuccess extends SendCheckinDataState {
  final String message;
  SendCheckinDataSuccess({this.message});

  @override
  String toString() {
    return 'State SendCheckinDataSuccess';
  }

  @override
  List<Object> get props => <Object>[message];
}

class SendCheckinDataFailure extends SendCheckinDataState {
  final String error;

  SendCheckinDataFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' SendCheckinData { error: $error }';

  @override
  List<Object> get props => <Object>[error];
}
