import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseService {
  SharedPreferences? _prefs;

  DatabaseService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String kUserPrefix = 'user_';
  static const String kTransactionPrefix = 'transaction_';
  static const String kReferralPrefix = 'referral_';
  static const String kWithdrawalPrefix = 'withdrawal_';

  // User Methods
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _prefs?.setString('$kUserPrefix$uid', json.encode(userData));
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final userJson = _prefs?.getString('$kUserPrefix$uid');
    if (userJson == null) return;

    final userData = json.decode(userJson) as Map<String, dynamic>;
    userData.addAll(data);
    await _prefs?.setString('$kUserPrefix$uid', json.encode(userData));
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final userJson = _prefs?.getString('$kUserPrefix$uid');
    if (userJson == null) return null;
    return json.decode(userJson) as Map<String, dynamic>;
  }

  Future<User?> getUserAsModel(String uid) async {
    final data = await getUser(uid);
    if (data == null) return null;
    data['uid'] = uid;
    return User.fromJson(data);
  }

  // Transaction Methods
  Future<void> addTransaction({
    required String userId,
    required String type,
    required String subType,
    required int amount,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
    final data = {
      'userId': userId,
      'type': type,
      'subType': subType,
      'amount': amount,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };
    await _prefs?.setString(
      '$kTransactionPrefix$transactionId',
      json.encode(data),
    );
  }

  // Referral Methods
  Future<Map<String, dynamic>?> getReferralByCode(String code) async {
    final allKeys = _prefs?.getKeys() ?? {};
    for (final key in allKeys) {
      if (key.startsWith(kUserPrefix)) {
        final userJson = _prefs?.getString(key);
        if (userJson != null) {
          final userData = json.decode(userJson);
          if (userData['referralCode'] == code) {
            return userData;
          }
        }
      }
    }
    return null;
  }

  Future<void> createReferral({
    required String referrerId,
    required String refereeId,
    required int refereeBonus,
  }) async {
    final referralId = DateTime.now().millisecondsSinceEpoch.toString();
    final data = {
      'referrerId': referrerId,
      'refereeId': refereeId,
      'refereeActiveDays': 0,
      'referrerRewarded': false,
      'refereeRewarded': true,
      'refereeBonus': refereeBonus,
      'createdAt': DateTime.now().toIso8601String(),
      'completedAt': null,
    };
    await _prefs?.setString('$kReferralPrefix$referralId', json.encode(data));
  }

  // Withdrawal Methods
  Future<void> requestWithdrawal({
    required String userId,
    required int amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    final withdrawalId = DateTime.now().millisecondsSinceEpoch.toString();
    final data = {
      'userId': userId,
      'amount': amount,
      'method': method,
      'details': details,
      'status': 'pending',
      'requestedAt': DateTime.now().toIso8601String(),
    };
    await _prefs?.setString(
      '$kWithdrawalPrefix$withdrawalId',
      json.encode(data),
    );
  }

  // Batch Write Methods
  Future<void> executeBatchWrites(List<Map<String, dynamic>> operations) async {
    for (var op in operations) {
      switch (op['type']) {
        case 'user_update':
          await updateUser(op['userId'], op['data']);
          break;
        case 'transaction':
          await addTransaction(
            userId: op['data']['userId'],
            type: op['data']['type'],
            subType: op['data']['subType'],
            amount: op['data']['amount'],
            status: op['data']['status'],
            metadata: op['data']['metadata'],
          );
          break;
        case 'referral':
          await createReferral(
            referrerId: op['data']['referrerId'],
            refereeId: op['data']['refereeId'],
            refereeBonus: op['data']['refereeBonus'],
          );
          break;
        case 'withdrawal':
          await requestWithdrawal(
            userId: op['data']['userId'],
            amount: op['data']['amount'],
            method: op['data']['method'],
            details: op['data']['details'],
          );
          break;
      }
    }
  }

  // Daily Stats Methods
  Future<void> updateDailyStats(String uid, Map<String, dynamic> stats) async {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final userJson = _prefs?.getString('$kUserPrefix$uid');
    if (userJson == null) return;

    final userData = json.decode(userJson) as Map<String, dynamic>;
    if (userData['dailyStats'] == null) {
      userData['dailyStats'] = {};
    }
    userData['dailyStats'][today] = stats;
    userData['lastActiveDate'] = today;

    await _prefs?.setString('$kUserPrefix$uid', json.encode(userData));
  }
}
