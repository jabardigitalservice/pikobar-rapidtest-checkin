import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'Bloc.dart';

class SendCheckinDataBloc
    extends Bloc<SendCheckinDataEvent, SendCheckinDataState> {
  final OfflineRepository repository;
  SendCheckinDataBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  SendCheckinDataState get initialState => InitialSendCheckinDataState();
  List<Map<String, dynamic>> startData;
  List<Map<String, dynamic>> endData;
  @override
  Stream<SendCheckinDataState> mapEventToState(
    SendCheckinDataEvent event,
  ) async* {
    if (event is SendCheckinData) {
      yield SendCheckinDataLoading();
      try {
        startData = await repository.select();
        await repository.checkin(startData);
        endData = await repository.select();

        yield SendCheckinDataSuccess(
            message:
                'Data berhasil terkirim ${startData.length - endData.length}/${startData.length}');
      } catch (e) {
        List<Map<String, dynamic>> endDataError = await repository.select();
        print(e.toString());
        yield SendCheckinDataFailure(
            error:
                'Data berhasil terkirim ${startData.length - endDataError.length}/${startData.length}');
      }
    }
  }
}
