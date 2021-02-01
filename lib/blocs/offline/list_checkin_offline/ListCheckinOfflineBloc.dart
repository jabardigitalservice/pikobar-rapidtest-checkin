import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'Bloc.dart';

class ListCheckinOfflineBloc
    extends Bloc<ListCheckinOfflineEvent, ListCheckinOfflineState> {
  final OfflineRepository repository;
  ListCheckinOfflineBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  ListCheckinOfflineState get initialState => InitialListCheckinOfflineState();

  @override
  Stream<ListCheckinOfflineState> mapEventToState(
    ListCheckinOfflineEvent event,
  ) async* {
    if (event is ListCheckinOfflineLoad) {
      yield ListCheckinOfflineLoading();
      try {
      var data = await repository.getCheckinList();

        yield ListCheckinOfflineLoaded(checkinOfflineModel:data );
      } catch (e) {
        yield ListCheckinOfflineFailure(error: e.toString());
      }
    }

  }
}
