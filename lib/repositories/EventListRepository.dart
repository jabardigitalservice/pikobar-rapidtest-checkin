import 'package:rapid_test/constants/EndPointPath.dart';
import 'package:rapid_test/constants/SharedPreferenceKey.dart';
import 'package:rapid_test/model/EventListModel.dart';
import 'package:rapid_test/utilities/SharedPreferences.dart';
import 'package:dio/dio.dart';
import 'package:rapid_test/utilities/http.dart';

class EventListRepository {
  Future<dynamic> getListOfEvent(int page) async {
    await Future.delayed(Duration(seconds: 1));
    try {
      Response response = await dio.get(
        '${EndPointPath.baseUrl}/rdt/events?per_page=20&page=${page.toString()}&sort_by=created_at&sort_order=desc&status=published',
      );
      final data = response.data;
      EventListModel record = EventListModel.fromJson(data);
      await Preferences.setDataInt(kTotalCount, record.meta.total);
      return record;
    } catch (e) {
      throw Exception(e);
    }
  }
}
