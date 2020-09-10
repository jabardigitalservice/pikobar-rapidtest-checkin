import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/ErrorException.dart';
import 'package:rapid_test/constants/HttpHeaders.dart';
import 'package:rapid_test/model/ListParticipantModel.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListParticipantRepository {
  Future<dynamic> getListOfParticipant(
      String kode, keyword, int page) async {
    await Future.delayed(Duration(seconds: 1));
    String kodePerf;
    if (kode == null || kode == '') {
      kodePerf = await getActivityCode();
    }
    final response = await http
        .post(
            '${EndPointPath.baseUrl}/checkin/event/participants?page=${page.toString()}',
            headers: await HttpHeaders.headers(),
            body: json.encode({
              "event_code": kode == null || kode == '' ? kodePerf : kode,
              "per_page": "20",
              "keyword": keyword == null ? '' : keyword
            }))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ListParticipantModel record = ListParticipantModel.fromJson(data);
      await Preferences.setTotalCount(record.meta.total);
      print(data);
      return record;
    } else if (response.statusCode == 401) {
      throw Exception(ErrorException.unauthorizedException);
    } else if (response.statusCode == 408) {
      throw Exception(ErrorException.timeoutException);
    } else if (response.statusCode == 404) {
      throw Exception(ErrorException.notFoundEvent);
    } else if (response.statusCode == 422) {
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    } else {
      throw Exception('Terjadi Kesalahan');
    }
  }

  Future<String> getActivityCode() async {
    // obtain shared preferences
    final prefs = await SharedPreferences.getInstance();
    // set value

    return prefs.getString('activityCode');
  }
}
