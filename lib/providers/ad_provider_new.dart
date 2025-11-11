import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_milestone.dart';
import 'dart:async'; // Import for Timer

class AdProviderNew extends ChangeNotifier {
  RewardedAd? rewardedAd;
  bool _isAdLoading = false; // Use a private flag to manage loading state
  int _rewardedAdLoadAttempts = 0;
  static const int _maxAdLoadAttempts = 3; // Max retries for ad loading
  static const Duration _adLoadRetryDelay = Duration(seconds: 5); // Delay before retrying

  final List<AdMilestone> _milestones = [
    AdMilestone(
      requiredWatches: 1,
      reward: 5,
      isLocked: false,
    ), // First milestone is unlocked
    AdMilestone(requiredWatches: 2, reward: 6),
    AdMilestone(requiredWatches: 3, reward: 7),
    AdMilestone(requiredWatches: 4, reward: 8),
    AdMilestone(requiredWatches: 5, reward: 10),
    AdMilestone(requiredWatches: 6, reward: 12),
    AdMilestone(requiredWatches: 7, reward: 8),
    AdMilestone(requiredWatches: 8, reward: 6),
    AdMilestone(requiredWatches: 9, reward: 4),
    AdMilestone(requiredWatches: 10, reward: 14),
  ];

  static const int _dailyAdLimit = 10;
  int get dailyAdLimit => _dailyAdLimit;

  List<AdMilestone> get milestones => List.unmodifiable(_milestones);

  int _adsWatchedToday = 0;
  int get adsWatchedToday => _adsWatchedToday;

  AdProviderNew() {
    _preloadRewardedAd(); // Preload ad when the provider is created
  }

  void _preloadRewardedAd() {
    if (_isAdLoading || rewardedAd != null) return;
    _isAdLoading = true;

    // Using the real AdMob rewarded ad unit ID provided by the user
    const String adUnitId = 'ca-app-pub-3863562453957252/5980806527';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          _isAdLoading = false;
          _rewardedAdLoadAttempts = 0; // Reset attempts on success
          notifyListeners();
          debugPrint('Rewarded Ad preloaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded Ad failed to load: $error');
          _isAdLoading = false;
          rewardedAd = null; // Ensure ad is null if loading failed
          _rewardedAdLoadAttempts++;
          notifyListeners();
          _handleAdLoadFailure();
        },
      ),
    );
  }

  void _handleAdLoadFailure() {
    if (_rewardedAdLoadAttempts < _maxAdLoadAttempts) {
      debugPrint('Retrying rewarded ad load in ${_adLoadRetryDelay.inSeconds} seconds...');
      Timer(_adLoadRetryDelay, () {
        _preloadRewardedAd();
      });
    } else {
      debugPrint('Max rewarded ad load attempts reached. No ad available.');
      // Optionally, show a user-friendly message or disable ad-related features
    }
  }

  Future<void> showRewardedAd({
    required Function(int reward) onAdEarned,
  }) async {
    if (rewardedAd == null) {
      debugPrint('Rewarded Ad not loaded. Attempting to preload...');
      if (!_isAdLoading) {
        _preloadRewardedAd(); // Try to load if not already loading
      }
      // Optionally, wait for the ad to load or show a message to the user
      return;
    }

    final currentMilestone = _getNextUncompletedMilestone();
    if (currentMilestone == null) {
      debugPrint('No uncompleted milestones available.');
      return;
    }

    await rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        _completeCurrentMilestone();
        onAdEarned(currentMilestone.reward);
      },
    );

    rewardedAd = null;
    _preloadRewardedAd(); // Preload next ad immediately after showing one
    notifyListeners();
  }

  AdMilestone? _getNextUncompletedMilestone() {
    return _milestones.firstWhere(
      (milestone) => !milestone.isCompleted,
      orElse: () => _milestones.last, // Fallback to last if all completed
    );
  }

  void _completeCurrentMilestone() {
    final currentIndex = _milestones.indexWhere((m) => !m.isCompleted);
    if (currentIndex != -1) {
      _milestones[currentIndex] = _milestones[currentIndex].copyWith(
        isCompleted: true,
      );

      // Unlock next milestone if available
      if (currentIndex + 1 < _milestones.length) {
        _milestones[currentIndex + 1] = _milestones[currentIndex + 1].copyWith(
          isLocked: false,
        );
      }

      _adsWatchedToday++;
      notifyListeners();
    }
  }

  void resetDailyProgress() {
    _adsWatchedToday = 0;
    for (var i = 0; i < _milestones.length; i++) {
      _milestones[i] = _milestones[i].copyWith(
        isCompleted: false,
        isLocked: i != 0, // Only first milestone is unlocked
        requiredWatches: i + 1, // Ensure requiredWatches is set correctly
      );
    }
    _preloadRewardedAd(); // Preload ad after resetting progress
    notifyListeners();
  }

  int get totalEarnedToday {
    return _milestones
        .where((m) => m.isCompleted)
        .fold(0, (sum, m) => sum + m.reward);
  }
}
