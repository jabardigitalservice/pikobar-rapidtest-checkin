import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/model/EventListModel.dart';
import 'package:rapid_test/repositories/EventListRepository.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'Bloc.dart';

class EventListBloc extends Bloc<EventListEvent, EventListState> {
  final EventListRepository repository;
  EventListBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  EventListState get initialState => InitialEventListState();

  @override
  Stream<EventListState> mapEventToState(
    EventListEvent event,
  ) async* {
    EventListModel eventListModel;
    if (event is EventListLoad) {
      yield EventListLoading();
      try {
        eventListModel = await repository.getListOfEvent(event.page);

        int maxDatalength = await Preferences.getDataInt(kTotalCount);
        yield EventListLoaded(
            eventListModel: eventListModel.data, maxData: maxDatalength);
      } catch (e) {
        yield EventListFailure(error: e.toString());
      }
    }
    if (event is EventListLoadMore) {
      try {
        EventListLoaded eventListLoaded = state as EventListLoaded;
        eventListModel = await repository.getListOfEvent(event.page);
        int maxDatalength = await Preferences.getDataInt(kTotalCount);
        yield EventListLoaded(
            eventListModel:
                eventListLoaded.eventListModel + eventListModel.data,
            maxData: maxDatalength);
      } catch (e) {
        yield EventListFailure(error: e.toString());
      }
    }
  }
}
