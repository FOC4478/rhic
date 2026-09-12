import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSettingsModel {
  final String id;

  final String paymentType;
  final String currency;

  final String bankName;
  final String accountName;
  final String accountNumber;

  final String instructions;

  final bool isActive;

  final DateTime? updatedAt;
  final String? updatedBy;

  const PaymentSettingsModel({
    required this.id,
    required this.paymentType,
    required this.currency,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.instructions,
    required this.isActive,
    this.updatedAt,
    this.updatedBy,
  });

  factory PaymentSettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PaymentSettingsModel(
      id: doc.id,

      paymentType:
          data['paymentType']?.toString() ?? '',

      currency:
          data['currency']?.toString() ?? 'NGN',

      bankName:
          data['bankName']?.toString() ?? '',

      accountName:
          data['accountName']?.toString() ?? '',

      accountNumber:
          data['accountNumber']?.toString() ?? '',

      instructions:
          data['instructions']?.toString() ?? '',

      isActive:
          data['isActive'] == true,

      updatedAt:
          data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp)
                  .toDate()
              : null,

      updatedBy:
          data['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'paymentType': paymentType,
      'currency': currency,
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'instructions': instructions,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  PaymentSettingsModel copyWith({
    String? id,
    String? paymentType,
    String? currency,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? instructions,
    bool? isActive,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PaymentSettingsModel(
      id: id ?? this.id,
      paymentType:
          paymentType ?? this.paymentType,
      currency:
          currency ?? this.currency,
      bankName:
          bankName ?? this.bankName,
      accountName:
          accountName ?? this.accountName,
      accountNumber:
          accountNumber ?? this.accountNumber,
      instructions:
          instructions ?? this.instructions,
      isActive:
          isActive ?? this.isActive,
      updatedAt:
          updatedAt ?? this.updatedAt,
      updatedBy:
          updatedBy ?? this.updatedBy,
    );
  }
}