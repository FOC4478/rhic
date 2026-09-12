import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/giving_model.dart';

class GivingRepository {
  GivingRepository._();

  static final GivingRepository instance =
      GivingRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _givingCollection =>
          _firestore.collection('givings');

  // ============================================================
  // CREATE GIVING
  // ============================================================

  Future<String> createGiving({
    required GivingModel giving,
  }) async {
    try {
      if (giving.userId.trim().isEmpty) {
        throw Exception(
          'User account could not be identified.',
        );
      }

      if (giving.type.trim().isEmpty) {
        throw Exception(
          'Please select a giving type.',
        );
      }

      if (giving.currency.trim().isEmpty) {
        throw Exception(
          'Please select a currency.',
        );
      }

      if (giving.amount <= 0) {
        throw Exception(
          'Giving amount must be greater than zero.',
        );
      }

      final doc =
          _givingCollection.doc();

      await doc.set({
        'userId': giving.userId,
        'userName': giving.userName,

        'type': giving.type,
        'currency': giving.currency,

        'amount': giving.amount,

        // Every new giving starts as pending.
        'status': 'pending',

        'paymentMethod':
            giving.paymentMethod,

        'createdAt':
            FieldValue.serverTimestamp(),

        // These are controlled by the admin.
        'verifiedAt': null,
        'verifiedBy': null,
        'adminNote': null,
      });

      return doc.id;
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception:')) {
        rethrow;
      }

      throw Exception(
        'Unable to create giving record.',
      );
    }
  }

  // ============================================================
  // USER GIVING HISTORY
  // ============================================================

  Stream<List<GivingModel>> userGivingStream({
    required String userId,
  }) {
    if (userId.trim().isEmpty) {
      return Stream.value(
        <GivingModel>[],
      );
    }

    return _givingCollection
        .where(
          'userId',
          isEqualTo: userId,
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
                  GivingModel.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ============================================================
  // SINGLE GIVING
  // ============================================================

  Stream<GivingModel?> givingStream(
    String givingId,
  ) {
    return _givingCollection
        .doc(givingId)
        .snapshots()
        .map(
          (snapshot) {
            if (!snapshot.exists) {
              return null;
            }

            return GivingModel.fromFirestore(
              snapshot,
            );
          },
        );
  }

  // ============================================================
  // ADMIN - ALL GIVINGS
  // ============================================================

  Stream<List<GivingModel>> adminGivingStream() {
    return _givingCollection
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  GivingModel.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ============================================================
  // ADMIN - PENDING GIVINGS
  // ============================================================

  Stream<List<GivingModel>>
      adminPendingGivingStream() {
    return _givingCollection
        .where(
          'status',
          isEqualTo: 'pending',
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
                  GivingModel.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ============================================================
  // ADMIN - APPROVE GIVING
  // ============================================================

  Future<void> approveGiving({
    required String givingId,
    required String adminId,
    String? adminNote,
  }) async {
    if (givingId.trim().isEmpty) {
      throw Exception(
        'Giving record could not be identified.',
      );
    }

    if (adminId.trim().isEmpty) {
      throw Exception(
        'Administrator could not be identified.',
      );
    }

    try {
      await _givingCollection
          .doc(givingId)
          .update({
        'status': 'approved',
        'verifiedBy': adminId,
        'verifiedAt':
            FieldValue.serverTimestamp(),
        'adminNote':
            adminNote?.trim().isEmpty == true
                ? null
                : adminNote?.trim(),
      });
    } catch (e) {
      throw Exception(
        'Unable to approve giving record.',
      );
    }
  }

  // ============================================================
  // ADMIN - REJECT GIVING
  // ============================================================

  Future<void> rejectGiving({
    required String givingId,
    required String adminId,
    String? adminNote,
  }) async {
    if (givingId.trim().isEmpty) {
      throw Exception(
        'Giving record could not be identified.',
      );
    }

    if (adminId.trim().isEmpty) {
      throw Exception(
        'Administrator could not be identified.',
      );
    }

    try {
      await _givingCollection
          .doc(givingId)
          .update({
        'status': 'rejected',
        'verifiedBy': adminId,
        'verifiedAt':
            FieldValue.serverTimestamp(),
        'adminNote':
            adminNote?.trim().isEmpty == true
                ? null
                : adminNote?.trim(),
      });
    } catch (e) {
      throw Exception(
        'Unable to reject giving record.',
      );
    }
  }

  // ============================================================
  // ADMIN - GET SINGLE GIVING
  // ============================================================

  Future<GivingModel?> getGiving(
    String givingId,
  ) async {
    try {
      final snapshot =
          await _givingCollection
              .doc(givingId)
              .get();

      if (!snapshot.exists) {
        return null;
      }

      return GivingModel.fromFirestore(
        snapshot,
      );
    } catch (e) {
      throw Exception(
        'Unable to load giving record.',
      );
    }
  }
}