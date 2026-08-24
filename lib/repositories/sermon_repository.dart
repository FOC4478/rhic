import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sermon_model.dart';

class SermonRepository {
  SermonRepository._();

  static final SermonRepository instance =
      SermonRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _sermons =>
          _firestore.collection('sermons');

  CollectionReference<Map<String, dynamic>>
      get _categories =>
          _firestore.collection('sermon_categories');

  // ============================================================
  // ALL PUBLISHED SERMONS
  // ============================================================

  Stream<List<SermonModel>> sermonsStream() {
    return _sermons
        .where(
          'isPublished',
          isEqualTo: true,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  SermonModel.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ============================================================
  // SERMONS BY CATEGORY
  // ============================================================

  Stream<List<SermonModel>> sermonsByCategory(
    String category,
  ) {
    Query<Map<String, dynamic>> query =
        _sermons.where(
      'isPublished',
      isEqualTo: true,
    );

    if (category != 'All') {
      query = query.where(
        'category',
        isEqualTo: category,
      );
    }

    return query
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  SermonModel.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Stream<List<SermonModel>> searchSermons(
    String search,
  ) {
    final keyword =
        search.trim().toLowerCase();

    if (keyword.isEmpty) {
      return sermonsStream();
    }

    return sermonsStream().map(
      (sermons) {
        return sermons.where(
          (sermon) {
            return sermon.title
                    .toLowerCase()
                    .contains(keyword) ||
                sermon.speaker
                    .toLowerCase()
                    .contains(keyword) ||
                sermon.category
                    .toLowerCase()
                    .contains(keyword);
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Stream<List<String>>
      categoriesStream() {
    return _categories
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) {
            final categories =
                snapshot.docs
                    .map(
                      (doc) =>
                          doc.data()['name']
                              ?.toString()
                              .trim() ??
                          '',
                    )
                    .where(
                      (name) =>
                          name.isNotEmpty,
                    )
                    .toList();

            return [
              'All',
              ...categories,
            ];
          },
        );
  }

  // ============================================================
  // ADMIN: CREATE CATEGORY
  // ============================================================

  Future<void> createCategory(
    String name,
  ) async {
    final cleaned =
        name.trim();

    if (cleaned.isEmpty ||
        cleaned.toLowerCase() == 'all') {
      return;
    }

    await _categories.add({
      'name': cleaned,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ADMIN: UPDATE CATEGORY
  // ============================================================

  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    final cleaned =
        name.trim();

    if (cleaned.isEmpty ||
        cleaned.toLowerCase() == 'all') {
      return;
    }

    await _categories
        .doc(categoryId)
        .update({
      'name': cleaned,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ADMIN: DELETE CATEGORY
  // ============================================================

  Future<void> deleteCategory(
    String categoryId,
  ) async {
    await _categories
        .doc(categoryId)
        .delete();
  }

  // ============================================================
  // ADMIN: CREATE SERMON
  // ============================================================

  Future<void> createSermon(
    SermonModel sermon,
  ) async {
    await _sermons.add(
      sermon.toFirestore(),
    );
  }

  // ============================================================
  // ADMIN: UPDATE SERMON
  // ============================================================

  Future<void> updateSermon(
    SermonModel sermon,
  ) async {
    await _sermons
        .doc(sermon.id)
        .update(
          sermon.toFirestore(),
        );
  }

  // ============================================================
  // ADMIN: DELETE SERMON
  // ============================================================

  Future<void> deleteSermon(
    String sermonId,
  ) async {
    await _sermons
        .doc(sermonId)
        .delete();
  }
}