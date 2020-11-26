import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'Bloc.dart';

class EventCodeBloc extends Bloc<EventCodeEvent, EventCodeState> {
  final OfflineRepository repository;
  EventCodeBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  EventCodeState get initialState => InitialEventCodeState();

  @override
  Stream<EventCodeState> mapEventToState(
    EventCodeEvent event,
  ) async* {
    // if (event is AppStart) {
    //   yield EventCodeLoading();

    //   try {
    //     String isLogin = await repository.getActivityCode();
    //     String location = await repository.getLocation();
    //     if (isLogin != null) {
    //       yield EventCodeLoaded(
    //           location: location);
    //     } else {
    //       yield EventCodeUnauthenticated();
    //     }
    //   } catch (e) {
    //     yield EventCodeFailure(error: e.toString());
    //   }
    // }

    // if (event is Logout) {
    //   yield EventCodeLoading();

    //   try {
    //     await repository.clearActivityCode();
    //     yield EventCodeUnauthenticated();
    //   } catch (e) {
    //     yield EventCodeFailure(error: e.toString());
    //   }
    // }

    if (event is EventCodeLoad) {
      yield EventCodeLoading();

      try {
        int _page = 1;
        if (event.isFromLogin != null) {
          await repository.setIsFromLogin(event.isFromLogin);
        }
        await repository.setActivityCode(event.eventCode);
        await repository.setLocation(event.location);
        String location = await repository.getLocation();
        String activityCode = await repository.getActivityCode();
        List<Map<String, dynamic>> checkData =
            await repository.selectParticipant();
        print("jumlah data " + checkData.length.toString());
        if (checkData.length != 0) {
          await repository.deleteTableParticipant();
        }
        ListParticipantModel tempData = await repository.getListOfParticipant(
            activityCode, _page.toString());
        if (tempData.meta.lastPage > 1) {
          for (var i = 1; i < tempData.meta.lastPage; i++) {
            _page++;
            await repository.getListOfParticipant(
                activityCode, _page.toString());
            print(_page);
          }
        }
        yield EventCodeLoaded(eventCode: activityCode, location: location);
      } catch (e) {
        yield EventCodeFailure(error: e.toString());
      }
    }
  }
}
