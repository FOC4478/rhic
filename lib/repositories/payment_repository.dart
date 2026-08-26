import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item_model.dart';
import '../models/payment_settings_model.dart';

class PaymentRepository {
  PaymentRepository._();

  static final PaymentRepository instance =
      PaymentRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _paymentSettings =>
          _firestore.collection('payment_settings');

  CollectionReference<Map<String, dynamic>>
      get _orders =>
          _firestore.collection('orders');

  // ============================================================
  // PAYMENT SETTINGS
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
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      return PaymentSettingsModel
          .fromFirestore(snapshot.docs.first);
    });
  }

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<String> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double total,
    required String currency,
    required String paymentReference,
  }) async {
    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final orderRef = _orders.doc();

    final orderItems = items.map((item) {
      return {
        'bookId': item.bookId,
        'title': item.title,
        'author': item.author,
        'coverUrl': item.coverUrl,
        'price': item.price,
        'currency': item.currency,
        'quantity': item.quantity,
      };
    }).toList();

    await orderRef.set({
      'userId': userId,
      'items': orderItems,
      'total': total,
      'currency': currency,

      // Payment state
      'status': 'pending',
      'paymentMethod': 'bank_transfer',
      'paymentReference':
          paymentReference.trim(),

      // Admin verification fields
      'adminNote': '',
      'verifiedBy': null,
      'verifiedAt': null,

      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }
}