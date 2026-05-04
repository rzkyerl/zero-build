import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preferences using SharedPreferences.
class SettingsService {
  static const _keyAutoSave = 'auto_save';

  static SettingsService? _instance;
  late SharedPreferences _prefs;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ── Auto Save ──────────────────────────────────────────────────────────────

  bool get autoSave => _prefs.getBool(_keyAutoSave) ?? false;

  Future<void> setAutoSave(bool value) => _prefs.setBool(_keyAutoSave, value);
}
