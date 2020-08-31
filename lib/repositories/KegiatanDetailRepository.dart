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
    final response = await dio
        .post('${EndPointPath.rdt}/checkin',
            data: json.encode({
              "registration_code": kode,
              "event_code": eventCode,
              "lab_code_sample": labCodeSample,
              "location": location
            }))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = response.data;
      CheckinModel record = CheckinModel.fromJson(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      throw Exception(ErrorException.notFoundUser);
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.data);
      throw Exception(data['message']);
    } else {
      throw Exception('Terjadi Kesalahan');
    }
  }

  Future<KodeKegiatanModel> checkKodeKegiatan(String kode) async {
    await Future.delayed(Duration(seconds: 1));
    String kodePerf;
    if (kode == null || kode == '') {
      kodePerf = await getActivityCode();
    }
    Response response = await dio
        .post('${EndPointPath.rdt}/event-check',
            data: json.encode(
                {"event_code": kode == null || kode == '' ? kodePerf : kode}))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = response.data;
      KodeKegiatanModel record = KodeKegiatanModel.fromJson(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      throw Exception(ErrorException.notFoundEvent);
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.data);
      throw Exception(data['message']);
    } else {
      throw Exception('Terjadi Kesalahan');
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
}
