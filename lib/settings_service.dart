import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get endpoint => _prefs.getString('endpoint') ?? 'http://127.0.0.1:4533';
  String get username => _prefs.getString('username') ?? 'username';
  String get password => _prefs.getString('password') ?? 'password';
  int get maxBitRate => _prefs.getInt('maxBitRate') ?? 0; // 0 means no limit (original quality)

  Future<void> saveSettings({
    required String endpoint,
    required String username,
    required String password,
    required int maxBitRate,
  }) async {
    await _prefs.setString('endpoint', endpoint);
    await _prefs.setString('username', username);
    await _prefs.setString('password', password);
    await _prefs.setInt('maxBitRate', maxBitRate);
  }
}
