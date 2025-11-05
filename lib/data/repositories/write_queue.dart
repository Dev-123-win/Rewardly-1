import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class WriteQueue {
  final List<_WriteOperation> _pendingWrites = [];
  Timer? _batchTimer;
  final FirebaseFirestore _firestore;

  WriteQueue(this._firestore);

  void addWrite({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) {
    _pendingWrites.add(
      _WriteOperation(
        collection: collection,
        documentId: documentId,
        data: data,
        merge: merge,
      ),
    );
    _scheduleBatch();
  }

  void _scheduleBatch() {
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(seconds: 30), () => _processBatch());
  }

  Future<void> _processBatch() async {
    if (_pendingWrites.isEmpty) return;

    final batch = _firestore.batch();
    final operations = List<_WriteOperation>.from(_pendingWrites);
    _pendingWrites.clear();

    for (final op in operations) {
      final doc = _firestore.collection(op.collection).doc(op.documentId);
      batch.set(doc, op.data, SetOptions(merge: op.merge));
    }

    try {
      await batch.commit();
    } catch (e) {
      // If batch fails, add operations back to queue
      _pendingWrites.addAll(operations);
      _scheduleBatch();
    }
  }

  Future<void> forceSync() async {
    _batchTimer?.cancel();
    await _processBatch();
  }

  void dispose() {
    _batchTimer?.cancel();
  }
}

class _WriteOperation {
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final bool merge;

  _WriteOperation({
    required this.collection,
    required this.documentId,
    required this.data,
    this.merge = true,
  });
}
