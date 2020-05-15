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
    if (event is KodeKegiatanLoad) {
      yield KodeKegiatanLoading();

      try {
        KodeKegiatanModel kodeKegiatanModel =
            await repository.checkKodeKegiatan(event.kodeKegiatan);

        yield KodeKegiatanLoaded(kodeKegiatan: kodeKegiatanModel);
      } catch (e) {
        yield KodeKegiatanFailure(error: e.toString());
      }
    }
  }
}
