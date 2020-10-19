// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

class UserModel {
  UserModel({
    this.id,
    this.name,
    this.email,
    this.provinceCode,
    this.province,
    this.cityCode,
    this.city,
    this.role,
    this.permissions,
  });

  String id;
  String name;
  String email;
  dynamic provinceCode;
  dynamic province;
  dynamic cityCode;
  dynamic city;
  String role;
  List<String> permissions;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        provinceCode: json["province_code"],
        province: json["province"],
        cityCode: json["city_code"],
        city: json["city"],
        role: json["role"],
        permissions: List<String>.from(json["permissions"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "province_code": provinceCode,
        "province": province,
        "city_code": cityCode,
        "city": city,
        "role": role,
        "permissions": List<dynamic>.from(permissions.map((x) => x)),
      };
}
