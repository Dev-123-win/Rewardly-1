class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? referralCode;
  final String? referredBy;
  final int coins;
  final int totalEarned;
  final int totalWithdrawn;
  final List<String> activeDays;
  final DateTime? lastActiveDate;
  final Map<String, dynamic> dailyStats;
  final Map<String, dynamic>? withdrawalInfo;

  User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.referralCode,
    this.referredBy,
    this.coins = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    this.activeDays = const [],
    this.lastActiveDate,
    this.dailyStats = const {},
    this.withdrawalInfo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
      coins: json['coins'] as int? ?? 0,
      totalEarned: json['totalEarned'] as int? ?? 0,
      totalWithdrawn: json['totalWithdrawn'] as int? ?? 0,
      activeDays: List<String>.from(json['activeDays'] ?? []),
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'])
          : null,
      dailyStats: Map<String, dynamic>.from(json['dailyStats'] ?? {}),
      withdrawalInfo: json['withdrawalInfo'] != null
          ? Map<String, dynamic>.from(json['withdrawalInfo'])
          : null,
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
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'dailyStats': dailyStats,
      'withdrawalInfo': withdrawalInfo,
    };
  }

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
    Map<String, dynamic>? withdrawalInfo,
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
      withdrawalInfo: withdrawalInfo ?? this.withdrawalInfo,
    );
  }
}
