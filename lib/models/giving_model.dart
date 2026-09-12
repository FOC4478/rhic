import 'package:cloud_firestore/cloud_firestore.dart';

class GivingModel {
  final String id;

  final String userId;
  final String userName;

  final String type;
  final String currency;

  final double amount;

  final String status;
  final String paymentMethod;

  final DateTime? createdAt;
  final DateTime? verifiedAt;

  final String? verifiedBy;
  final String? adminNote;

  const GivingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.currency,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.adminNote,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory GivingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return GivingModel(
      id: doc.id,

      userId: data['userId']?.toString() ?? '',

      userName:
          data['userName']?.toString() ?? 'RHIC Member',

      type: data['type']?.toString() ?? '',

      currency:
          data['currency']?.toString() ?? 'NGN',

      amount: data['amount'] is num
          ? (data['amount'] as num).toDouble()
          : double.tryParse(
                data['amount']?.toString() ?? '',
              ) ??
              0,

      status:
          data['status']?.toString() ?? 'pending',

      paymentMethod:
          data['paymentMethod']?.toString() ??
              'bank_transfer',

      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,

      verifiedAt: data['verifiedAt'] is Timestamp
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,

      verifiedBy:
          data['verifiedBy']?.toString(),

      adminNote:
          data['adminNote']?.toString(),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'currency': currency,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,

      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),

      'verifiedAt': verifiedAt == null
          ? null
          : Timestamp.fromDate(verifiedAt!),

      'verifiedBy': verifiedBy,
      'adminNote': adminNote,
    };
  }
}