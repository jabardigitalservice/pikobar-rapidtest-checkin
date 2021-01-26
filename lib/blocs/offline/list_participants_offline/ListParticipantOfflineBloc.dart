import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'Bloc.dart';

class ListParticipantOfflineBloc
    extends Bloc<ListParticipantOfflineEvent, ListParticipantOfflineState> {
  final OfflineRepository repository;
  ListParticipantOfflineBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  ListParticipantOfflineState get initialState =>
      InitialListParticipantOfflineState();

  @override
  Stream<ListParticipantOfflineState> mapEventToState(
    ListParticipantOfflineEvent event,
  ) async* {
    if (event is ListParticipantOfflineLoad) {
      yield ListParticipantOfflineLoading();
      try {
        List<ListParticipantOfflineModel> getList =
            await repository.getParticipant();
        yield ListParticipantOfflineLoaded(
            listParticipantOfflineModel: getList);
      } catch (e) {
        yield ListParticipantOfflineFailure(error: e.toString());
      }
    }

    if (event is ListParticipantSearchOffline) {
      yield ListParticipantOfflineLoading();
      try {
        List<ListParticipantOfflineModel> getList =
            await repository.getParticipant();
        var getSearch = getList
            .where((element) =>
                element.name.toString().toLowerCase().contains(event.keyword))
            .toList();
        yield ListParticipantOfflineLoaded(
            listParticipantOfflineModel: getSearch);
      } catch (e) {
        yield ListParticipantOfflineFailure(error: e.toString());
      }
    }
  }
}
