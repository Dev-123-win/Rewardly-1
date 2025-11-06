import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class LocalTransactionRepository {
  static const String _transactionsKey = 'local_transactions';
  final SharedPreferences _prefs;

  LocalTransactionRepository(this._prefs);

  // Get all transactions
  List<Map<String, dynamic>> getTransactions({String? userId}) {
    final String? transactionsJson = _prefs.getString(_transactionsKey);
    if (transactionsJson == null) return [];

    List<Map<String, dynamic>> transactions = List<Map<String, dynamic>>.from(
      json.decode(transactionsJson),
    );

    if (userId != null) {
      transactions = transactions.where((t) => t['userId'] == userId).toList();
    }

    return transactions;
  }

  List<Transaction> getAllTransactions() {
    final String? transactionsJson = _prefs.getString(_transactionsKey);
    if (transactionsJson == null) return [];

    List<dynamic> jsonList = json.decode(transactionsJson);
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }

  // Add a new transaction
  Future<void> addTransaction({
    required String userId,
    required String type,
    required String subType,
    required int amount,
    Map<String, dynamic>? metadata,
  }) async {
    final transactions = getAllTransactions();

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      subType: subType,
      amount: amount,
      timestamp: DateTime.now(),
      status: 'completed',
      metadata: metadata,
    );

    transactions.add(newTransaction);

    // Save updated list
    await _prefs.setString(
      _transactionsKey,
      json.encode(transactions.map((t) => t.toJson()).toList()),
    );
  }

  // Get transactions filtered by type
  List<Transaction> getTransactionsByType(String type) {
    return getAllTransactions()
        .where((transaction) => transaction.type == type)
        .toList();
  }

  // Get user's current balance
  int getUserBalance(String userId) {
    return getAllTransactions()
        .where((t) => t.userId == userId)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Clear all transactions (for testing/debugging)
  Future<void> clearAllTransactions() async {
    await _prefs.remove(_transactionsKey);
  }
}
