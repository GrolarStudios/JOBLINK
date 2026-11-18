import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const String _key = 'isDarkMode';

  static Future<void> saveThemePreference(bool isDarkMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_key, isDarkMode);
  }

  static Future<bool> getThemePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }
}
