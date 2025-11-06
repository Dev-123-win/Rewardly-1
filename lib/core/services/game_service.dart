import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../data/repositories/local_transaction_repository.dart';

class GameService {
  static Future<void> handleGameEarnings({
    required UserProvider userProvider,
    required int amount,
    required String gameType,
    required Map<String, dynamic> metadata,
  }) async {
    if (amount <= 0 || userProvider.currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final transactionRepo = LocalTransactionRepository(prefs);
    final currentUser = userProvider.currentUser!;

    // Create transaction record
    await transactionRepo.addTransaction(
      userId: currentUser.uid,
      type: 'earning',
      subType: gameType,
      amount: amount,
      metadata: {
        ...metadata,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      },
    );

    // Clear local data and reload it to ensure consistency
    userProvider.clearUserData();
    await userProvider.loadUser();
  }

  static Future<void> handleAdReward({
    required UserProvider userProvider,
    required int amount,
    required String source,
  }) async {
    if (amount <= 0 || userProvider.currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final transactionRepo = LocalTransactionRepository(prefs);
    final currentUser = userProvider.currentUser!;

    // Create transaction record
    await transactionRepo.addTransaction(
      userId: currentUser.uid,
      type: 'earning',
      subType: 'ad_reward',
      amount: amount,
      metadata: {
        'source': source,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      },
    );

    // Clear local data and reload it to ensure consistency
    userProvider.clearUserData();
    await userProvider.loadUser();
  }
}
