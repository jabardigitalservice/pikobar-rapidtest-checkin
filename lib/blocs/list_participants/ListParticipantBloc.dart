import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/repositories/ListParticipantRepository.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'Bloc.dart';

class ListParticipantBloc
    extends Bloc<ListParticipantEvent, ListParticipantState> {
  final ListParticipantRepository repository;
  ListParticipantBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  ListParticipantState get initialState => InitialListParticipantState();

  @override
  Stream<ListParticipantState> mapEventToState(
    ListParticipantEvent event,
  ) async* {
    ListParticipantModel listParticipantModel;
    if (event is ListParticipantLoad) {
      // if (event.page == 1 && event.isFirstLoad)
      yield ListParticipantLoading();
      try {
        listParticipantModel = await repository.getListOfParticipant(
            event.eventCode, event.keyword, event.page);

        int maxDatalength = await Preferences.getTotalCount();
        yield ListParticipantLoaded(
            listParticipantModel: listParticipantModel.data,
            maxData: maxDatalength);
      } catch (e) {
        yield ListParticipantFailure(error: e.toString());
      }
    }
    if (event is ListParticipantLoadMore) {
      try {
        ListParticipantLoaded listParticipantLoaded =
            state as ListParticipantLoaded;
        listParticipantModel = await repository.getListOfParticipant(
            event.eventCode, event.keyword, event.page);
        int maxDatalength = await Preferences.getTotalCount();
        yield ListParticipantLoaded(
            listParticipantModel: listParticipantLoaded.listParticipantModel +
                listParticipantModel.data,
            maxData: maxDatalength);
      } catch (e) {
        yield ListParticipantFailure(error: e.toString());
      }
    }
    
  }
}
