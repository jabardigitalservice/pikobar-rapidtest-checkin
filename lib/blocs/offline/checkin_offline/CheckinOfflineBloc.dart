import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'Bloc.dart';

class CheckinOfflineBloc
    extends Bloc<CheckinOfflineEvent, CheckinOfflineState> {
  final OfflineRepository repository;
  CheckinOfflineBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  CheckinOfflineState get initialState => InitialCheckinOfflineState();

  @override
  Stream<CheckinOfflineState> mapEventToState(
    CheckinOfflineEvent event,
  ) async* {
    if (event is CheckinOfflineLoad) {
      yield CheckinOfflineLoading();
      try {
        String location = await Preferences.getDataString('location');
        String eventCode = await Preferences.getDataString('activityCode');
        List<ListParticipantOfflineModel> getList =
            await repository.getParticipant();
        final data = CheckinOfflineModel(
            eventCode: eventCode,
            labCodeSample: event.labCodeSample,
            location: location,
            createdAt: DateTime.now().toString(),
            registrationCode: event.nomorPendaftaran);
        await repository.insert(data);
        var getData = getList
            .where(
                (element) => element.registrationCode == event.nomorPendaftaran)
            .toList();

        await repository.updateListParticipant(ListParticipantOfflineModel(
            id: getData[0].id,
            attendedAt: DateTime.now().toString(),
            labCode: event.labCodeSample,
            name: getData[0].name,
            registrationCode: getData[0].registrationCode));
        yield CheckinOfflineLoaded();
      } catch (e) {
        yield CheckinOfflineFailure(error: e.toString());
      }
    }
    if (event is GetNameLoad) {
      yield CheckinOfflineLoading();
      try {
        List<ListParticipantOfflineModel> getList =
            await repository.getParticipant();
        String eventCode = await Preferences.getDataString('activityCode');
        var getName = getList
            .where(
                (element) => element.registrationCode == event.registrationCode)
            .toList();
        if (getName.isEmpty) {
          yield CheckinOfflineFailure(
              error: 'Kode registrasi tidak ditemukan dalam event ini');
        } else {
          if (getName[0].attendedAt != null) {
            yield CheckinOfflineFailure(
                error:
                    'Kode registrasi telah checkin pada ${unixTimeStampToDateTime(getName[0].attendedAt)}');
          } else {
            var getLabCode = getList
                .where((element) =>
                    element.labCode.toString().toLowerCase() ==
                    event.labCode.toString().toLowerCase())
                .toList();
            if (getLabCode.length == 0) {
              yield GetNameLoaded(
                  name: getName[0].name,
                  registrationCode: event.registrationCode,
                  eventCode: eventCode,
                  labCode: event.labCode);
            } else {
              yield CheckinOfflineFailure(
                  error: 'Kode lab telah digunakan oleh ${getLabCode[0].name}');
            }
          }
        }
      } catch (e) {
        yield CheckinOfflineFailure(error: e.toString());
      }
    }
  }
}
