import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item_model.dart';
import '../models/payment_settings_model.dart';
import '../models/order_model.dart';

class PaymentRepository {
  PaymentRepository._();

  static final PaymentRepository instance =
      PaymentRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _paymentSettings =>
          _firestore.collection('payment_settings');

  CollectionReference<Map<String, dynamic>>
      get _orders =>
          _firestore.collection('book_orders');

  // ============================================================
  // PAYMENT DOCUMENT ID
  // ============================================================

  String paymentSettingsId({
    required String paymentType,
    required String currency,
  }) {
    return '${paymentType.trim().toLowerCase()}_'
        '${currency.trim().toUpperCase()}';
  }

  // ============================================================
  // GET PAYMENT SETTINGS
  // ============================================================

  Future<PaymentSettingsModel?>
      getPaymentSettings({
    required String paymentType,
    required String currency,
  }) async {
    final id = paymentSettingsId(
      paymentType: paymentType,
      currency: currency,
    );

    try {
      final snapshot =
          await _paymentSettings.doc(id).get();

      if (!snapshot.exists) {
        return null;
      }

      return PaymentSettingsModel.fromFirestore(
        snapshot,
      );
    } catch (e) {
      throw Exception(
        'Unable to load payment settings.',
      );
    }
  }

  // ============================================================
  // PAYMENT SETTINGS STREAM
  // ============================================================

  Stream<PaymentSettingsModel?>
      paymentSettingsStream({
    required String paymentType,
    required String currency,
  }) {
    final id = paymentSettingsId(
      paymentType: paymentType,
      currency: currency,
    );

    return _paymentSettings
        .doc(id)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return PaymentSettingsModel.fromFirestore(
        snapshot,
      );
    });
  }

  // ============================================================
  // ALL PAYMENT SETTINGS
  // ============================================================

  Stream<List<PaymentSettingsModel>>
      allPaymentSettingsStream() {
    return _paymentSettings
        .orderBy('paymentType')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            PaymentSettingsModel.fromFirestore,
          )
          .toList();
    });
  }

  // ============================================================
  // SAVE PAYMENT SETTINGS
  // ============================================================

  Future<void> savePaymentSettings({
    required String paymentType,
    required String currency,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String instructions,
    required bool isActive,
    required String adminId,
  }) async {
    if (bankName.trim().isEmpty) {
      throw Exception(
        'Please enter the bank name.',
      );
    }

    if (accountName.trim().isEmpty) {
      throw Exception(
        'Please enter the account name.',
      );
    }

    if (accountNumber.trim().isEmpty) {
      throw Exception(
        'Please enter the account number.',
      );
    }

    if (adminId.trim().isEmpty) {
      throw Exception(
        'Admin account could not be identified.',
      );
    }

    final normalizedType =
        paymentType.trim().toLowerCase();

    final normalizedCurrency =
        currency.trim().toUpperCase();

    final id = paymentSettingsId(
      paymentType: normalizedType,
      currency: normalizedCurrency,
    );

    try {
      await _paymentSettings.doc(id).set(
        {
          'paymentType': normalizedType,
          'currency': normalizedCurrency,
          'bankName': bankName.trim(),
          'accountName': accountName.trim(),
          'accountNumber': accountNumber.trim(),
          'instructions': instructions.trim(),
          'isActive': isActive,
          'updatedAt':
              FieldValue.serverTimestamp(),
          'updatedBy': adminId,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception(
        'Unable to save payment settings.',
      );
    }
  }

  // ============================================================
  // CREATE SHOP ORDER
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

    if (total <= 0) {
      throw Exception(
        'Invalid order total.',
      );
    }

    if (paymentReference.trim().isEmpty) {
      throw Exception(
        'Please enter your payment reference.',
      );
    }

    final normalizedCurrency =
        currency.trim().toUpperCase();

    final orderRef = _orders.doc();

    // IMPORTANT:
    // Use coverObjectKey, not coverUrl.
    final orderItems = items.map((item) {
      return {
        'bookId': item.bookId,
        'title': item.title,
        'author': item.author,
        'coverObjectKey':
            item.coverObjectKey,
        'price': item.price,
        'currency':
            item.currency.toUpperCase(),
        'quantity': item.quantity,
      };
    }).toList();

    await orderRef.set({
      'userId': userId,
      'items': orderItems,
      'total': total,
      'currency': normalizedCurrency,
      'status': 'pending',
      'paymentMethod': 'bank_transfer',
      'paymentReference':
          paymentReference.trim(),
      'adminNote': '',
      'verifiedBy': null,
      'verifiedAt': null,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }

  // ============================================================
  // ALL SHOP ORDERS
  // ============================================================

  Stream<List<OrderModel>>
      adminOrdersStream() {
    return _orders
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            OrderModel.fromFirestore,
          )
          .toList();
    });
  }

  // ============================================================
  // PENDING SHOP ORDERS
  // ============================================================

  Stream<List<OrderModel>>
      pendingOrdersStream() {
    return _orders
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            OrderModel.fromFirestore,
          )
          .toList();
    });
  }

  // ============================================================
  // APPROVE SHOP ORDER
  // ============================================================

  Future<void> approveOrder({
    required String orderId,
    required String adminId,
    String? adminNote,
  }) async {
    try {
      await _orders.doc(orderId).update({
        'status': 'approved',
        'verifiedBy': adminId,
        'verifiedAt':
            FieldValue.serverTimestamp(),
        'adminNote':
            adminNote?.trim().isEmpty == true
                ? ''
                : adminNote?.trim() ?? '',
      });
    } catch (e) {
      throw Exception(
        'Unable to approve order.',
      );
    }
  }

  // ============================================================
  // REJECT SHOP ORDER
  // ============================================================

  Future<void> rejectOrder({
    required String orderId,
    required String adminId,
    String? adminNote,
  }) async {
    try {
      await _orders.doc(orderId).update({
        'status': 'rejected',
        'verifiedBy': adminId,
        'verifiedAt':
            FieldValue.serverTimestamp(),
        'adminNote':
            adminNote?.trim().isEmpty == true
                ? ''
                : adminNote?.trim() ?? '',
      });
    } catch (e) {
      throw Exception(
        'Unable to reject order.',
      );
    }
  }
}