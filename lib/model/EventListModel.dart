class EventListModel {
  List<ListEvent> data;
  Links links;
  Meta meta;

  EventListModel({this.data, this.links, this.meta});

  EventListModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = new List<ListEvent>();
      json['data'].forEach((v) {
        data.add(new ListEvent.fromJson(v));
      });
    }
    links = json['links'] != null ? new Links.fromJson(json['links']) : null;
    meta = json['meta'] != null ? new Meta.fromJson(json['meta']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data.map((v) => v.toJson()).toList();
    }
    if (this.links != null) {
      data['links'] = this.links.toJson();
    }
    if (this.meta != null) {
      data['meta'] = this.meta.toJson();
    }
    return data;
  }
}

class ListEvent {
  String eventName;
  String eventLocation;
  String eventRegUrl;
  String hostName;
  String startAt;
  String endAt;
  String status;
  City city;
  int invitationsCount;
  int schedulesCount;
  int id;
  String eventCode;
  String createdAt;
  String updatedAt;

  ListEvent(
      {this.eventName,
      this.eventLocation,
      this.eventRegUrl,
      this.hostName,
      this.startAt,
      this.endAt,
      this.status,
      this.city,
      this.invitationsCount,
      this.schedulesCount,
      this.id,
      this.eventCode,
      this.createdAt,
      this.updatedAt});

  ListEvent.fromJson(Map<String, dynamic> json) {
    eventName = json['event_name'];
    eventLocation = json['event_location'];
    eventRegUrl = json['event_reg_url'];
    hostName = json['host_name'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    status = json['status'];
    city = json['city'] != null ? new City.fromJson(json['city']) : null;
    invitationsCount = json['invitations_count'];
    schedulesCount = json['schedules_count'];
    id = json['id'];
    eventCode = json['event_code'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['event_name'] = this.eventName;
    data['event_location'] = this.eventLocation;
    data['event_reg_url'] = this.eventRegUrl;
    data['host_name'] = this.hostName;
    data['start_at'] = this.startAt;
    data['end_at'] = this.endAt;
    data['status'] = this.status;
    if (this.city != null) {
      data['city'] = this.city.toJson();
    }
    data['invitations_count'] = this.invitationsCount;
    data['schedules_count'] = this.schedulesCount;
    data['id'] = this.id;
    data['event_code'] = this.eventCode;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class City {
  String name;
  String code;

  City({this.name, this.code});

  City.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['code'] = this.code;
    return data;
  }
}

class Links {
  String first;
  String last;
  String prev;
  String next;

  Links({this.first, this.last, this.prev, this.next});

  Links.fromJson(Map<String, dynamic> json) {
    first = json['first'];
    last = json['last'];
    prev = json['prev'];
    next = json['next'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['first'] = this.first;
    data['last'] = this.last;
    data['prev'] = this.prev;
    data['next'] = this.next;
    return data;
  }
}

class Meta {
  int currentPage;
  int from;
  int lastPage;
  String path;
  int perPage;
  int to;
  int total;

  Meta(
      {this.currentPage,
      this.from,
      this.lastPage,
      this.path,
      this.perPage,
      this.to,
      this.total});

  Meta.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    from = json['from'];
    lastPage = json['last_page'];
    path = json['path'];
    perPage = json['per_page'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_page'] = this.currentPage;
    data['from'] = this.from;
    data['last_page'] = this.lastPage;
    data['path'] = this.path;
    data['per_page'] = this.perPage;
    data['to'] = this.to;
    data['total'] = this.total;
    return data;
  }
}