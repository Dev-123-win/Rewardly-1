import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user.dart';
import '../models/payment_method.dart'; // Added
class UserProviderNew with ChangeNotifier {
  User? _currentUser;

  UserProviderNew() {
    _init();
  }

  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _init() async {
    await loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('current_user');
    if (userData != null) {
      _currentUser = User.fromJson(json.decode(userData));
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('current_user', json.encode(_currentUser!.toJson()));
    } else {
      await prefs.remove('current_user');
    }
    notifyListeners();
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    _currentUser = null;
    notifyListeners();
  }

  // Example of updating user data
  Future<void> updateCoins(int amount) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(coins: _currentUser!.coins + amount);
      await saveCurrentUser();
    }
  }

  Future<void> recordGameReward({
    required String gameType,
    required int amount,
    int? dailyLimit, // Added dailyLimit parameter
  }) async {
    if (_currentUser != null) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final updatedDailyStats = Map<String, dynamic>.from(_currentUser!.dailyStats);

      updatedDailyStats.update(
        today,
        (value) => {
          ...value,
          'coinsEarned': (value['coinsEarned'] ?? 0) + amount,
          'gamesPlayed': (value['gamesPlayed'] ?? 0) + 1,
          if (gameType == 'dailyBonus') 'dailyBonusClaimed': true,
        },
        ifAbsent: () => {
          'coinsEarned': amount,
          'gamesPlayed': 1,
          if (gameType == 'dailyBonus') 'dailyBonusClaimed': true,
        },
      );

      _currentUser = _currentUser!.copyWith(
        coins: _currentUser!.coins + amount,
        totalEarned: _currentUser!.totalEarned + amount,
        dailyStats: updatedDailyStats,
      );
      await saveCurrentUser();
    }
  }

  Future<void> resetDailyStreak() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        dailyStreak: 0,
        lastStreakDate: null,
      );
      await saveCurrentUser();
    }
  }

  Future<void> incrementDailyStreak() async {
    if (_currentUser != null) {
      final now = DateTime.now();
      final lastStreakDate = _currentUser!.lastStreakDate;

      if (lastStreakDate == null ||
          now.difference(lastStreakDate).inDays > 1) {
        // Reset streak if more than one day has passed
        _currentUser = _currentUser!.copyWith(
          dailyStreak: 1,
          lastStreakDate: now,
        );
      } else if (now.difference(lastStreakDate).inDays == 1) {
        // Increment streak if it's the next day
        _currentUser = _currentUser!.copyWith(
          dailyStreak: _currentUser!.dailyStreak + 1,
          lastStreakDate: now,
        );
      } else if (now.difference(lastStreakDate).inDays == 0) {
        // Do nothing if already claimed today
      }
      await saveCurrentUser();
    }
  }


  Future<void> updatePaymentMethod(PaymentMethod method) async {
    if (_currentUser != null) {
      final updatedMethods = List<Map<String, dynamic>>.from(_currentUser!.paymentMethods);
      final index = updatedMethods.indexWhere((m) => m['type'] == method.type);

      if (index != -1) {
        updatedMethods[index] = method.toJson();
      } else {
        updatedMethods.add(method.toJson());
      }

      _currentUser = _currentUser!.copyWith(paymentMethods: updatedMethods);
      await saveCurrentUser();
    }
  }

  // Example of updating withdrawal info
  Future<void> updateWithdrawalInfo(Map<String, dynamic> info) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(withdrawalInfo: info);
      await saveCurrentUser();
    }
  }

  Future<void> saveWithdrawalInfo(Map<String, dynamic> info) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(withdrawalInfo: info);
      await saveCurrentUser();
    }
  }

  Future<void> requestWithdrawal({
    required int amount,
    required String method,
    required Map<String, dynamic> details,
    required int minWithdrawalCoins,
  }) async {
    if (_currentUser == null) {
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

    // For simplicity, we'll just update the user's balance and total withdrawn
    // In a real app, this would involve a backend call and transaction processing
    _currentUser = _currentUser!.copyWith(
      coins: _currentUser!.coins - amount,
      totalWithdrawn: _currentUser!.totalWithdrawn + amount,
      withdrawalInfo: details,
    );

    await saveCurrentUser();
    notifyListeners();
  }

  Future<void> recordAdWatch(int rewardAmount) async {
    if (_currentUser == null) return;

    final today = DateTime.now();
    final todayString = today.toIso8601String().substring(0, 10);
    final todayStats = _currentUser!.dailyStats[todayString] ?? {};
    final adsWatchedToday = todayStats['adsWatched'] ?? 0;

    Map<String, dynamic> updatedDailyStats = Map<String, dynamic>.from(
      _currentUser!.dailyStats,
    );
    updatedDailyStats[todayString] = {
      ...(updatedDailyStats[todayString] ?? {}),
      'adsWatched': adsWatchedToday + 1,
      'adCoins': (todayStats['adCoins'] ?? 0) + rewardAmount,
    };

    _currentUser = _currentUser!.copyWith(
      coins: _currentUser!.coins + rewardAmount,
      totalEarned: _currentUser!.totalEarned + rewardAmount,
      dailyStats: updatedDailyStats,
    );

    await saveCurrentUser();
    notifyListeners();
  }
}
