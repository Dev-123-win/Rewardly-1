import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/local_transaction_repository.dart';

class GameService {
  static Future<void> handleGameEarnings({
    required int amount,
    required String gameType,
    required Map<String, dynamic> metadata,
  }) async {
    if (amount <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final transactionRepo = LocalTransactionRepository(prefs);
    const String userId = 'local_user'; // Using a static user ID

    // Create transaction record
    await transactionRepo.addTransaction(
      userId: userId,
      type: 'earning',
      subType: gameType,
      amount: amount,
      metadata: {
        ...metadata,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      },
    );
  }

  static Future<void> handleAdReward({
    required int amount,
    required String source,
  }) async {
    if (amount <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final transactionRepo = LocalTransactionRepository(prefs);
    const String userId = 'local_user'; // Using a static user ID

    // Create transaction record
    await transactionRepo.addTransaction(
      userId: userId,
      type: 'earning',
      subType: 'ad_reward',
      amount: amount,
      metadata: {
        'source': source,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      },
    );
  }
}
