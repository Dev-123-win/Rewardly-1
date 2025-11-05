import 'package:cloud_firestore/cloud_firestore.dart';
import '../cache/cache_manager.dart';
import 'write_queue.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final CacheManager _cache;
  final WriteQueue _writeQueue;

  UserRepository(this._firestore, this._cache, this._writeQueue);

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    // Try cache first
    final cachedData = _cache.getCachedUserData();
    if (cachedData != null && !_cache.needsSync()) {
      return cachedData;
    }

    // If cache miss or needs sync, fetch from Firestore
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null) {
        await _cache.cacheUserData(data);
      }
      return data;
    } catch (e) {
      // On network error, return cached data if available
      return cachedData;
    }
  }

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    // Update cache immediately
    final cachedData = _cache.getCachedUserData();
    if (cachedData != null) {
      cachedData.addAll(updates);
      await _cache.cacheUserData(cachedData);
    }

    // Queue write to Firestore
    _writeQueue.addWrite(
      collection: 'users',
      documentId: userId,
      data: updates,
      merge: true,
    );
  }

  Future<void> updateUserCoins(String userId, int amount) async {
    final cachedData = _cache.getCachedUserData();
    if (cachedData != null) {
      final currentCoins = cachedData['coins'] as int? ?? 0;
      cachedData['coins'] = currentCoins + amount;
      await _cache.cacheUserData(cachedData);
    }

    _writeQueue.addWrite(
      collection: 'users',
      documentId: userId,
      data: {
        'coins': FieldValue.increment(amount),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  Future<bool> validateDailyReward(String userId) async {
    final cachedData = _cache.getCachedUserData();
    if (cachedData != null) {
      final lastReward = cachedData['lastDailyReward'] as int?;
      if (lastReward != null) {
        final lastRewardDate = DateTime.fromMillisecondsSinceEpoch(lastReward);
        final today = DateTime.now();
        return !lastRewardDate.isAtSameMomentAs(
          DateTime(today.year, today.month, today.day),
        );
      }
    }
    return true;
  }

  Future<void> recordDailyReward(String userId, int amount) async {
    final today = DateTime.now();
    final timestamp = DateTime(
      today.year,
      today.month,
      today.day,
    ).millisecondsSinceEpoch;

    await updateUserData(userId, {'lastDailyReward': timestamp});

    await updateUserCoins(userId, amount);
  }
}
