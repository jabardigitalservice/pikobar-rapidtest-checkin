import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';

abstract class KodeKegiatanState extends Equatable {
  const KodeKegiatanState([List props = const <dynamic>[]]);
}

class InitialKodeKegiatanState extends KodeKegiatanState {
  @override
  List<Object> get props => [];
}

class KodeKegiatanLoading extends KodeKegiatanState {
  @override
  String toString() {
    return 'State KodeKegiatanLoading';
  }

  @override
  List<Object> get props => [];
}

class KodeKegiatanLoaded extends KodeKegiatanState {
  final KodeKegiatanModel kodeKegiatan;

  KodeKegiatanLoaded({this.kodeKegiatan}) : super([kodeKegiatan]);

  @override
  String toString() {
    return 'State KodeKegiatanLoaded';
  }

  @override
  List<Object> get props => [kodeKegiatan];
}

class KodeKegiatanFailure extends KodeKegiatanState {
  final String error;

   KodeKegiatanFailure({@required this.error}) : super([error]);

  @override
  String toString() => ' KodeKegiatan { error: $error }';

  @override
  List<Object> get props => [error];
}
