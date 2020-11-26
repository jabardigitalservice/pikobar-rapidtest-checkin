import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import './Bloc.dart';

class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  final KegiatanDetailRepository repository;
  final OfflineRepository offlineRepository;

  CheckinBloc({@required this.repository, @required this.offlineRepository})
      : assert(repository != null);
  @override
  CheckinState get initialState => InitialCheckinState();

  @override
  Stream<CheckinState> mapEventToState(
    CheckinEvent event,
  ) async* {
    if (event is CheckinLoad) {
      yield CheckinLoading();

      if (await ConnectivityWrapper.instance.isConnected) {
        var checkinOfflineData = await offlineRepository.getCheckinList();
        if (checkinOfflineData.length != 0) {
          var getOfflineData = await offlineRepository.select();
          for (var i = 0; i < getOfflineData.length; i++) {
            await offlineRepository.checkin(
                getOfflineData[i]['registration_code'],
                getOfflineData[i]['event_code'],
                getOfflineData[i]['lab_code_sample'],
                getOfflineData[i]['location'],
                getOfflineData[i]['id']);
          }
        }
        try {
          String location = await repository.getLocation();
          CheckinModel checkinModel = await repository.checkNomorPendaftaran(
              event.nomorPendaftaran,
              event.eventCode,
              event.labCodeSample,
              location);
          List<ListParticipantOfflineModel> getList =
              await offlineRepository.getParticipant();
          var getData = getList
              .where((element) =>
                  element.registrationCode == event.nomorPendaftaran)
              .toList();
          await offlineRepository.updateListParticipant(
              ListParticipantOfflineModel(
                  id: getData[0].id,
                  attendedAt: DateTime.now().toString(),
                  labCode: event.labCodeSample,
                  name: getData[0].name,
                  registrationCode: getData[0].registrationCode));
          yield CheckinLoaded(
            name: checkinModel.data.name,
          );
        } catch (e) {
          yield CheckinFailure(error: e.toString());
        }
      } else {
        try {
          String location = await repository.getLocation();
          String eventCode = await repository.getActivityCode();
          List<ListParticipantOfflineModel> getList =
              await offlineRepository.getParticipant();
          final data = CheckinOfflineModel(
              eventCode: eventCode,
              labCodeSample: event.labCodeSample,
              location: location,
              createdAt: DateTime.now().toString(),
              registrationCode: event.nomorPendaftaran);
          await offlineRepository.insert(data);
          var getData = getList
              .where((element) =>
                  element.registrationCode == event.nomorPendaftaran)
              .toList();

          await offlineRepository.updateListParticipant(
              ListParticipantOfflineModel(
                  id: getData[0].id,
                  attendedAt: DateTime.now().toString(),
                  labCode: event.labCodeSample,
                  name: getData[0].name,
                  registrationCode: getData[0].registrationCode));
          yield CheckinLoaded(name: getData[0].name);
        } catch (e) {
          yield CheckinFailure(error: e.toString());
        }
      }
    }
    if (event is GetNameLoad) {
      yield CheckinLoading();
      try {
        if (await ConnectivityWrapper.instance.isConnected) {
          var getName = await repository.getName(event.registrationCode);
          yield GetNameLoaded(
              name: getName['data']['name'],
              registrationCode: event.registrationCode,
              eventCode: event.eventCode,
              labCode: event.labCode);
        } else {
          List<ListParticipantOfflineModel> getList =
              await offlineRepository.getParticipant();
          String eventCode = await repository.getActivityCode();
          var getName = getList
              .where((element) =>
                  element.registrationCode == event.registrationCode)
              .toList();
          if (getName.isEmpty) {
            yield CheckinFailure(
                error: 'Kode registrasi tidak ditemukan dalam event ini');
          } else {
            if (getName[0].attendedAt != null) {
              yield CheckinFailure(
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
                yield CheckinFailure(
                    error:
                        'Kode lab telah digunakan oleh ${getLabCode[0].name}');
              }
            }
          }
        }
      } catch (e) {
        yield CheckinFailure(error: e.toString());
      }
    }
  }
}
