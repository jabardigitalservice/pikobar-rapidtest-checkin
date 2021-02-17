import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
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
        final List<CheckinOfflineModel> data =
            await repository.getCheckinList();

        yield ListCheckinOfflineLoaded(checkinOfflineModel: data);
      } catch (e) {
        yield ListCheckinOfflineFailure(error: e.toString());
      }
    }
    if (event is ListCheckinOfflineDelete) {
      yield ListCheckinOfflineLoading();
      try {
        final List<ListParticipantOfflineModel> getList =
            await repository.getParticipant();

        /// update offline data
        final List<ListParticipantOfflineModel> getData = getList
            .where((element) =>
                element.registrationCode ==
                event.checkinOfflineModel.registrationCode)
            .toList();
        await repository.deleteCheckinData(event.checkinOfflineModel.id);
        await repository.updateListParticipant(ListParticipantOfflineModel(
            attendedAt: null,
            id: getData[0].id,
            labCode: null,
            name: getData[0].name,
            registrationCode: getData[0].registrationCode));

        yield ListCheckinOfflineDeleted();
      } catch (e) {
        yield ListCheckinOfflineFailure(error: e.toString());
      }
    }
  }
}
