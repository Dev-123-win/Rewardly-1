import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConfigProvider with ChangeNotifier {
  Map<String, dynamic> _appConfig = {};
  Map<String, dynamic> get appConfig => _appConfig;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;

  ConfigProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadConfigFromCache();
  }

  void _loadConfigFromCache() {
    final String? cachedConfig = _prefs.getString('app_config');
    final int? lastFetchedTimestamp = _prefs.getInt('app_config_last_fetched');

    if (cachedConfig != null && lastFetchedTimestamp != null) {
      _appConfig = json.decode(cachedConfig);
      // Optionally, you could check here if the cached config is too old
      // and trigger a refresh, but we'll handle that in fetchAppConfig.
      notifyListeners();
    }
  }

  Future<void> fetchAppConfig({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    final int? lastFetchedTimestamp = _prefs.getInt('app_config_last_fetched');
    final bool isCacheOutdated = lastFetchedTimestamp == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastFetchedTimestamp)).inDays >= 7; // Weekly refresh

    if (!forceRefresh && _appConfig.isNotEmpty && !isCacheOutdated) {
      // Use cached data if not forced to refresh, config is not empty, and cache is not outdated
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final DocumentSnapshot configDoc = await _firestore.collection('app_config').doc('settings').get();
      if (configDoc.exists) {
        _appConfig = configDoc.data() as Map<String, dynamic>;
        _prefs.setString('app_config', json.encode(_appConfig));
        _prefs.setInt('app_config_last_fetched', DateTime.now().millisecondsSinceEpoch);
      } else {
        // Set default values if config doesn't exist
        _appConfig = {
          'minWithdrawalCoins': 10000,
          'coinsPerRupee': 100,
          'dailyReadLimit': 5,
          'dailyWriteLimit': 3,
          'dailyAdLimit': 10,
          'dailySpinLimit': 3,
          'rewards': {
            'dailyReward': 10,
            'adReward': 4,
            'spinReward': 4,
            'tictactoeReward': 4,
            'referrerBonus': 500,
            'refereeBonus': 200,
          },
        };
        _prefs.setString('app_config', json.encode(_appConfig));
        _prefs.setInt('app_config_last_fetched', DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      // Fallback to cached or default values on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get specific config values
  dynamic getConfig(String key, {dynamic defaultValue}) {
    return _appConfig[key] ?? defaultValue;
  }
}
