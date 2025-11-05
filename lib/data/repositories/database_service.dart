import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class DatabaseService {
  final FirebaseFirestore _firestore;

  DatabaseService(this._firestore);

  // Collection References
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get transactions => _firestore.collection('transactions');
  CollectionReference get referrals => _firestore.collection('referrals');
  CollectionReference get withdrawals => _firestore.collection('withdrawals');

  // User Methods
  Future<void> createUser(String uid, Map<String, dynamic> userData) {
    return users.doc(uid).set(userData);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return users.doc(uid).update(data);
  }

  Future<DocumentSnapshot> getUser(String uid) {
    return users.doc(uid).get();
  }

  Stream<User?> userStream(String uid) {
    return users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = doc.id;
      return User.fromJson(data);
    });
  }

  // Transaction Methods
  Future<void> addTransaction({
    required String userId,
    required String type,
    required String subType,
    required int amount,
    required String status,
    Map<String, dynamic>? metadata,
  }) {
    return transactions.add({
      'userId': userId,
      'type': type,
      'subType': subType,
      'amount': amount,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }

  // Referral Methods
  Future<QuerySnapshot> getReferralByCode(String code) {
    return users.where('referralCode', isEqualTo: code).limit(1).get();
  }

  Future<void> createReferral({
    required String referrerId,
    required String refereeId,
    required int refereeBonus,
  }) {
    return referrals.add({
      'referrerId': referrerId,
      'refereeId': refereeId,
      'refereeActiveDays': 0,
      'referrerRewarded': false,
      'refereeRewarded': true,
      'refereeBonus': refereeBonus,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });
  }

  // Withdrawal Methods
  Future<void> requestWithdrawal({
    required String userId,
    required int amount,
    required String method,
    required Map<String, dynamic> details,
  }) {
    return withdrawals.add({
      'userId': userId,
      'amount': amount,
      'method': method,
      'details': details,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  // Batch Write Methods
  Future<void> executeBatchWrites(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();

    for (var op in operations) {
      switch (op['type']) {
        case 'user_update':
          batch.update(users.doc(op['userId']), op['data']);
          break;
        case 'transaction':
          batch.set(transactions.doc(), op['data']);
          break;
        case 'referral':
          batch.set(referrals.doc(), op['data']);
          break;
        case 'withdrawal':
          batch.set(withdrawals.doc(), op['data']);
          break;
      }
    }

    await batch.commit();
  }

  // Daily Stats Methods
  Future<void> updateDailyStats(String uid, Map<String, dynamic> stats) {
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    return users.doc(uid).update({
      'dailyStats.$today': stats,
      'lastActiveDate': today,
    });
  }
}
