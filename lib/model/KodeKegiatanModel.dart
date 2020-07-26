class KodeKegiatanModel {
  Data data;

  KodeKegiatanModel({this.data});

  KodeKegiatanModel.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data.toJson();
    }
    return data;
  }
}

class Data {
  int id;
  String eventCode;
  String eventName;
  String eventLocation;
  String startAt;
  String endAt;
  String status;
  String deletedAt;
  String createdAt;
  String updatedAt;
  List<Applicants> applicants;

  Data(
      {this.id,
      this.eventCode,
      this.eventName,
      this.eventLocation,
      this.startAt,
      this.endAt,
      this.status,
      this.deletedAt,
      this.createdAt,
      this.updatedAt,
      this.applicants});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    eventCode = json['event_code'];
    eventName = json['event_name'];
    eventLocation = json['event_location'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    status = json['status'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['invitations'] != null) {
      applicants = new List<Applicants>();
      json['invitations'].forEach((v) {
        applicants.add(new Applicants.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['event_code'] = this.eventCode;
    data['event_name'] = this.eventName;
    data['event_location'] = this.eventLocation;
    data['start_at'] = this.startAt;
    data['end_at'] = this.endAt;
    data['status'] = this.status;
    data['deleted_at'] = this.deletedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.applicants != null) {
      data['invitations'] = this.applicants.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Applicants {
  String registrationCode;
  String name;
  String qrcode;
  Event event;
  String approvedAt;
  String invitedAt;
  String attendedAt;
  String status;
  String createdAt;
  String updatedAt;

  Applicants(
      {this.registrationCode,
      this.name,
      this.qrcode,
      this.event,
      this.approvedAt,
      this.invitedAt,
      this.attendedAt,
      this.status,
      this.createdAt,
      this.updatedAt});

  Applicants.fromJson(Map<String, dynamic> json) {
    registrationCode = json['registration_code'];
    name = json['name'];
    qrcode = json['qrcode'];
    event = json['event'] != null ? new Event.fromJson(json['event']) : null;
    approvedAt = json['approved_at'];
    invitedAt = json['invited_at'];
    attendedAt = json['attended_at'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['registration_code'] = this.registrationCode;
    data['name'] = this.name;
    data['qrcode'] = this.qrcode;
    if (this.event != null) {
      data['event'] = this.event.toJson();
    }
    data['approved_at'] = this.approvedAt;
    data['invited_at'] = this.invitedAt;
    data['attended_at'] = this.attendedAt;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Event {
  int id;
  String eventCode;
  String eventName;
  String eventLocation;
  String startAt;
  String endAt;
  String status;
  String deletedAt;
  String createdAt;
  String updatedAt;

  Event(
      {this.id,
      this.eventCode,
      this.eventName,
      this.eventLocation,
      this.startAt,
      this.endAt,
      this.status,
      this.deletedAt,
      this.createdAt,
      this.updatedAt});

  Event.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    eventCode = json['event_code'];
    eventName = json['event_name'];
    eventLocation = json['event_location'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    status = json['status'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['event_code'] = this.eventCode;
    data['event_name'] = this.eventName;
    data['event_location'] = this.eventLocation;
    data['start_at'] = this.startAt;
    data['end_at'] = this.endAt;
    data['status'] = this.status;
    data['deleted_at'] = this.deletedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
