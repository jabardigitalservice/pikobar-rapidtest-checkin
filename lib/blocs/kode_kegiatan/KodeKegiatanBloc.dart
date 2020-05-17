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
      yield KodeKegiatanLoading();

      try {
        String isLogin = await repository.getActivityCode();
        if (isLogin != null) {
          
          yield KodeKegiatanLoaded(kodeKegiatanPref: isLogin);
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
        String isLogin = await repository.getActivityCode();
        yield KodeKegiatanLoaded(
            kodeKegiatan: kodeKegiatanModel, kodeKegiatanPref: isLogin);
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }
  }
}
