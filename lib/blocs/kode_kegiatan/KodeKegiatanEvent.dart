import 'package:equatable/equatable.dart';

abstract class KodeKegiatanEvent extends Equatable {
  const KodeKegiatanEvent([List props = const <dynamic>[]]);
}

class KodeKegiatanLoad extends KodeKegiatanEvent {
  final String kodeKegiatan, location;
  final bool isFromLogin;
  KodeKegiatanLoad({this.kodeKegiatan, this.location, this.isFromLogin});

  @override
  String toString() {
    return 'Event KodeKegiatanLoad';
  }

  @override
  List<Object> get props => <Object>[];
}

class KodeKegiatanMovePage extends KodeKegiatanEvent {
  final String kodeKegiatan, location;
  final bool isFromLogin;
  KodeKegiatanMovePage({this.kodeKegiatan, this.location, this.isFromLogin});

  @override
  String toString() {
    return 'Event KodeKegiatanLoad';
  }

  @override
  List<Object> get props => <Object>[];
}

class AppStart extends KodeKegiatanEvent {
  @override
  String toString() {
    return 'Event KodeKegiatanLoad';
  }

  @override
  List<Object> get props => <Object>[];
}

class Logout extends KodeKegiatanEvent {
  @override
  String toString() {
    return 'Event Logout';
  }

  @override
  List<Object> get props => <Object>[];
}
