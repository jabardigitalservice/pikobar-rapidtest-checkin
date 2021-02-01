final String columnId = 'id';
final String columnRegistrationCode = 'registration_code';
final String columnName = 'name';
final String columnattendedAt = 'attended_at';
final String columnLabCodeSample = 'lab_code_sample';

class ListParticipantOfflineModel {
  int id;
  String name;
  String registrationCode;
  String attendedAt;
  String labCode;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
      columnRegistrationCode: registrationCode,
      columnattendedAt: attendedAt,
      columnLabCodeSample: labCode
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  ListParticipantOfflineModel(
      {this.id,
      this.name,
      this.registrationCode,
      this.attendedAt,
      this.labCode});

  ListParticipantOfflineModel.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
    registrationCode = map[columnRegistrationCode];
    attendedAt = map[columnattendedAt];
    labCode = map[columnLabCodeSample];
  }
}
