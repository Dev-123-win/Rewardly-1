import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _darkModeEnabled = false;
  bool get darkModeEnabled => _darkModeEnabled;

  late SharedPreferences _prefs;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    _darkModeEnabled = _prefs.getBool('darkModeEnabled') ?? false;
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _darkModeEnabled = value;
    await _prefs.setBool('darkModeEnabled', value);
    notifyListeners();
  }
}
