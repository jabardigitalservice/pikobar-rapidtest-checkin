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
        CheckinModel checkinModel = await repository.checkNomorPendaftaran(
            event.nomorPendaftaran, event.eventCode);

        yield CheckinLoaded(checkinModel: checkinModel);
      } catch (e) {
        yield CheckinFailure(error: e.toString());
      }
    }
  }
}
