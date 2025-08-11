import 'package:shared_preferences/shared_preferences.dart';

class CacheRepository {
  final SharedPreferencesWithCache _sharedPreferences;

  CacheRepository({required SharedPreferencesWithCache sharedPreferences})
      : _sharedPreferences = sharedPreferences;

  Future<String> getString(String key, {String defaultValue = ""}) async {
    return _sharedPreferences.getString(key) ?? defaultValue;
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    return _sharedPreferences.getInt(key) ?? defaultValue;
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _sharedPreferences.getBool(key) ?? defaultValue;
  }

  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    return _sharedPreferences.getDouble(key) ?? defaultValue;
  }

  Future<void> putString(String key, String value) async {
    _sharedPreferences.setString(key, value);
  }

  Future putInt(String key, int value) async {
    _sharedPreferences.setInt(key, value);
  }

  Future putBool(String key, bool value) async {
    _sharedPreferences.setBool(key, value);
  }

  Future putDouble(String key, double value) async {
    _sharedPreferences.setDouble(key, value);
  }
}
