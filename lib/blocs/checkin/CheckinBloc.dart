import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import './Bloc.dart';

class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  final KegiatanDetailRepository repository;
  CheckinBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  CheckinState get initialState => InitialCheckinState();

  @override
  Stream<CheckinState> mapEventToState(
    CheckinEvent event,
  ) async* {
    if (event is CheckinLoad) {
      yield CheckinLoading();
      try {
        String location = await repository.getLocation();

        CheckinModel checkinModel = await repository.checkNomorPendaftaran(
            event.nomorPendaftaran,
            event.eventCode,
            event.labCodeSample,
            location);

        yield CheckinLoaded(
          checkinModel: checkinModel,
        );
      } catch (e) {
        yield CheckinFailure(error: e.toString());
      }
    }
    if (event is GetNameLoad) {
      yield CheckinLoading();
      try {
        var getName = await repository.getName(event.registrationCode);
        yield GetNameLoaded(
            name: getName['data']['name'],
            registrationCode: event.registrationCode,
            eventCode: event.eventCode,
            labCode: event.labCode);
      } catch (e) {
        yield CheckinFailure(error: e.toString());
      }
    }
  }
}
