import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

final String tableCheckin = 'test_masif';
final String tableListParticipant = 'test_masif_list_participant';
final String columnId = 'id';
final String columnEventCode = 'event_code';
final String columnRegistrationCode = 'registration_code';
final String columnLabCodeSample = 'lab_code_sample';
final String columnLocation = 'location';
final String columnCreatedAt = 'created_at';
final String columnName = 'name';
final String columnattendedAt = 'attended_at';

class OfflineRepository {
  Database db;

  Future open() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'test_masif.db';
    print(path);
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableCheckin ( 
  $columnId integer primary key autoincrement, 
  $columnEventCode text not null,
  $columnRegistrationCode text not null,
  $columnLabCodeSample text not null,
  $columnLocation text not null,
  $columnCreatedAt text not null)
''');
      await db.execute("DROP TABLE IF EXISTS $tableListParticipant");
      await db.execute('''
create table $tableListParticipant ( 
  $columnId integer primary key autoincrement, 
  $columnName text not null,
  $columnattendedAt text,
  $columnLabCodeSample text,
  $columnRegistrationCode text not null)
''');
    });
  }

  Future<CheckinOfflineModel> insert(CheckinOfflineModel todo) async {
    print(db);
    if (db == null) {
      await open();
    }
    todo.id = await db.insert(tableCheckin, todo.toMap());
    return todo;
  }

  Future<ListParticipantOfflineModel> insertParticipant(
      ListParticipantOfflineModel todo) async {
    print(db);
    if (db == null) {
      await open();
    }
    todo.id = await db.insert(tableListParticipant, todo.toMap());
    return todo;
  }

  Future<dynamic> getListOfParticipant(String kode, page) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      Response response = await dio.post(
          '${EndPointPath.baseUrl}/checkin/event/participants?page=$page',
          data: json.encode({"event_code": kode, "per_page": 500}));
      final data = response.data;
      ListParticipantModel record = ListParticipantModel.fromJson(data);
      for (var i = 0; i < record.data.length; i++) {
        insertParticipant(ListParticipantOfflineModel(
            labCode: record.data[i].labCodeSample,
            attendedAt: record.data[i].attendedAt,
            name: record.data[i].name,
            registrationCode: record.data[i].registrationCode));
      }
      print(data);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<dynamic> checkin(List<dynamic> dataCheckin) async {
    await Future.delayed(Duration(seconds: 1));
    final response = await http.post('${EndPointPath.rdt}/bulk-checkin',
        body: jsonEncode({'data': dataCheckin})
            .toString()
            .replaceAll('created_at', 'attended_at'),
        headers: {"Content-Type": "application/json"});
    final data = jsonDecode(response.body);
    print(data);

    if (response.statusCode == 200) {
      for (var i = 0; i < dataCheckin.length; i++) {
        var getData = data['succes']
            .where((element) => element == dataCheckin[i]['registration_code'])
            .toList();
        print(getData);
        if (getData.length != 0) {
          await deleteCheckinData(dataCheckin[i]['id']);
        }
      }

      return data;
    } else {
      throw Exception(
          data['failed'].length.toString() + ' data tidak berhasil dikirim');
    }
  }

  Future<void> setIsFromLogin(bool isFromLogin) async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    await prefs.setBool('IsFromLogin', isFromLogin);
    return;
  }

  Future<CheckinOfflineModel> getTable(int id) async {
    List<Map> maps = await db.query(tableCheckin,
        columns: [
          columnId,
          columnEventCode,
          columnRegistrationCode,
          columnLabCodeSample,
          columnLocation,
          columnCreatedAt
        ],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return CheckinOfflineModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteCheckinData(int id) async {
    return await db
        .delete(tableCheckin, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> deleteTableParticipant() async {
    return await db.delete(tableListParticipant);
  }

  Future<int> update(CheckinOfflineModel todo) async {
    return await db.update(tableCheckin, todo.toMap(),
        where: '$columnId = ?', whereArgs: [todo.id]);
  }

  Future<int> updateListParticipant(ListParticipantOfflineModel todo) async {
    return await db.update(tableListParticipant, todo.toMap(),
        where: '$columnId = ?', whereArgs: [todo.id]);
  }

  Future<List<Map<String, dynamic>>> select() async {
    print(db);
    if (db == null) {
      await open();
    }
    var mapList = await db.query(tableCheckin, orderBy: 'id');
    print(mapList);
    return mapList;
  }

  Future<List<CheckinOfflineModel>> getCheckinList() async {
    var contactMapList = await select();
    int count = contactMapList.length;
    List<CheckinOfflineModel> contactList = List<CheckinOfflineModel>();
    for (int i = 0; i < count; i++) {
      contactList.add(CheckinOfflineModel.fromMap(contactMapList[i]));
    }
    return contactList;
  }

  Future<List<Map<String, dynamic>>> selectParticipant() async {
    print(db);
    if (db == null) {
      await open();
    }
    var mapList = await db.query(tableListParticipant, orderBy: 'id');
    print(mapList);
    return mapList;
  }

  Future<List<ListParticipantOfflineModel>> getParticipant() async {
    var contactMapList = await selectParticipant();
    int count = contactMapList.length;
    List<ListParticipantOfflineModel> contactList =
        List<ListParticipantOfflineModel>();
    for (int i = 0; i < count; i++) {
      contactList.add(ListParticipantOfflineModel.fromMap(contactMapList[i]));
    }
    return contactList;
  }

  Future close() async => db.close();

  Future<void> setActivityCode(String activityCode) async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    await prefs.setString('activityCode', activityCode);
    return;
  }

  Future<String> getActivityCode() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value

    return prefs.getString('activityCode');
  }

  Future<void> clearActivityCode() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    prefs.remove('activityCode');
  }

  Future<void> setLocation(String location) async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    await prefs.setString('location', location);
    return;
  }

  Future<String> getLocation() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value

    return prefs.getString('location');
  }

  Future<void> clearLocation() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    prefs.remove('location');
  }
}
