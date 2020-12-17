import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import 'package:rapid_test/repositories/OfflineRepository.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import './Bloc.dart';

class KodeKegiatanBloc extends Bloc<KodeKegiatanEvent, KodeKegiatanState> {
  final KegiatanDetailRepository repository;
  final OfflineRepository offlineRepository;

  KodeKegiatanBloc(
      {@required this.repository, @required this.offlineRepository})
      : assert(repository != null);
  @override
  KodeKegiatanState get initialState => InitialKodeKegiatanState();

  @override
  Stream<KodeKegiatanState> mapEventToState(
    KodeKegiatanEvent event,
  ) async* {
    if (event is AppStart) {
      yield KodeKegiatanLoading();

      try {
        String isLogin = await Preferences.getDataString('activityCode');
        String location = await Preferences.getDataString('location');
        if (isLogin != null) {
          yield KodeKegiatanSuccessMovePage(
              kodeKegiatanPref: isLogin, location: location);
        } else {
          yield KodeKegiatanUnauthenticated();
        }
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }

    if (event is Logout) {
      yield KodeKegiatanLoading();

      try {
        await Preferences.clearData('activityCode');
        yield KodeKegiatanUnauthenticated();
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }

    if (event is KodeKegiatanLoad) {
      yield KodeKegiatanLoading();

      try {
        int _page = 1;
        if (event.isFromLogin != null) {
          await Preferences.setDataBool('IsFromLogin', event.isFromLogin);
          if (event.location != null) {
            await Preferences.setDataString('location', event.location);
          }
        }
        String eventCode = await Preferences.getDataString('activityCode');
        KodeKegiatanModel kodeKegiatanModel =
            await repository.checkKodeKegiatan(eventCode);
        await Preferences.setDataString(
            'activityCode', kodeKegiatanModel.data.eventCode);
        List<Map<String, dynamic>> checkData =
            await offlineRepository.selectParticipant();
        print("jumlah data " + checkData.length.toString());
        if (checkData.length != 0) {
          await offlineRepository.deleteTableParticipant();
        }
        ListParticipantModel tempData = await offlineRepository
            .getListOfParticipant(eventCode, _page.toString());
        if (tempData.meta.lastPage > 1) {
          for (var i = 1; i < tempData.meta.lastPage; i++) {
            _page++;
            await offlineRepository.getListOfParticipant(
                eventCode, _page.toString());
            print(_page);
          }
        }

        String location = await Preferences.getDataString('location');
        String isLogin = await Preferences.getDataString('activityCode');
        yield KodeKegiatanLoaded(
            kodeKegiatan: kodeKegiatanModel,
            kodeKegiatanPref: isLogin,
            location: location);
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }

    if (event is KodeKegiatanMovePage) {
      yield KodeKegiatanLoading();

      try {
        if (event.isFromLogin != null) {
          await Preferences.setDataBool('IsFromLogin', event.isFromLogin);
          if (event.location != null) {
            await Preferences.setDataString('location', event.location);
          }
        }
        await Preferences.setDataString('activityCode', event.kodeKegiatan);
        yield KodeKegiatanSuccessMovePage();
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }
  }
}
