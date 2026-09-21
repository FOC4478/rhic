import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_model.dart';
import '../models/cart_item_model.dart';

class CartRepository {
  CartRepository._();

  static final CartRepository instance =
      CartRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _cartCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart');
  }

  // ============================================================
  // CART STREAM
  // ============================================================

  Stream<List<CartItemModel>> cartStream(
    String userId,
  ) {
    return _cartCollection(userId)
        .orderBy(
          'addedAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CartItemModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ============================================================
  // ADD BOOK
  // ============================================================

  Future<void> addToCart({
    required String userId,
    required BookModel book,
  }) async {
    final ref = _cartCollection(userId).doc(book.id);

    final existing = await ref.get();

    if (existing.exists) {
      final data = existing.data() ?? {};

      final currentQuantity =
          data['quantity'] is int
              ? data['quantity'] as int
              : int.tryParse(
                    data['quantity']?.toString() ?? '',
                  ) ??
                  1;

      await ref.update({
        'quantity': currentQuantity + 1,

        // Keep the private B2 cover object key current.
        'coverObjectKey': book.coverObjectKey,

        // Keep the private B2 ebook object key current.
        'ebookObjectKey': book.ebookObjectKey,

        // Keep the current book information.
        'title': book.title,
        'author': book.author,
        'price': book.price,
        'currency': book.currency,
      });

      return;
    }

    await ref.set({
      'bookId': book.id,

      'title': book.title,

      'author': book.author,

      // ========================================================
      // BACKBLAZE B2 OBJECT KEYS
      // ========================================================

      // Private B2 object key for the cover.
      // This is NOT a URL.
      'coverObjectKey': book.coverObjectKey,

      // Private B2 object key for the ebook.
      // This is NOT a URL.
      'ebookObjectKey': book.ebookObjectKey,

      // ========================================================
      // BOOK PRICE
      // ========================================================

      'price': book.price,

      'currency': book.currency,

      'quantity': 1,

      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // CHANGE QUANTITY
  // ============================================================

  Future<void> updateQuantity({
    required String userId,
    required String bookId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(
        userId: userId,
        bookId: bookId,
      );
      return;
    }

    await _cartCollection(userId)
        .doc(bookId)
        .update({
      'quantity': quantity,
    });
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<void> removeFromCart({
    required String userId,
    required String bookId,
  }) async {
    await _cartCollection(userId)
        .doc(bookId)
        .delete();
  }

  // ============================================================
  // CLEAR CART
  // ============================================================

  Future<void> clearCart(
    String userId,
  ) async {
    final snapshot =
        await _cartCollection(userId).get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}