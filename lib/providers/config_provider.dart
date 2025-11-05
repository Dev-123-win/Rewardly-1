import 'package:flutter/foundation.dart';
import '../core/services/config_service.dart';

class ConfigProvider with ChangeNotifier {
  final ConfigService _configService;

  ConfigProvider(this._configService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchAppConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _configService.initialize();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get specific config values
  dynamic getConfig(String key, {dynamic defaultValue}) {
    return _configService.getValue(key, defaultValue: defaultValue);
  }

  // Commonly used getters
  int get minWithdrawalCoins => _configService.minWithdrawalAmount;
  int get dailyAdLimit => _configService.dailyAdLimit;
  int get dailySpinLimit => _configService.dailySpinLimit;
  int get referrerBonus => _configService.referralBonus;
  int get refereeBonus => _configService.refereeBonus;
  int get dailyRewardAmount => _configService.dailyRewardAmount;

  Map<String, dynamic> get appConfig => _configService.getAll();
}
