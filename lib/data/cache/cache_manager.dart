import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const String userDataKey = 'user_data';
  static const String configDataKey = 'config_data';
  static const String lastSyncKey = 'last_sync';

  final SharedPreferences _prefs;

  CacheManager(this._prefs);

  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(userDataKey, jsonEncode(userData));
    await _prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, dynamic>? getCachedUserData() {
    final data = _prefs.getString(userDataKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  bool needsSync() {
    final lastSync = _prefs.getInt(lastSyncKey) ?? 0;
    final sixHoursAgo = DateTime.now()
        .subtract(Duration(hours: 6))
        .millisecondsSinceEpoch;
    return lastSync < sixHoursAgo;
  }

  Future<void> clearCache() async {
    await _prefs.remove(userDataKey);
    await _prefs.remove(configDataKey);
    await _prefs.remove(lastSyncKey);
  }
}
