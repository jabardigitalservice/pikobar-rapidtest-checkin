// To parse this JSON data, do
//

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

class UserModel {
  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.permissions,
  });

  String id;
  String name;
  String email;
  String role;
  List<String> permissions;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        role: json["role"],
        permissions: List<String>.from(json["permissions"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "role": role,
        "permissions": List<dynamic>.from(permissions.map((x) => x)),
      };
}
