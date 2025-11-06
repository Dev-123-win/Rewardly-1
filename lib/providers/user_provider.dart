import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/local_transaction_repository.dart';
import 'config_provider.dart';

// Constant keys for SharedPreferences
const String kUserPrefix = 'user_data_';
const String kDailyStatsKey = 'local_daily_stats';
const String kPendingWritesKey = 'pending_writes';
const String kLocalWritesCountKey = 'local_writes_count';
const String kLocalReadsCountKey = 'local_reads_count';
const String kLastSyncDateKey = 'last_sync_date';
const String kLastFetchDateKey = 'last_fetch_date';

// Define a simple User model to encapsulate user data
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? referralCode;
  final String? referredBy;
  final int coinBalance;
  final int totalEarned;
  final int totalWithdrawn;
  final List<String> activeDays;
  final String? lastActiveDate;
  final Map<String, dynamic> dailyStats;
  final Map<String, dynamic>? withdrawalInfo;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.referralCode,
    this.referredBy,
    this.coinBalance = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    this.activeDays = const [],
    this.lastActiveDate,
    this.dailyStats = const {},
    this.withdrawalInfo,
  });

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? referralCode,
    String? referredBy,
    int? coinBalance,
    int? totalEarned,
    int? totalWithdrawn,
    List<String>? activeDays,
    String? lastActiveDate,
    Map<String, dynamic>? dailyStats,
    Map<String, dynamic>? withdrawalInfo,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      coinBalance: coinBalance ?? this.coinBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      activeDays: activeDays ?? this.activeDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyStats: dailyStats ?? this.dailyStats,
      withdrawalInfo: withdrawalInfo ?? this.withdrawalInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'coinBalance': coinBalance,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'activeDays': activeDays,
      'lastActiveDate': lastActiveDate,
      'dailyStats': dailyStats,
      'withdrawalInfo': withdrawalInfo,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
      coinBalance: json['coinBalance'] as int? ?? 0,
      totalEarned: json['totalEarned'] as int? ?? 0,
      totalWithdrawn: json['totalWithdrawn'] as int? ?? 0,
      activeDays: List<String>.from(json['activeDays'] ?? []),
      lastActiveDate: json['lastActiveDate'] as String?,
      dailyStats: Map<String, dynamic>.from(json['dailyStats'] ?? {}),
      withdrawalInfo: json['withdrawalInfo'] != null
          ? Map<String, dynamic>.from(json['withdrawalInfo'])
          : null,
    );
  }

  // Helper to get today's stats
  Map<String, dynamic> get todayStats {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    return Map<String, dynamic>.from(dailyStats[today] ?? {});
  }
}

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  List<Map<String, dynamic>> _referredUsers = [];
  List<Map<String, dynamic>> get referredUsers => _referredUsers;

  // Referral related data
  String? _referralCode;
  String? get referralCode => _referralCode;

  // Local state for daily limits
  Map<String, dynamic> _localDailyStats = {};
  Map<String, dynamic> get localDailyStats => _localDailyStats;
  int _localWritesCount = 0;
  int _localReadsCount = 0;
  int get readsCount => _localReadsCount;
  int get writesCount => _localWritesCount;
  String _lastSyncDate = '';
  LocalTransactionRepository? _transactionRepo;

  final ConfigProvider? configProvider;
  late SharedPreferences sharedPreferences;

  UserProvider({this.configProvider}) {
    _initSharedPrefs();
  }

  Future<void> _initSharedPrefs() async {
    sharedPreferences = await SharedPreferences.getInstance();
    _transactionRepo = LocalTransactionRepository(sharedPreferences);
    await _loadLocalData(); // Load local data on startup
  }

  Future<void> loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final lastFetchDate = sharedPreferences.getString(kLastFetchDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastFetchDate != today) {
      await fetchUserData(user.uid, forceRefresh: true);
      await sharedPreferences.setString(kLastFetchDateKey, today);
    } else {
      await fetchUserData(user.uid);
    }
  }

  Future<void> fetchUserData(String uid, {bool forceRefresh = false}) async {
    final String? cachedUser = sharedPreferences.getString('$kUserPrefix$uid');
    if (!forceRefresh && cachedUser != null) {
      final userData = json.decode(cachedUser);
      _currentUser = AppUser.fromJson(userData);
      _referralCode = _currentUser?.referralCode;
      notifyListeners();
    } else {
      // In local storage mode, create a new user if none exists
      if (_currentUser == null) {
        _currentUser = AppUser(
          uid: uid,
          email: FirebaseAuth.instance.currentUser?.email,
          displayName: FirebaseAuth.instance.currentUser?.displayName,
          photoURL: FirebaseAuth.instance.currentUser?.photoURL,
        );
        await saveCurrentUser();
      }
    }

    // Load referred users from local storage
    final String? referredUsersJson = sharedPreferences.getString(
      'referred_users_$uid',
    );
    if (referredUsersJson != null) {
      _referredUsers = List<Map<String, dynamic>>.from(
        json.decode(referredUsersJson),
      );
    }

    notifyListeners();
  }

  Future<void> saveCurrentUser() async {
    if (_currentUser != null) {
      await sharedPreferences.setString(
        '$kUserPrefix${_currentUser!.uid}',
        json.encode(_currentUser!.toJson()),
      );
    }
  }

  Future<void> saveWithdrawalInfo(Map<String, dynamic> withdrawalInfo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    _currentUser = _currentUser!.copyWith(withdrawalInfo: withdrawalInfo);
    await saveCurrentUser();
    notifyListeners();
  }

  void clearUserData() {
    _currentUser = null;
    _referralCode = null;
    _referredUsers = [];
    _localDailyStats = {};
    _localWritesCount = 0;
    _localReadsCount = 0;
    _lastSyncDate = '';

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      sharedPreferences.remove('$kUserPrefix$currentUid');
      sharedPreferences.remove('referred_users_$currentUid');
    }
    sharedPreferences.remove(kDailyStatsKey);
    sharedPreferences.remove(kLocalWritesCountKey);
    sharedPreferences.remove(kLocalReadsCountKey);
    sharedPreferences.remove(kLastSyncDateKey);

    notifyListeners();
  }

  Future<void> redeemReferralCode(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in.");
    if (_currentUser == null) throw Exception("User data not loaded.");

    // Check if the user has already redeemed a code
    if (_currentUser!.referredBy != null &&
        _currentUser!.referredBy!.isNotEmpty) {
      throw Exception("You have already redeemed a referral code.");
    }

    // Get all users from local storage to find referrer
    final allUserKeys = sharedPreferences.getKeys().where(
      (key) => key.startsWith(kUserPrefix),
    );
    String? referrerId;
    AppUser? referrer;

    for (final key in allUserKeys) {
      final userData = json.decode(sharedPreferences.getString(key) ?? '{}');
      if (userData['referralCode'] == code) {
        referrer = AppUser.fromJson(userData);
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
      coinBalance: _currentUser!.coinBalance + refereeBonus,
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
      json.decode(sharedPreferences.getString(referralsKey) ?? '[]'),
    );
    referrals.add(referral);
    await sharedPreferences.setString(referralsKey, json.encode(referrals));

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (_currentUser!.lastActiveDate == today) return;

    // Update active days for current user
    List<String> activeDays = List<String>.from(_currentUser!.activeDays);
    if (!activeDays.contains(today)) {
      activeDays.add(today);
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
          json.decode(sharedPreferences.getString(referralsKey) ?? '[]'),
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
              final referrerJson = sharedPreferences.getString(referrerKey);

              if (referrerJson != null) {
                final referrerData = json.decode(referrerJson);
                final referrer = AppUser.fromJson(referrerData);

                final int referrerBonus =
                    configProvider?.getConfig(
                      'rewards.referrerBonus',
                      defaultValue: 500,
                    ) ??
                    500;

                // Update referrer's balance
                final updatedReferrer = referrer.copyWith(
                  coinBalance: referrer.coinBalance + referrerBonus,
                  totalEarned: referrer.totalEarned + referrerBonus,
                );
                await sharedPreferences.setString(
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
            await sharedPreferences.setString(
              referralsKey,
              json.encode(referrals),
            );
          }
        }
      }

      notifyListeners();
    }
  }

  Future<void> _loadLocalData() async {
    final String today = DateTime.now().toIso8601String().substring(0, 10);

    _lastSyncDate = sharedPreferences.getString(kLastSyncDateKey) ?? '';
    final String? dailyStatsJson = sharedPreferences.getString(kDailyStatsKey);
    final String? localWritesCount = sharedPreferences.getString(
      kLocalWritesCountKey,
    );
    final String? localReadsCount = sharedPreferences.getString(
      kLocalReadsCountKey,
    );

    if (dailyStatsJson != null) {
      _localDailyStats = jsonDecode(dailyStatsJson) as Map<String, dynamic>;
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
    await sharedPreferences.setString(
      kDailyStatsKey,
      jsonEncode(_localDailyStats),
    );
    await sharedPreferences.setString(
      kLocalWritesCountKey,
      _localWritesCount.toString(),
    );
    await sharedPreferences.setString(
      kLocalReadsCountKey,
      _localReadsCount.toString(),
    );
    await sharedPreferences.setString(kLastSyncDateKey, _lastSyncDate);
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String lastActiveDate = _currentUser!.lastActiveDate ?? '';
    final Map<String, dynamic> todayStats =
        _currentUser!.dailyStats[today] ?? {};
    final bool dailyRewardClaimed = todayStats['dailyRewardClaimed'] ?? false;

    if (dailyRewardClaimed || lastActiveDate == today) {
      throw Exception(
        "Daily reward already claimed today or user not active on a new day.",
      );
    }

    // Update local daily stats
    _localDailyStats[today] = {
      ...(_localDailyStats[today] ?? {}),
      'dailyRewardClaimed': true,
    };
    incrementWritesCount();

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[today] = {
      ...(updatedDailyStats[today] ?? {}),
      'dailyRewardClaimed': true,
    };

    List<String> activeDays = List<String>.from(_currentUser!.activeDays);
    if (!activeDays.contains(today)) {
      activeDays.add(today);
    }

    _currentUser = _currentUser!.copyWith(
      coinBalance: _currentUser!.coinBalance + dailyRewardAmount,
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
      metadata: {'date': today},
    );

    notifyListeners();
  }

  Future<void> recordAdWatch(int adRewardAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final int dailyAdLimit =
        configProvider?.getConfig('dailyAdLimit', defaultValue: 10) ?? 10;
    final int adsWatchedToday =
        _currentUser!.dailyStats[today]?['adsWatched'] ?? 0;

    if (adsWatchedToday >= dailyAdLimit) {
      throw Exception("Daily ad watch limit reached.");
    }

    // Update local daily stats
    _localDailyStats[today] = {
      ...(_localDailyStats[today] ?? {}),
      'adsWatched': adsWatchedToday + 1,
    };
    incrementWritesCount();

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[today] = {
      ...(updatedDailyStats[today] ?? {}),
      'adsWatched': adsWatchedToday + 1,
    };

    _currentUser = _currentUser!.copyWith(
      coinBalance: _currentUser!.coinBalance + adRewardAmount,
      totalEarned: _currentUser!.totalEarned + adRewardAmount,
      dailyStats: updatedDailyStats,
    );
    await saveCurrentUser();

    // Create transaction record
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'earning',
      subType: 'ad',
      amount: adRewardAmount,
      metadata: {'date': today, 'adCount': adsWatchedToday + 1},
    );

    notifyListeners();
  }

  Future<void> spinAndEarnCoins(int amount, int dailySpinLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final Map<String, dynamic> todayStats =
        _currentUser!.dailyStats[today] ?? {};
    final int spinsUsedToday = todayStats['spinsUsed'] ?? 0;

    if (spinsUsedToday >= dailySpinLimit) {
      throw Exception("Daily spin limit reached.");
    }

    // Update local daily stats
    _localDailyStats[today] = {
      ...(_localDailyStats[today] ?? {}),
      'spinsUsed': spinsUsedToday + 1,
    };
    incrementWritesCount();

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[today] = {
      ...(updatedDailyStats[today] ?? {}),
      'spinsUsed': spinsUsedToday + 1,
    };

    _currentUser = _currentUser!.copyWith(
      coinBalance: _currentUser!.coinBalance + amount,
      totalEarned: _currentUser!.totalEarned + amount,
      dailyStats: updatedDailyStats,
    );
    await saveCurrentUser();

    // Create transaction record
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'earning',
      subType: 'spin',
      amount: amount,
      metadata: {'date': today, 'spinCount': spinsUsedToday + 1},
    );

    notifyListeners();
  }

  Future<void> playTicTacToeAndEarnCoins(int tictactoeRewardAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final Map<String, dynamic> todayStats =
        _currentUser!.dailyStats[today] ?? {};
    final int tictactoeGamesToday = todayStats['tictactoeGames'] ?? 0;

    // Update local daily stats
    _localDailyStats[today] = {
      ...(_localDailyStats[today] ?? {}),
      'tictactoeGames': tictactoeGamesToday + 1,
    };
    incrementWritesCount();

    // Update user data
    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[today] = {
      ...(updatedDailyStats[today] ?? {}),
      'tictactoeGames': tictactoeGamesToday + 1,
    };

    _currentUser = _currentUser!.copyWith(
      coinBalance: _currentUser!.coinBalance + tictactoeRewardAmount,
      totalEarned: _currentUser!.totalEarned + tictactoeRewardAmount,
      dailyStats: updatedDailyStats,
    );
    await saveCurrentUser();

    // Create transaction record
    await _transactionRepo?.addTransaction(
      userId: user.uid,
      type: 'earning',
      subType: 'tictactoe',
      amount: tictactoeRewardAmount,
      metadata: {'date': today, 'gameCount': tictactoeGamesToday + 1},
    );

    notifyListeners();
  }

  Future<void> requestWithdrawal(
    int amount,
    String method,
    Map<String, dynamic> details,
    int minWithdrawalCoins,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentUser == null) {
      throw Exception("User not found");
    }

    final int currentBalance = _currentUser!.coinBalance;

    if (amount < minWithdrawalCoins) {
      throw Exception(
        "Minimum withdrawal amount is $minWithdrawalCoins coins.",
      );
    }

    if (amount > currentBalance) {
      throw Exception("Insufficient coin balance for withdrawal.");
    }

    // Update local coin balance
    _currentUser = AppUser(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      photoURL: _currentUser!.photoURL,
      referralCode: _currentUser!.referralCode,
      referredBy: _currentUser!.referredBy,
      coinBalance: currentBalance - amount,
      totalEarned: _currentUser!.totalEarned,
      totalWithdrawn: _currentUser!.totalWithdrawn + amount,
      activeDays: _currentUser!.activeDays,
      lastActiveDate: _currentUser!.lastActiveDate,
      dailyStats: _currentUser!.dailyStats,
      withdrawalInfo: _currentUser!.withdrawalInfo,
    );

    // Save updated user data to SharedPreferences
    await sharedPreferences.setString(
      'user_data_${user.uid}',
      jsonEncode(_currentUser!.toJson()),
    );

    // Add withdrawal transaction to local storage
    await LocalTransactionRepository(sharedPreferences).addTransaction(
      userId: user.uid,
      type: 'withdrawal',
      subType: method == 'UPI' ? 'upi' : 'bank',
      amount: -amount, // Negative for withdrawal
      metadata: {'method': method, 'details': details},
    );
    notifyListeners();
  }

  Future<void> runDailyReconciliation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUser == null) return;

    final String userId = user.uid;
    final int localBalance = _currentUser!.coinBalance;
    final int localTotalWithdrawn = _currentUser!.totalWithdrawn;

    // Get transactions from local storage
    final transactions = _transactionRepo?.getTransactions(userId: userId);
    if (transactions == null) return;

    // Calculate balance from transactions
    int calculatedBalance = 0;
    int calculatedWithdrawn = 0;

    for (var transaction in transactions) {
      final int amount = transaction['amount'] ?? 0;
      final String type = transaction['type'] ?? '';

      if (type == 'earning') {
        calculatedBalance += amount;
      } else if (type == 'withdrawal') {
        calculatedBalance += amount; // Amount is negative for withdrawals
        calculatedWithdrawn += -amount;
      }
    }

    // Update user data if there's a mismatch
    if (calculatedBalance != localBalance ||
        calculatedWithdrawn != localTotalWithdrawn) {
      _currentUser = _currentUser!.copyWith(
        coinBalance: calculatedBalance,
        totalWithdrawn: calculatedWithdrawn,
      );
      await saveCurrentUser();
      notifyListeners();
    }
  }
}
