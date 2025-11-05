import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  final FirebaseFirestore _firestore;
  Map<String, dynamic> _config = {};
  DateTime? _lastFetch;
  static const _cacheExpiryDuration = Duration(hours: 24);

  ConfigService(this._firestore);

  Future<void> initialize() async {
    await _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('settings')
          .get();
      if (doc.exists) {
        _config = doc.data() ?? {};
        _lastFetch = DateTime.now();
      }
    } catch (e) {
      // In case of error, keep using cached config
      debugPrint('Error fetching config: $e');
    }
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
