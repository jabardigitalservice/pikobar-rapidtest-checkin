import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/constants/Dictionary.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/utilities/FormatDate.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
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

      /// Checking for connection status
      if (await ConnectivityWrapper.instance.isConnected) {
        /// ------ Online -------
        /// get offline data
        final List<CheckinOfflineModel> checkinOfflineData =
            await offlineRepository.getCheckinList();

        /// Checking offline data  not null
        if (checkinOfflineData.length != 0) {
          /// ------ Offline Data  Available ------
          /// get raw offline data
          final List<Map<String, dynamic>> getOfflineData =
              await offlineRepository.select();

          /// send offline data  to API
          await offlineRepository.checkin(getOfflineData);
        }
        try {
          /// get [location] form shared preference
          final String location = await Preferences.getDataString(kLocation);

          /// send data to API
          final CheckinModel checkinModel =
              await repository.checkNomorPendaftaran(event.nomorPendaftaran,
                  event.eventCode, event.labCodeSample, location);

          /// get offline data
          final List<ListParticipantOfflineModel> getList =
              await offlineRepository.getParticipant();

          /// update offline data
          final List<ListParticipantOfflineModel> getData = getList
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
        /// ------ Offline -------

        try {
          /// get [location] form shared preference
          final String location = await Preferences.getDataString(kLocation);

          /// get [eventCode] form shared preference
          final String eventCode =
              await Preferences.getDataString(kActivityCode);

          /// get offline data
          final List<ListParticipantOfflineModel> getList =
              await offlineRepository.getParticipant();
          final List<ListParticipantOfflineModel> getLabCode = getList
              .where((element) =>
                  element.labCode.toString().toLowerCase() ==
                  event.labCodeSample.toString().toLowerCase())
              .toList();
          if (getLabCode.length == 0) {
            /// save data to local storage
            final CheckinOfflineModel data = CheckinOfflineModel(
                eventCode: eventCode,
                labCodeSample: event.labCodeSample,
                location: location,
                createdAt: DateTime.now().add(Duration(hours: -7)).toString(),
                registrationCode: event.nomorPendaftaran);
            await offlineRepository.insert(data);

            /// update offline data
            final List<ListParticipantOfflineModel> getData = getList
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
          } else {
            yield CheckinFailure(
                error: Dictionary.labCodeAlreadyUsed + '${getLabCode[0].name}');
          }
        } catch (e) {
          yield CheckinFailure(error: e.toString());
        }
      }
    }
    if (event is GetNameLoad) {
      yield CheckinLoading();
      try {
        List<ListParticipantOfflineModel> getList =
            await offlineRepository.getParticipant();
        String eventCode = await Preferences.getDataString(kActivityCode);
        var getName = getList
            .where(
                (element) => element.registrationCode == event.registrationCode)
            .toList();
        if (getName.isEmpty) {
          yield CheckinFailure(error: Dictionary.numberRegistrationNotFound);
        } else {
          if (getName[0].attendedAt != null) {
            yield CheckinFailure(
                error: Dictionary.numberRegistrationAlreadyCheckin +
                    '${unixTimeStampToDateTime(getName[0].attendedAt)}');
          } else {
            if (await ConnectivityWrapper.instance.isConnected) {
              var getNameOnline =
                  await repository.getName(event.registrationCode);
              yield GetNameLoaded(
                  name: getNameOnline['data']['name'],
                  registrationCode: event.registrationCode,
                  eventCode: event.eventCode,
                  labCode: event.labCode);
            } else {
              yield GetNameLoaded(
                  name: getName[0].name,
                  registrationCode: event.registrationCode,
                  eventCode: eventCode,
                  labCode: event.labCode);
            }
          }
        }
      } catch (e) {
        yield CheckinFailure(error: e.toString());
      }
    }
  }
}
