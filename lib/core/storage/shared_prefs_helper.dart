import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();
  SharedPrefsHelper._internal();
  factory SharedPrefsHelper() => _instance;

  // ── String ───────────────────────────────────────────────────

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // ── Bool ─────────────────────────────────────────────────────

  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ── Int ──────────────────────────────────────────────────────

  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // ── Utility ──────────────────────────────────────────────────

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
