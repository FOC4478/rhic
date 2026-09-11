
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item_model.dart';
import '../models/payment_settings_model.dart';

class PaymentRepository {
  PaymentRepository._();

  static final PaymentRepository instance =
      PaymentRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // PAYMENT SETTINGS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _paymentSettings =>
          _firestore.collection(
            'payment_settings',
          );

  // ============================================================
  // SHOP ORDERS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _orders =>
          _firestore.collection(
            'book_orders',
          );

  // ============================================================
  // ACTIVE PAYMENT SETTINGS
  // ============================================================

  Stream<PaymentSettingsModel?>
      paymentSettingsStream() {
    return _paymentSettings
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .snapshots()
        .map(
          (snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            }

            return PaymentSettingsModel
                .fromFirestore(
              snapshot.docs.first,
            );
          },
        );
  }

  // ============================================================
  // CREATE BOOK ORDER
  // ============================================================

  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double total,
    required String currency,
    required String paymentReference,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception(
        'User account could not be identified.',
      );
    }

    if (items.isEmpty) {
      throw Exception(
        'Your cart is empty.',
      );
    }

    if (paymentReference
        .trim()
        .isEmpty) {
      throw Exception(
        'Please enter your payment reference.',
      );
    }

    final orderRef =
        _orders.doc();

    final orderItems =
        items.map(
      (item) {
        return {
          'bookId': item.bookId,
          'title': item.title,
          'author': item.author,

          // Kept for order history/display.
          // This is the stored cover reference,
          // not used for B2 ebook security.
          'coverUrl': item.coverObjectKey,

          'price': item.price,
          'currency': item.currency,
          'quantity': item.quantity,
        };
      },
    ).toList();

    await orderRef.set({
      'userId': userId,

      'items': orderItems,

      'total': total,

      'currency': currency,

      // ========================================================
      // PAYMENT
      // ========================================================

      'status': 'pending',

      'paymentMethod':
          'bank_transfer',

      'paymentReference':
          paymentReference.trim(),

      // ========================================================
      // ADMIN VERIFICATION
      // ========================================================

      'adminNote': '',

      'verifiedBy': null,

      'verifiedAt': null,

      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }
}

