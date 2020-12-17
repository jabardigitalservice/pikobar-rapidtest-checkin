import 'dart:convert';
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:dio/dio.dart';
import 'package:rapid_test/utilities/http.dart';

class ListParticipantRepository {
  Future<dynamic> getListOfParticipant(String kode, keyword, int page) async {
    await Future.delayed(Duration(seconds: 1));
    String kodePerf;
    if (kode == null || kode == '') {
      kodePerf = await Preferences.getDataString('activityCode');
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
      await Preferences.setDataInt('TotalCount', record.meta.total);
      print(data);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }

}
