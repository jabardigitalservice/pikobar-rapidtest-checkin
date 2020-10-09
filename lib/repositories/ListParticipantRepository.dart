import 'dart:convert';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:rapid_test/utilities/http.dart';

class ListParticipantRepository {
  Future<dynamic> getListOfParticipant(String kode, keyword, int page) async {
    await Future.delayed(Duration(seconds: 1));
    String kodePerf;
    if (kode == null || kode == '') {
      kodePerf = await getActivityCode();
    }
    try {
      Response response = await dio.post(
          '${EndPointPath.baseUrl}/checkin/event/participants?page=${page.toString()}',
          data: json.encode({
            "event_code": kode == null || kode == '' ? kodePerf : kode,
            "per_page": "20",
            "keyword": keyword == null ? '' : keyword
          }));
      final data = response.data;
      ListParticipantModel record = ListParticipantModel.fromJson(data);
      await Preferences.setTotalCount(record.meta.total);
      print(data);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<String> getActivityCode() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value

    return prefs.getString('activityCode');
  }
}
