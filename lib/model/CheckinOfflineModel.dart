final String columnId = 'id';
final String columnEventCode = 'event_code';
final String columnRegistrationCode = 'registration_code';
final String columnLabCodeSample = 'lab_code_sample';
final String columnLocation = 'location';
final String columnCreatedAt = 'created_at';


class CheckinOfflineModel {
  int id;
  String eventCode;
  String registrationCode;
  String labCodeSample;
  String location;
  String createdAt;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnEventCode: eventCode,
      columnRegistrationCode: registrationCode,
      columnLabCodeSample: labCodeSample,
      columnLocation: location,
      columnCreatedAt:createdAt
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  CheckinOfflineModel(
      {this.id,
      this.eventCode,
      this.registrationCode,
      this.labCodeSample,
      this.location,this.createdAt});

  CheckinOfflineModel.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    eventCode = map[columnEventCode];
    registrationCode = map[columnRegistrationCode];
    labCodeSample = map[columnLabCodeSample];
    location = map[columnLocation];
    createdAt=map[columnCreatedAt];
  }
}