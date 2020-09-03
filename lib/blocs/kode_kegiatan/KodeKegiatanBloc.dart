import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/repositories/KegiatanDetailRepository.dart';
import './Bloc.dart';

class KodeKegiatanBloc extends Bloc<KodeKegiatanEvent, KodeKegiatanState> {
  final KegiatanDetailRepository repository;
  KodeKegiatanBloc({
    @required this.repository,
  }) : assert(repository != null);
  @override
  KodeKegiatanState get initialState => InitialKodeKegiatanState();

  @override
  Stream<KodeKegiatanState> mapEventToState(
    KodeKegiatanEvent event,
  ) async* {
    if (event is AppStart) {
      print('test test');
      yield KodeKegiatanLoading();

      try {
        String isLogin = await repository.getActivityCode();
        String location = await repository.getLocation();
        if (isLogin != null) {
          yield KodeKegiatanLoaded(
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
        await repository.clearActivityCode();
        await repository.clearLocation();
        yield KodeKegiatanUnauthenticated();
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }

    if (event is KodeKegiatanLoad) {
      yield KodeKegiatanLoading();

      try {
        KodeKegiatanModel kodeKegiatanModel =
            await repository.checkKodeKegiatan(event.kodeKegiatan);
        await repository.setActivityCode(kodeKegiatanModel.data.eventCode);
        if (event.location != null) {
          await repository.setLocation(event.location);
        }
        String location = await repository.getLocation();
        String isLogin = await repository.getActivityCode();
        yield KodeKegiatanLoaded(
            kodeKegiatan: kodeKegiatanModel,
            kodeKegiatanPref: isLogin,
            location: location);
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }
  }
}
