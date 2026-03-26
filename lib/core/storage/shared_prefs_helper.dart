import 'package:shared_preferences/shared_preferences.dart';


class SharedPrefsHelper {
  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();

  late SharedPreferences _prefs;


  SharedPrefsHelper._internal();

  factory SharedPrefsHelper() => _instance;


  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  String? getString(String key){
   return  _prefs.getString(key);
  }

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);


  Future<void> clear() =>
      _prefs.clear();

  Future<bool> setBool(String key, bool value) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.setBool(key, value);
}

Future<bool?> getBool(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key);
}
}
