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
  // GIVING SETTINGS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _givingSettingsCollection =>
          _firestore.collection('giving_settings');

  // ============================================================
  // GET PAYMENT DETAILS
  // ============================================================

  Future<Map<String, dynamic>?> getPaymentDetails({
    required String currency,
  }) async {
    try {
      final snapshot =
          await _givingSettingsCollection
              .doc(currency)
              .get();

      if (!snapshot.exists) {
        return null;
      }

      return snapshot.data();
    } catch (e) {
      throw Exception(
        'Unable to load payment details.',
      );
    }
  }

  // ============================================================
  // PAYMENT DETAILS STREAM
  // ============================================================

  Stream<Map<String, dynamic>?> paymentDetailsStream({
    required String currency,
  }) {
    return _givingSettingsCollection
        .doc(currency)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return snapshot.data();
    });
  }

  // ============================================================
  // CREATE GIVING
  //
  // This will be used later when the user confirms
  // that they have made a transfer.
  // ============================================================

  Future<String> createGiving({
    required GivingModel giving,
  }) async {
    try {
      final doc =
          await _givingCollection.add(
        giving.toFirestore(),
      );

      return doc.id;
    } catch (e) {
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
}