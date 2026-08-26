import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_model.dart';

class ShopRepository {
  ShopRepository._();

  static final ShopRepository instance =
      ShopRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _books =>
          _firestore.collection('books');

  // ============================================================
  // PUBLISHED BOOKS
  // ============================================================

  Stream<List<BookModel>> booksStream() {
    return _books
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
          (snapshot) => snapshot.docs
              .map(BookModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // FEATURED BOOKS
  // ============================================================

  Stream<List<BookModel>> featuredBooksStream() {
    return _books
        .where(
          'isPublished',
          isEqualTo: true,
        )
        .where(
          'isFeatured',
          isEqualTo: true,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(BookModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // ONE BOOK
  // ============================================================

  Future<BookModel?> getBook(
    String bookId,
  ) async {
    final doc = await _books.doc(bookId).get();

    if (!doc.exists) {
      return null;
    }

    return BookModel.fromFirestore(doc);
  }

  // ============================================================
  // ADMIN - ALL BOOKS
  // ============================================================

  Stream<List<BookModel>> adminBooksStream() {
    return _books
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(BookModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // ADMIN - CREATE
  // ============================================================

  Future<String> createBook({
    required String title,
    required String author,
    required String description,
    required String category,
    required String coverUrl,
    required String ebookUrl,
    required double price,
    required String currency,
    required bool isPublished,
    required bool isFeatured,
  }) async {
    final doc = _books.doc();

    await doc.set({
      'title': title.trim(),
      'author': author.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'coverUrl': coverUrl.trim(),
      'ebookUrl': ebookUrl.trim(),
      'price': price,
      'currency': currency,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // ============================================================
  // ADMIN - UPDATE
  // ============================================================

  Future<void> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String description,
    required String category,
    required String coverUrl,
    required String ebookUrl,
    required double price,
    required String currency,
    required bool isPublished,
    required bool isFeatured,
  }) async {
    await _books.doc(bookId).update({
      'title': title.trim(),
      'author': author.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'coverUrl': coverUrl.trim(),
      'ebookUrl': ebookUrl.trim(),
      'price': price,
      'currency': currency,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // ADMIN - DELETE
  // ============================================================

  Future<void> deleteBook(
    String bookId,
  ) async {
    await _books.doc(bookId).delete();
  }

  // ============================================================
  // ADMIN - PUBLISH
  // ============================================================

  Future<void> setPublished({
    required String bookId,
    required bool published,
  }) async {
    await _books.doc(bookId).update({
      'isPublished': published,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}