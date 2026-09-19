import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogService {
  ActivityLogService._();

  static final ActivityLogService instance =
      ActivityLogService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('activity_logs');

  Future<void> log({
    required String type,
    required String title,
    required String description,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _collection.add({
        'type': type,
        'title': title,
        'description': description,
        'userId': userId,
        'metadata': metadata ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stream({
    int limit = 10,
  }) {
    return _collection
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(limit)
        .snapshots();
  }

  Future<void> clearAll() async {
    final snapshot = await _collection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }
}