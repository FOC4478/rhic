import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/cart_item_model.dart';
import '../models/payment_settings_model.dart';
import '../models/order_model.dart';

class PaymentRepository {
  PaymentRepository._();

  static final PaymentRepository instance =
      PaymentRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // BACKEND
  // ============================================================

  static const String backendBaseUrl =
      'http://localhost:3000';

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
  // GET FIREBASE ID TOKEN
  // ============================================================

  Future<String> _getIdToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in.',
      );
    }

    final token =
        await user.getIdToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate with the server.',
      );
    }

    return token;
  }

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
    // Store the B2 object key, never a URL.
    final orderItems = items.map((item) {
      return {
        'bookId': item.bookId,
        'title': item.title,
        'author': item.author,
        'coverObjectKey': item.coverObjectKey,
        'ebookObjectKey': item.ebookObjectKey,
        'price': item.price,
        'currency': item.currency.toUpperCase(),
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
  //
  // Approval is now handled by the backend.
  //
  // Flutter
  //    ↓
  // Backend payment controller
  //    ↓
  // Firestore approval
  //    ↓
  // Notification service
  //    ↓
  // Member notification
  //
  // ============================================================

  Future<void> approveOrder({
    required String orderId,
    required String adminId,
    String? adminNote,
  }) async {
    if (orderId.trim().isEmpty) {
      throw Exception(
        'Order ID is required.',
      );
    }

    if (adminId.trim().isEmpty) {
      throw Exception(
        'Admin account could not be identified.',
      );
    }

    try {
      final idToken =
          await _getIdToken();

      final response =
          await http.post(
        Uri.parse(
          '$backendBaseUrl/api/admin/payments/orders/approve',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $idToken',
        },
        body: jsonEncode({
          'orderId':
              orderId.trim(),
          'adminNote':
              adminNote?.trim() ?? '',
        }),
      );

      Map<String, dynamic> data = {};

      if (response.body.trim().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded
              is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {
          // Ignore invalid JSON and use
          // the HTTP status below.
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        return;
      }

      final message =
          data['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        throw Exception(
          message.trim(),
        );
      }

      throw Exception(
        'Unable to approve order.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to approve order.',
      );
    }
  }

  // ============================================================
  // REJECT SHOP ORDER
  // ============================================================
  //
  // Rejection is also handled by the backend so that
  // admin payment actions use the same secure flow.
  //
  // ============================================================

  Future<void> rejectOrder({
    required String orderId,
    required String adminId,
    String? adminNote,
  }) async {
    if (orderId.trim().isEmpty) {
      throw Exception(
        'Order ID is required.',
      );
    }

    if (adminId.trim().isEmpty) {
      throw Exception(
        'Admin account could not be identified.',
      );
    }

    try {
      final idToken =
          await _getIdToken();

      final response =
          await http.post(
        Uri.parse(
          '$backendBaseUrl/api/admin/payments/orders/reject',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $idToken',
        },
        body: jsonEncode({
          'orderId':
              orderId.trim(),
          'adminNote':
              adminNote?.trim() ?? '',
        }),
      );

      Map<String, dynamic> data = {};

      if (response.body.trim().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded
              is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {
          // Ignore invalid JSON and use
          // the HTTP status below.
        }
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        return;
      }

      final message =
          data['message'];

      if (message is String &&
          message.trim().isNotEmpty) {
        throw Exception(
          message.trim(),
        );
      }

      throw Exception(
        'Unable to reject order.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'Unable to reject order.',
      );
    }
  }
}