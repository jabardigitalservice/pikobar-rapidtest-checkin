import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static Future<int> getParticipantPage() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('participantPage');
  }

  static Future<bool> setParticipantPage(int value) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.setInt('participantPage', value);
  }

  static Future<int> getTotalCount() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('TotalCount');
  }

  static Future<bool> setTotalCount(int value) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.setInt('TotalCount', value);
  }
}