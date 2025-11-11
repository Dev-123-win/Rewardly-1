import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_milestone.dart';

class AdProviderNew extends ChangeNotifier {
  RewardedAd? rewardedAd;
  bool isLoading = false;
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

  void loadRewardedAd() {
    if (isLoading || rewardedAd != null) return;
    isLoading = true;

    RewardedAd.load(
      adUnitId: 'ca-app-pub-3863562453957252/2356285112', // Rewarded Ad Unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          isLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          isLoading = false;
          notifyListeners();
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Function(int reward) onAdEarned,
  }) async {
    if (rewardedAd == null) return;

    final currentMilestone = _getNextUncompletedMilestone();
    if (currentMilestone == null) return;

    await rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        _completeCurrentMilestone();
        onAdEarned(currentMilestone.reward);
      },
    );

    rewardedAd = null;
    loadRewardedAd(); // Preload next ad
    notifyListeners();
  }

  AdMilestone? _getNextUncompletedMilestone() {
    return _milestones.firstWhere(
      (milestone) => !milestone.isCompleted,
      orElse: () => _milestones.last,
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
    notifyListeners();
  }

  int get totalEarnedToday {
    return _milestones
        .where((m) => m.isCompleted)
        .fold(0, (sum, m) => sum + m.reward);
  }
}
