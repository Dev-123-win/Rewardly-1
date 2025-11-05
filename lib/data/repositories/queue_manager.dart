import 'dart:async';

import '../repositories/database_service.dart';
import '../cache/cache_manager.dart';

class QueueManager {
  final DatabaseService _db;
  final CacheManager _cache;
  final List<Map<String, dynamic>> _writeQueue = [];
  Timer? _batchTimer;
  static const _batchDelay = Duration(minutes: 5);
  static const int _maxQueueSize = 100;

  QueueManager(this._db, this._cache);

  void queueWrite(Map<String, dynamic> operation) {
    _writeQueue.add(operation);

    // Update cache immediately for responsive UI
    if (operation['type'] == 'user_update') {
      final cachedData = _cache.getCachedUserData();
      if (cachedData != null) {
        cachedData.addAll(operation['data']);
        _cache.cacheUserData(cachedData);
      }
    }

    // Process queue if it's getting full
    if (_writeQueue.length >= _maxQueueSize) {
      _processBatch();
    } else {
      _scheduleBatch();
    }
  }

  void _scheduleBatch() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDelay, _processBatch);
  }

  Future<void> _processBatch() async {
    if (_writeQueue.isEmpty) return;

    final operations = List<Map<String, dynamic>>.from(_writeQueue);
    _writeQueue.clear();

    try {
      await _db.executeBatchWrites(operations);
    } catch (e) {
      // If batch fails, requeue operations
      _writeQueue.addAll(operations);
      _scheduleBatch();
      rethrow;
    }
  }

  Future<void> forceBatch() async {
    _batchTimer?.cancel();
    await _processBatch();
  }

  void dispose() {
    _batchTimer?.cancel();
  }
}
