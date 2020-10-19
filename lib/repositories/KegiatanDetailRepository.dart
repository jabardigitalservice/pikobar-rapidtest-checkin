import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KegiatanDetailRepository {
  Future<CheckinModel> checkNomorPendaftaran(
      String kode, eventCode, labCodeSample, location) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      final response = await dio
          .post('${EndPointPath.rdt}/checkin',
              data: json.encode({
                "registration_code": kode,
                "event_code": eventCode,
                "lab_code_sample": labCodeSample,
                "location": location
              }))
          .timeout(const Duration(seconds: 15));
      final data = response.data;
      CheckinModel record = CheckinModel.fromJson(data);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<KodeKegiatanModel> checkKodeKegiatan(String kode) async {
    await Future.delayed(Duration(seconds: 1));
    String kodePerf;
    if (kode == null || kode == '') {
      kodePerf = await getActivityCode();
    }
    try {
      Response response = await dio
          .post('${EndPointPath.rdt}/event-check',
              data: json.encode(
                  {"event_code": kode == null || kode == '' ? kodePerf : kode}))
          .timeout(const Duration(seconds: 15));
      final data = response.data;
      KodeKegiatanModel record = KodeKegiatanModel.fromJson(data);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> getName(String registrationCode) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      Response response = await dio
          .post('${EndPointPath.baseUrl}/checkin/applicant-profile',
              data: json.encode({"registration_code": registrationCode}))
          .timeout(const Duration(seconds: 15));
      final data = response.data;
      print(data);
      return data;
    } catch (e) {
      throw Exception(e);
    }
  }

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

  Future<void> setIsFromLogin(bool isFromLogin) async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    await prefs.setBool('IsFromLogin', isFromLogin);
    return;
  }

  Future<bool> getIsFromLogin() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    bool temp = prefs.getBool('IsFromLogin');
    if (temp == null) {
      return true;
    } else {
      return prefs.getBool('IsFromLogin');
    }
  }

  Future<void> clearIsFromLogin() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value
    prefs.remove('IsFromLogin');
  }
}
