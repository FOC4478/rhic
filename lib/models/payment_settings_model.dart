import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSettingsModel {
  final String id;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String instructions;
  final bool isActive;
  final DateTime? updatedAt;

  const PaymentSettingsModel({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.instructions,
    required this.isActive,
    this.updatedAt,
  });

  factory PaymentSettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PaymentSettingsModel(
      id: doc.id,
      bankName: data['bankName']?.toString() ?? '',
      accountName: data['accountName']?.toString() ?? '',
      accountNumber: data['accountNumber']?.toString() ?? '',
      instructions: data['instructions']?.toString() ?? '',
      isActive: data['isActive'] == true,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}