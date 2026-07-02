import 'package:shared_preferences/shared_preferences.dart';

class CsvLoginService {
  CsvLoginService._();

  static const String _csvUserKey = "csv_logged_user";

  /// Save logged in CSV user
  static Future<void> login(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_csvUserKey, userId);
  }

  /// Get currently logged in CSV user
  static Future<String?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_csvUserKey);
  }

  /// Returns true if a CSV user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_csvUserKey);
  }

  /// Logout CSV user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_csvUserKey);
  }
}