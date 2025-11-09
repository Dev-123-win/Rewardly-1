import 'package:flutter/foundation.dart';

@immutable
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String referralCode;
  final String? referredBy;
  final int coins;
  final int totalEarned;
  final int totalWithdrawn;
  final List<String> activeDays;
  final DateTime lastActiveDate;
  final Map<String, dynamic> dailyStats;
  final List<Map<String, dynamic>> paymentMethods; // Added
  final Map<String, dynamic>? withdrawalInfo; // Added
  final int dailyStreak; // Added
  final DateTime? lastStreakDate; // Added
  final List<Map<String, dynamic>> referredUsers; // Added

  const User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.referralCode,
    this.referredBy,
    this.coins = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    this.activeDays = const [],
    required this.lastActiveDate,
    this.dailyStats = const {},
    this.paymentMethods = const [], // Added
    this.withdrawalInfo, // Added
    this.dailyStreak = 0, // Added
    this.lastStreakDate, // Added
    this.referredUsers = const [], // Added
  });

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? referralCode,
    String? referredBy,
    int? coins,
    int? totalEarned,
    int? totalWithdrawn,
    List<String>? activeDays,
    DateTime? lastActiveDate,
    Map<String, dynamic>? dailyStats,
    List<Map<String, dynamic>>? paymentMethods, // Added
    Map<String, dynamic>? withdrawalInfo, // Added
    int? dailyStreak, // Added
    DateTime? lastStreakDate, // Added
    List<Map<String, dynamic>>? referredUsers, // Added
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      coins: coins ?? this.coins,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      activeDays: activeDays ?? this.activeDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyStats: dailyStats ?? this.dailyStats,
      paymentMethods: paymentMethods ?? this.paymentMethods, // Added
      withdrawalInfo: withdrawalInfo ?? this.withdrawalInfo, // Added
      dailyStreak: dailyStreak ?? this.dailyStreak, // Added
      lastStreakDate: lastStreakDate ?? this.lastStreakDate, // Added
      referredUsers: referredUsers ?? this.referredUsers, // Added
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      referralCode: json['referralCode'] as String,
      referredBy: json['referredBy'] as String?,
      coins: json['coins'] as int,
      totalEarned: json['totalEarned'] as int,
      totalWithdrawn: json['totalWithdrawn'] as int,
      activeDays: (json['activeDays'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
      dailyStats: json['dailyStats'] as Map<String, dynamic>,
      paymentMethods: (json['paymentMethods'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [], // Added
      withdrawalInfo: json['withdrawalInfo'] as Map<String, dynamic>?, // Added
      dailyStreak: json['dailyStreak'] as int? ?? 0, // Added
      lastStreakDate: json['lastStreakDate'] != null
          ? DateTime.parse(json['lastStreakDate'] as String)
          : null, // Added
      referredUsers: (json['referredUsers'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [], // Added
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
      'coins': coins,
      'totalEarned': totalEarned,
      'totalWithdrawn': totalWithdrawn,
      'activeDays': activeDays,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'dailyStats': dailyStats,
      'paymentMethods': paymentMethods, // Added
      'withdrawalInfo': withdrawalInfo, // Added
      'dailyStreak': dailyStreak, // Added
      'lastStreakDate': lastStreakDate?.toIso8601String(), // Added
      'referredUsers': referredUsers, // Added
    };
  }
}
