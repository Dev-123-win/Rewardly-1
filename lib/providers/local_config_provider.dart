import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalConfigProvider with ChangeNotifier {
  static const String _configKey = 'local_app_config';
  late SharedPreferences _prefs;
  Map<String, dynamic> _appConfig = {
    // Default configuration values
    'dailySpinLimit': 3,
    'minWithdrawalCoins': 10000,
    'rewards': {'refereeBonus': 200, 'referrerBonus': 500},
    'adRewards': {'basic': 50, 'premium': 100},
    'gameRewards': {
      'ticTacToe': {'win': 100, 'draw': 20},
      'spinAndWin': {'max': 200, 'min': 10},
      'whackAMole': {'perMole': 10, 'timeBonus': 50},
    },
  };

  Map<String, dynamic> get appConfig => _appConfig;

  LocalConfigProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadConfig();
  }

  void _loadConfig() {
    final storedConfig = _prefs.getString(_configKey);
    if (storedConfig != null) {
      _appConfig = Map<String, dynamic>.from(
        const JsonDecoder().convert(storedConfig),
      );
    }
    notifyListeners();
  }

  Future<void> updateConfig(Map<String, dynamic> newConfig) async {
    _appConfig = newConfig;
    await _prefs.setString(_configKey, const JsonEncoder().convert(newConfig));
    notifyListeners();
  }

  dynamic getConfig(String key, {dynamic defaultValue}) {
    final keys = key.split('.');
    dynamic value = _appConfig;

    for (final k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return defaultValue;
      }
    }

    return value ?? defaultValue;
  }
}
