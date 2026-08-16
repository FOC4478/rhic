import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _languageKey = 'selected_language';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<void> saveLanguage(String languageCode) async {
    await _preferences.setString(_languageKey, languageCode);
  }

  Future<String?> getLanguage() async {
    return _preferences.getString(_languageKey);
  }

  Future<void> clearLanguage() async {
    await _preferences.remove(_languageKey);
  }
}