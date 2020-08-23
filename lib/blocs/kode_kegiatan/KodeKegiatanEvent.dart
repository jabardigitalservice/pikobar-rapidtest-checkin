import 'package:equatable/equatable.dart';

abstract class KodeKegiatanEvent extends Equatable {
  const KodeKegiatanEvent([List props = const <dynamic>[]]);
}

class KodeKegiatanLoad extends KodeKegiatanEvent {
  final String kodeKegiatan, location;
  KodeKegiatanLoad({this.kodeKegiatan, this.location});

  @override
  String toString() {
    return 'Event KodeKegiatanLoad';
  }

  @override
  List<Object> get props => [];
}

class AppStart extends KodeKegiatanEvent {
  @override
  String toString() {
    return 'Event KodeKegiatanLoad';
  }

  @override
  List<Object> get props => [];
}

class Logout extends KodeKegiatanEvent {
  @override
  String toString() {
    return 'Event Logout';
  }

  @override
  List<Object> get props => [];
}
