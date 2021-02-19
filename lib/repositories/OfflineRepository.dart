import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/storageKeys.dart';
import 'package:rapid_test/model/CheckinOfflineModel.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/model/ListParticipantOfflineModel.dart';
import 'package:rapid_test/utilities/http.dart';
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
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path + kTesMasifDB;
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
    if (db == null) {
      await open();
    }
    todo.id = await db.insert(tableCheckin, todo.toMap());
    return todo;
  }

  Future<ListParticipantOfflineModel> insertParticipant(
      ListParticipantOfflineModel todo) async {
    if (db == null) {
      await open();
    }
    todo.id = await db.insert(tableListParticipant, todo.toMap());
    return todo;
  }

  Future<dynamic> getListOfParticipant(String kode, page) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      final Response response = await dio.post(
          '${EndPointPath.baseUrl}/checkin/event/participants?page=$page',
          data: json.encode({"event_code": kode, "per_page": 500}));
      final dynamic data = response.data;
      final ListParticipantModel record = ListParticipantModel.fromJson(data);
      for (var i = 0; i < record.data.length; i++) {
        insertParticipant(ListParticipantOfflineModel(
            labCode: record.data[i].labCodeSample,
            attendedAt: record.data[i].attendedAt,
            name: record.data[i].name,
            registrationCode: record.data[i].registrationCode));
      }
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<dynamic> checkin(List<dynamic> dataCheckin) async {
    await Future.delayed(Duration(seconds: 1));
    final dynamic response = await http.post('${EndPointPath.rdt}/bulk-checkin',
        body: jsonEncode({'data': dataCheckin})
            .toString()
            .replaceAll('created_at', 'attended_at'),
        headers: {"Content-Type": "application/json"});
    final dynamic data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      for (var i = 0; i < dataCheckin.length; i++) {
        final dynamic getData = data['succes']
            .where((element) => element == dataCheckin[i]['registration_code'])
            .toList();
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

  Future<CheckinOfflineModel> getTable(int id) async {
    final List<Map> maps = await db.query(tableCheckin,
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
    if (db == null) {
      await open();
    }
    final List<Map<String, dynamic>> mapList =
        await db.query(tableCheckin, orderBy: 'id');

    return mapList;
  }

  Future<List<CheckinOfflineModel>> getCheckinList() async {
    final List<Map<String, dynamic>> contactMapList = await select();
    final int count = contactMapList.length;
    final List<CheckinOfflineModel> contactList = List<CheckinOfflineModel>();
    for (int i = 0; i < count; i++) {
      contactList.add(CheckinOfflineModel.fromMap(contactMapList[i]));
    }
    return contactList;
  }

  Future<List<Map<String, dynamic>>> selectParticipant() async {
    if (db == null) {
      await open();
    }
    final List<Map<String, dynamic>> mapList =
        await db.query(tableListParticipant, orderBy: 'id');

    return mapList;
  }

  Future<List<ListParticipantOfflineModel>> getParticipant() async {
    final List<Map<String, dynamic>> contactMapList = await selectParticipant();
    final int count = contactMapList.length;
    final List<ListParticipantOfflineModel> contactList =
        List<ListParticipantOfflineModel>();
    for (int i = 0; i < count; i++) {
      contactList.add(ListParticipantOfflineModel.fromMap(contactMapList[i]));
    }
    return contactList;
  }

  Future close() async => db.close();
}
