import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/game_service.dart';
import 'user_provider.dart';
import 'ad_provider.dart';

// Game constants
const int normalMoleCoins = 5; // Base coins per normal mole
const int bomberPenalty = -3; // Penalty for hitting bomber mole
const int comboBonus = 2; // Additional coins for 3+ consecutive hits
const int adBonusCoins = 10; // Bonus coins for watching ad after game

class WhackAMoleProvider extends ChangeNotifier {
  final BuildContext context;

  WhackAMoleProvider(this.context) {
    _initGame();
  }

  // Game state
  late Duration countdown;
  late List<MoleModel> moles;
  int currentGameCoins = 0;
  int consecutiveHits = 0;
  int maxCombo = 0;
  bool isPlaying = false;

  DateTime? _startedAt;
  DateTime? _stoppedAt;

  void _initGame() {
    countdown = const Duration(minutes: 1);
    moles = List.generate(9, (i) => MoleModel(index: i));
    currentGameCoins = 0;
    consecutiveHits = 0;
    maxCombo = 0;
    isPlaying = false;
    _startedAt = null;
    _stoppedAt = null;
  }

  Future<void> startGame() async {
    _initGame();
    isPlaying = true;
    _startedAt = DateTime.now();
    notifyListeners();

    while (isPlaying && countdown.inSeconds > 0) {
      await Future.delayed(const Duration(seconds: 1));
      countdown = countdown - const Duration(seconds: 1);

      // Update moles
      for (var mole in moles) {
        moles[mole.index] = mole
          ..isTapped = false
          ..type = _getRandomMoleType();
      }

      notifyListeners();
    }

    await _handleGameOver();
  }

  MoleType _getRandomMoleType() {
    // 70% chance for normal mole, 30% chance for bomber
    return Random().nextDouble() > 0.3 ? MoleType.normal : MoleType.bomber;
  }

  Future<void> onMoleHit(MoleModel mole) async {
    if (!isPlaying || mole.isTapped) return;

    if (mole.type == MoleType.bomber) {
      countdown -= const Duration(seconds: 5);
      currentGameCoins += bomberPenalty;
      consecutiveHits = 0;
    } else if (mole.type == MoleType.normal) {
      countdown += const Duration(seconds: 1);
      consecutiveHits++;
      maxCombo = max(maxCombo, consecutiveHits);

      // Calculate coins with combo bonus
      int coinsEarned = normalMoleCoins;
      if (consecutiveHits >= 3) {
        coinsEarned += comboBonus;
      }
      currentGameCoins += coinsEarned;
    }

    moles[mole.index] = mole..isTapped = true;
    notifyListeners();

    // Check if game should end
    if (countdown.inSeconds <= 0) {
      isPlaying = false;
      await _handleGameOver();
    }
  }

  Future<void> _handleGameOver() async {
    _stoppedAt = DateTime.now();
    isPlaying = false;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adProvider = Provider.of<AdProvider>(context, listen: false);

    // Save base game coins if positive
    if (currentGameCoins > 0) {
      await GameService.handleGameEarnings(
        userProvider: userProvider,
        amount: currentGameCoins,
        gameType: 'whack_a_mole',
        metadata: {
          'maxCombo': maxCombo,
          'duration': _stoppedAt!.difference(_startedAt!).inSeconds,
        },
      );
    }

    // Show reward ad if available
    if (adProvider.isRewardedAdReady) {
      adProvider.showRewardedAd(
        onAdEarned: (reward) async {
          // Award bonus coins for watching ad
          currentGameCoins += adBonusCoins;

          // Update user's coin balance with ad bonus
          await GameService.handleAdReward(
            userProvider: userProvider,
            amount: adBonusCoins,
            source: 'whack_a_mole',
          );
          notifyListeners();
        },
      );
    }

    notifyListeners();
  }

  Duration? get gameResult {
    if (_startedAt == null || _stoppedAt == null) return null;
    return _stoppedAt!.difference(_startedAt!);
  }
}

enum MoleType { normal, bomber, none }

class MoleModel {
  MoleModel({this.index = 0, this.type = MoleType.none, this.isTapped = false});

  MoleType type;
  int index;
  bool isTapped;
}
