import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user.dart';
import '../data/repositories/local_transaction_repository.dart';
import '../providers/local_config_provider.dart';

const String kUserPrefix = 'local_user_';
const String kCurrentUserKey = 'current_user';

class LocalUserProvider with ChangeNotifier {
  final LocalConfigProvider? configProvider;
  late SharedPreferences _prefs;
  LocalTransactionRepository? _transactionRepo;
  User? _currentUser;
  String? _currentUserId;

  User? get currentUser => _currentUser;
  LocalTransactionRepository? get transactionRepo => _transactionRepo;

  LocalUserProvider({this.configProvider}) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _transactionRepo = LocalTransactionRepository(_prefs);
    await loadCurrentUser();
  }

  Future<void> signInUser(String displayName) async {
    final userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _currentUserId = userId;

    final newUser = User(
      uid: userId,
      displayName: displayName,
      email: null,
      photoURL: null,
      coins: 0,
      totalEarned: 0,
      totalWithdrawn: 0,
      dailyStreak: 1,
      activeDays: [],
      dailyStats: {},
      lastActiveDate: DateTime.now(), // Added default value
      referralCode: '', // Changed to empty string as it's likely non-nullable
    );

    await _prefs.setString(kCurrentUserKey, userId);
    _currentUser = newUser;
    await saveCurrentUser();
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    _currentUserId = null;
    await _prefs.remove(kCurrentUserKey);
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _currentUserId = _prefs.getString(kCurrentUserKey);
    if (_currentUserId == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    final userData = _prefs.getString('$kUserPrefix$_currentUserId');
    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));

      // Ensure balance is correct by checking transactions
      final currentBalance =
          _transactionRepo?.getUserBalance(_currentUserId!) ?? 0;
      if (currentBalance != _currentUser!.coins) {
        _currentUser = _currentUser!.copyWith(coins: currentBalance);
        await saveCurrentUser();
      }

      notifyListeners();
    }
  }

  Future<void> saveCurrentUser() async {
    if (_currentUser != null && _currentUserId != null) {
      await _prefs.setString(
        '$kUserPrefix$_currentUserId',
        json.encode(_currentUser!.toJson()),
      );
      notifyListeners();
    }
  }

  Future<void> recordGameReward({
    required String gameType,
    required int amount,
    int? dailyLimit,
  }) async {
    if (_currentUser == null || _currentUserId == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final todayStats = _currentUser!.dailyStats[todayString] ?? {};
    final gamesPlayedToday = todayStats['${gameType}Played'] ?? 0;

    if (dailyLimit != null && gamesPlayedToday >= dailyLimit) {
      throw Exception('Daily limit reached for $gameType');
    }

    // Create transaction record first
    await _transactionRepo?.addTransaction(
      userId: _currentUserId!,
      type: 'earning',
      subType: gameType,
      amount: amount,
      metadata: {
        'date': todayString,
        'gameCount': gamesPlayedToday + 1,
        'gameType': gameType,
      },
    );

    // Update user data with transaction-based balance
    final currentBalance =
        _transactionRepo?.getUserBalance(_currentUserId!) ?? 0;

    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[todayString] = {
      ...(updatedDailyStats[todayString] ?? {}),
      '${gameType}Played': gamesPlayedToday + 1,
      '${gameType}Coins': (todayStats['${gameType}Coins'] ?? 0) + amount,
    };

    _currentUser = _currentUser!.copyWith(
      coins: currentBalance,
      totalEarned: _currentUser!.totalEarned + amount,
      dailyStats: updatedDailyStats,
    );

    await saveCurrentUser();
    notifyListeners();
  }

  Future<void> recordAdWatch(int rewardAmount) async {
    if (_currentUser == null || _currentUserId == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final todayStats = _currentUser!.dailyStats[todayString] ?? {};
    final adsWatchedToday = todayStats['adsWatched'] ?? 0;

    // Create transaction record first
    await _transactionRepo?.addTransaction(
      userId: _currentUserId!,
      type: 'earning',
      subType: 'ad_watch',
      amount: rewardAmount,
      metadata: {'date': todayString, 'adCount': adsWatchedToday + 1},
    );

    // Update user data with transaction-based balance
    final currentBalance =
        _transactionRepo?.getUserBalance(_currentUserId!) ?? 0;

    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[todayString] = {
      ...(updatedDailyStats[todayString] ?? {}),
      'adsWatched': adsWatchedToday + 1,
      'adCoins': (todayStats['adCoins'] ?? 0) + rewardAmount,
    };

    _currentUser = _currentUser!.copyWith(
      coins: currentBalance,
      totalEarned: _currentUser!.totalEarned + rewardAmount,
      dailyStats: updatedDailyStats,
    );

    await saveCurrentUser();
    notifyListeners();
  }

  Future<void> claimDailyReward(int dailyRewardAmount) async {
    if (_currentUser == null || _currentUserId == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final todayStats = _currentUser!.dailyStats[todayString] ?? {};
    final bool dailyRewardClaimed = todayStats['dailyBonusClaimed'] ?? false;

    if (dailyRewardClaimed) {
      throw Exception("Daily reward already claimed today.");
    }

    // Check streak continuity
    final lastStreakDate = _currentUser!.lastStreakDate;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayString = yesterday.toIso8601String().substring(0, 10);

    if (lastStreakDate != null) {
      final lastClaimDate = lastStreakDate.toIso8601String().substring(0, 10);
      if (lastClaimDate != yesterdayString) {
        // Streak broken, reset to 1
        _currentUser = _currentUser!.copyWith(dailyStreak: 1);
      } else {
        // Increment streak
        _currentUser = _currentUser!.copyWith(
          dailyStreak: _currentUser!.dailyStreak + 1,
        );
      }
    }

    // Create transaction record first
    await _transactionRepo?.addTransaction(
      userId: _currentUserId!,
      type: 'earning',
      subType: 'daily_reward',
      amount: dailyRewardAmount,
      metadata: {'date': todayString},
    );

    // Get updated balance from transactions
    final currentBalance =
        _transactionRepo?.getUserBalance(_currentUserId!) ?? 0;

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[todayString] = {
      ...(updatedDailyStats[todayString] ?? {}),
      'dailyBonusClaimed': true,
      'dailyBonusAmount': dailyRewardAmount,
    };

    List<String> activeDays = List<String>.from(_currentUser!.activeDays);
    if (!activeDays.contains(todayString)) {
      activeDays.add(todayString);
    }

    _currentUser = _currentUser!.copyWith(
      coins: currentBalance,
      totalEarned: _currentUser!.totalEarned + dailyRewardAmount,
      lastActiveDate: today,
      activeDays: activeDays,
      dailyStats: updatedDailyStats,
      lastStreakDate: today,
    );

    await saveCurrentUser();
    notifyListeners();
  }

  Future<void> requestWithdrawal({
    required int amount,
    required String method,
    required Map<String, dynamic> details,
    required int minWithdrawalCoins,
  }) async {
    if (_currentUser == null || _currentUserId == null) {
      throw Exception("User not found");
    }

    if (amount < minWithdrawalCoins) {
      throw Exception(
        "Minimum withdrawal amount is $minWithdrawalCoins coins.",
      );
    }

    if (amount > _currentUser!.coins) {
      throw Exception("Insufficient coin balance for withdrawal.");
    }

    // Create withdrawal transaction
    await _transactionRepo?.addTransaction(
      userId: _currentUserId!,
      type: 'withdrawal',
      subType: method,
      amount: -amount,
      metadata: details,
    );

    // Get updated balance
    final currentBalance =
        _transactionRepo?.getUserBalance(_currentUserId!) ?? 0;

    // Update user data
    _currentUser = _currentUser!.copyWith(
      coins: currentBalance,
      totalWithdrawn: _currentUser!.totalWithdrawn + amount,
      withdrawalInfo: details,
    );

    await saveCurrentUser();
    notifyListeners();
  }
}
