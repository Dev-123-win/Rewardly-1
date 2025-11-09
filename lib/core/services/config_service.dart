import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConfigService {
  SharedPreferences? _prefs;
  Map<String, dynamic> _config = {};
  DateTime? _lastFetch;
  static const _cacheExpiryDuration = Duration(hours: 24);

  ConfigService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> initialize() async {
    await _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final configJson = _prefs?.getString('app_config');
      if (configJson != null) {
        _config = json.decode(configJson);
        _lastFetch = DateTime.now();
      } else {
        // Initialize with default values
        _config = {
          'rewards': {
            'referrerBonus': 500,
            'refereeBonus': 200,
            'dailyBonus': 100,
            'adReward': 10,
            'spinReward': 20,
            'gameReward': 15,
          },
          'limits': {'dailyAds': 10, 'dailySpins': 3, 'minWithdrawal': 10000},
        };
        await _saveConfig();
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> _saveConfig() async {
    await _prefs?.setString('app_config', json.encode(_config));
    _lastFetch = DateTime.now();
  }

  dynamic getValue(String key, {dynamic defaultValue}) {
    _refreshIfNeeded();
    return _config[key] ?? defaultValue;
  }

  Map<String, dynamic> getAll() {
    _refreshIfNeeded();
    return Map<String, dynamic>.from(_config);
  }

  void _refreshIfNeeded() {
    if (_lastFetch == null ||
        DateTime.now().difference(_lastFetch!) > _cacheExpiryDuration) {
      _fetchConfig();
    }
  }

  // Specific getters for commonly used config values
  int get dailyAdLimit => getValue('dailyAdLimit', defaultValue: 10);
  int get dailySpinLimit => getValue('dailySpinLimit', defaultValue: 3);
  int get minWithdrawalAmount =>
      getValue('minWithdrawalAmount', defaultValue: 10000);
  int get dailyRewardAmount => getValue('dailyRewardAmount', defaultValue: 100);
  int get referralBonus => getValue('referralBonus', defaultValue: 500);
  int get refereeBonus => getValue('refereeBonus', defaultValue: 200);
}
