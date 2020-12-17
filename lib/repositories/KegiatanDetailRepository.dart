import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:rapid_test/utilities/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KegiatanDetailRepository {
  Future<CheckinModel> checkNomorPendaftaran(
      String kode, eventCode, labCodeSample, location) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      final response = await dio.post('${EndPointPath.rdt}/checkin',
          data: json.encode({
            "registration_code": kode,
            "event_code": eventCode,
            "lab_code_sample": labCodeSample,
            "location": location
          }));
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
      kodePerf = await Preferences.getDataString('activityCode');
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
}
