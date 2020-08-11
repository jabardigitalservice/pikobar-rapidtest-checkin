import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/constants/HttpHeaders.dart';
import 'package:rapid_test/model/CheckinModel.dart';
import 'package:rapid_test/model/KodeKegiatanModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KegiatanDetailRepository {
  Future<CheckinModel> checkNomorPendaftaran(
      String kode, eventCode, labCodeSample) async {
    await Future.delayed(Duration(seconds: 1));
    final response = await http
        .post('${EndPointPath.rdt}/checkin',
            headers: await HttpHeaders.headers(),
            body: json.encode({
              "registration_code": kode,
              "event_code": eventCode,
              "lab_code_sample": labCodeSample
            }))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      CheckinModel record = CheckinModel.fromJson(data);
      print(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      final data = jsonDecode(response.body);
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
    final response = await http
        .post('${EndPointPath.rdt}/event-check',
            headers: await HttpHeaders.headers(),
            body: json.encode(
                {"event_code": kode == null || kode == '' ? kodePerf : kode}))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      KodeKegiatanModel record = KodeKegiatanModel.fromJson(data);
      print(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      final data = jsonDecode(response.body);
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
}
