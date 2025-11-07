import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user.dart';
import '../data/repositories/local_transaction_repository.dart';
import '../providers/config_provider.dart';

const String kUserPrefix = 'user_';
const String kDailyStatsKey = 'daily_stats';
const String kLocalWritesCountKey = 'local_writes_count';
const String kLocalReadsCountKey = 'local_reads_count';
const String kLastSyncDateKey = 'last_sync_date';

class UserProvider with ChangeNotifier {
  final ConfigProvider? configProvider;
  late SharedPreferences _prefs;
  LocalTransactionRepository? _transactionRepo;
  User? _currentUser;
  Map<String, dynamic> _localDailyStats = {};
  int _localWritesCount = 0;
  int _localReadsCount = 0;
  String _lastSyncDate = '';

  User? get currentUser => _currentUser;

  UserProvider({this.configProvider}) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _transactionRepo = LocalTransactionRepository(_prefs);
    await loadCurrentUser();
    await _loadLocalData(); // Load local data on startup
  }

  Future<void> loadCurrentUser() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    final userData = _prefs.getString('$kUserPrefix${user.uid}');
    if (userData != null) {
      _currentUser = User.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  Future<void> saveCurrentUser() async {
    if (_currentUser != null) {
      await _prefs.setString(
        '$kUserPrefix${_currentUser!.uid}',
        json.encode(_currentUser!.toJson()),
      );
    }
  }

  Future<void> saveWithdrawalInfo(Map<String, dynamic> withdrawalInfo) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    _currentUser = _currentUser!.copyWith(withdrawalInfo: withdrawalInfo);
    await saveCurrentUser();
    notifyListeners();
  }

  void clearUserData() {
    _currentUser = null;
    _localDailyStats = {};
    _localWritesCount = 0;
    _localReadsCount = 0;
    _lastSyncDate = '';

    final String? currentUid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      _prefs.remove('$kUserPrefix$currentUid');
    }
    _prefs.remove(kDailyStatsKey);
    _prefs.remove(kLocalWritesCountKey);
    _prefs.remove(kLocalReadsCountKey);
    _prefs.remove(kLastSyncDateKey);

    notifyListeners();
  }

  Future<void> redeemReferralCode(String code) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in.");
    if (_currentUser == null) throw Exception("User data not loaded.");

    // Check if the user has already redeemed a code
    if (_currentUser!.referredBy != null &&
        _currentUser!.referredBy!.isNotEmpty) {
      throw Exception("You have already redeemed a referral code.");
    }

    // Get all users from local storage to find referrer
    final allUserKeys = _prefs.getKeys().where(
      (key) => key.startsWith(kUserPrefix),
    );
    String? referrerId;
    User? referrer;

    for (final key in allUserKeys) {
      final userData = json.decode(_prefs.getString(key) ?? '{}');
      if (userData['referralCode'] == code) {
        referrer = User.fromJson(userData);
        referrerId = referrer.uid;
        break;
      }
    }

    if (referrerId == null || referrer == null) {
      throw Exception("Invalid referral code.");
    }

    if (referrerId == user.uid) {
      throw Exception("Cannot redeem your own referral code.");
    }

    // Get referral bonus from config provider or use default
    final int refereeBonus =
        configProvider?.getConfig('rewards.refereeBonus', defaultValue: 200) ??
        200;

    // Update current user
    _currentUser = _currentUser!.copyWith(
      referredBy: code,
      coins: _currentUser!.coins + refereeBonus,
      totalEarned: _currentUser!.totalEarned + refereeBonus,
    );
    await saveCurrentUser();

    // Save referral relationship
    final referral = {
      'referrerId': referrerId,
      'refereeId': user.uid,
      'refereeActiveDays': 0,
      'referrerRewarded': false,
      'refereeRewarded': true,
      'createdAt': DateTime.now().toIso8601String(),
      'completedAt': null,
    };

    final referralsKey = 'referrals_${user.uid}';
    final referrals = List<Map<String, dynamic>>.from(
      json.decode(_prefs.getString(referralsKey) ?? '[]'),
    );
    referrals.add(referral);
    await _prefs.setString(referralsKey, json.encode(referrals));

    // Add transaction for the referee
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'earning',
      subType: 'referral',
      amount: refereeBonus,
      metadata: {'referrerId': referrerId, 'referralCode': code},
    );

    notifyListeners();
  }

  Future<void> updateActiveDays() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);

    if (_currentUser!.lastActiveDate?.toIso8601String().substring(0, 10) ==
        todayString) {
      return;
    }

    // Update active days for current user
    List<String> activeDays = List<String>.from(_currentUser!.activeDays);
    if (!activeDays.contains(todayString)) {
      activeDays.add(todayString);
      _currentUser = _currentUser!.copyWith(
        activeDays: activeDays,
        lastActiveDate: today,
      );
      await saveCurrentUser();

      // Check if this user was referred and update refereeActiveDays
      if (_currentUser!.referredBy != null &&
          _currentUser!.referredBy!.isNotEmpty) {
        final referralsKey = 'referrals_${user.uid}';
        final referrals = List<Map<String, dynamic>>.from(
          json.decode(_prefs.getString(referralsKey) ?? '[]'),
        );

        // Find the referral record where user is referee and not yet completed
        final referralIndex = referrals.indexWhere(
          (r) => r['refereeId'] == user.uid && r['referrerRewarded'] == false,
        );

        if (referralIndex != -1) {
          final referral = referrals[referralIndex];
          final currentActiveDays = referral['refereeActiveDays'] ?? 0;

          if (currentActiveDays < 3) {
            // Update referral record
            referrals[referralIndex]['refereeActiveDays'] =
                currentActiveDays + 1;

            if (currentActiveDays + 1 == 3) {
              // Award referrer bonus when reaching 3 active days
              final referrerId = referral['referrerId'];
              final referrerKey = '$kUserPrefix$referrerId';
              final referrerJson = _prefs.getString(referrerKey);

              if (referrerJson != null) {
                final referrerData = json.decode(referrerJson);
                final referrer = User.fromJson(referrerData);

                final int referrerBonus =
                    configProvider?.getConfig(
                      'rewards.referrerBonus',
                      defaultValue: 500,
                    ) ??
                    500;

                // Update referrer's balance
                final updatedReferrer = referrer.copyWith(
                  coins: referrer.coins + referrerBonus,
                  totalEarned: referrer.totalEarned + referrerBonus,
                );
                await _prefs.setString(
                  referrerKey,
                  json.encode(updatedReferrer.toJson()),
                );

                // Mark referral as completed
                referrals[referralIndex]['referrerRewarded'] = true;
                referrals[referralIndex]['completedAt'] = DateTime.now()
                    .toIso8601String();

                // Create transaction for referrer
                await _transactionRepo?.addTransaction(
                  userId: referrerId,
                  type: 'earning',
                  subType: 'referral_bonus',
                  amount: referrerBonus,
                  metadata: {
                    'refereeId': user.uid,
                    'referralCode': _currentUser!.referredBy,
                  },
                );
              }
            }

            // Save updated referrals
            await _prefs.setString(referralsKey, json.encode(referrals));
          }
        }
      }

      notifyListeners();
    }
  }

  Future<void> _loadLocalData() async {
    final String today = DateTime.now().toIso8601String().substring(0, 10);

    _lastSyncDate = _prefs.getString(kLastSyncDateKey) ?? '';
    final String? dailyStatsJson = _prefs.getString(kDailyStatsKey);
    final String? localWritesCount = _prefs.getString(kLocalWritesCountKey);
    final String? localReadsCount = _prefs.getString(kLocalReadsCountKey);

    if (dailyStatsJson != null) {
      _localDailyStats = jsonDecode(dailyStatsJson);
    } else {
      _localDailyStats = {};
    }

    _localWritesCount = int.tryParse(localWritesCount ?? '0') ?? 0;
    _localReadsCount = int.tryParse(localReadsCount ?? '0') ?? 0;

    // Reset daily stats if it's a new day
    if (_lastSyncDate != today) {
      _localDailyStats = {};
      _localWritesCount = 0;
      _localReadsCount = 0;
      _lastSyncDate = today;
      await _saveLocalData(); // Save the reset data
    }
    notifyListeners();
  }

  Future<void> _saveLocalData() async {
    await _prefs.setString(kDailyStatsKey, jsonEncode(_localDailyStats));
    await _prefs.setString(kLocalWritesCountKey, _localWritesCount.toString());
    await _prefs.setString(kLocalReadsCountKey, _localReadsCount.toString());
    await _prefs.setString(kLastSyncDateKey, _lastSyncDate);
  }

  void incrementReadsCount() {
    _localReadsCount++;
    _saveLocalData();
    notifyListeners();
  }

  void incrementWritesCount() {
    _localWritesCount++;
    _saveLocalData();
    notifyListeners();
  }

  Future<void> claimDailyReward(int dailyRewardAmount) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final Map<String, dynamic> todayStats =
        _currentUser!.dailyStats[todayString] ?? {};
    final bool dailyRewardClaimed = todayStats['dailyRewardClaimed'] ?? false;

    if (dailyRewardClaimed ||
        _currentUser!.lastActiveDate?.toIso8601String().substring(0, 10) ==
            todayString) {
      throw Exception("Daily reward already claimed today.");
    }

    // Update local daily stats
    _localDailyStats[todayString] = {
      ...(_localDailyStats[todayString] ?? {}),
      'dailyRewardClaimed': true,
    };
    incrementWritesCount();

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[todayString] = {
      ...(updatedDailyStats[todayString] ?? {}),
      'dailyRewardClaimed': true,
    };

    List<String> activeDays = List<String>.from(_currentUser!.activeDays);
    if (!activeDays.contains(todayString)) {
      activeDays.add(todayString);
    }

    _currentUser = _currentUser!.copyWith(
      coins: _currentUser!.coins + dailyRewardAmount,
      totalEarned: _currentUser!.totalEarned + dailyRewardAmount,
      lastActiveDate: today,
      activeDays: activeDays,
      dailyStats: updatedDailyStats,
    );
    await saveCurrentUser();

    // Create transaction record
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'earning',
      subType: 'daily_reward',
      amount: dailyRewardAmount,
      metadata: {'date': todayString},
    );

    notifyListeners();
  }

  Future<void> recordGameReward({
    required String gameType,
    required int amount,
    int? dailyLimit,
  }) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final todayStats = _currentUser!.dailyStats[todayString] ?? {};
    final gamesPlayedToday = todayStats['${gameType}Played'] ?? 0;

    if (dailyLimit != null && gamesPlayedToday >= dailyLimit) {
      throw Exception('Daily limit reached for $gameType');
    }

    // Update local daily stats
    _localDailyStats[todayString] = {
      ...(_localDailyStats[todayString] ?? {}),
      '${gameType}Played': gamesPlayedToday + 1,
    };
    incrementWritesCount();

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[todayString] = {
      ...(updatedDailyStats[todayString] ?? {}),
      '${gameType}Played': gamesPlayedToday + 1,
    };

    _currentUser = _currentUser!.copyWith(
      coins: _currentUser!.coins + amount,
      totalEarned: _currentUser!.totalEarned + amount,
      dailyStats: updatedDailyStats,
    );
    await saveCurrentUser();

    // Create transaction record
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'earning',
      subType: gameType,
      amount: amount,
      metadata: {'date': todayString, 'gameCount': gamesPlayedToday + 1},
    );

    notifyListeners();
  }

  Future<void> requestWithdrawal({
    required int amount,
    required String method,
    required Map<String, dynamic> details,
    required int minWithdrawalCoins,
  }) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) {
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

    // Update user data
    _currentUser = _currentUser!.copyWith(
      coins: _currentUser!.coins - amount,
      totalWithdrawn: _currentUser!.totalWithdrawn + amount,
      withdrawalInfo: details,
    );
    await saveCurrentUser();

    // Create transaction record
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'withdrawal',
      subType: method,
      amount: -amount,
      metadata: details,
    );

    notifyListeners();
  }
}
