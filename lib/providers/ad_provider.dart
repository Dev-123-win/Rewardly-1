import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdProvider with ChangeNotifier {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  RewardedAd? get rewardedAd => _rewardedAd; // Expose the ad for direct access
  bool get isRewardedAdReady => _isRewardedAdReady;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ad unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdReady = false;
          _rewardedAd = null; // Ensure ad is null on failure
          notifyListeners();
        },
      ),
    );
  }

  void showRewardedAd({required Function(RewardItem) onAdEarned}) {
    if (_rewardedAd == null) {
      debugPrint(
        'Warning: Attempted to show rewarded ad before it was loaded.',
      );
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null; // Clear ad after dismissal
        loadRewardedAd(); // Load a new ad
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null; // Clear ad on failure
        loadRewardedAd(); // Load a new ad
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onAdEarned(reward);
      },
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}
