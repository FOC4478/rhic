import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMemberModel {
  final String uid;
  final Timestamp? joinedAt;

  const CommunityMemberModel({
    required this.uid,
    required this.joinedAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory CommunityMemberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return CommunityMemberModel(
      uid: data['uid']?.toString() ?? snapshot.id,
      joinedAt: data['joinedAt'] as Timestamp?,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'joinedAt': joinedAt,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CommunityMemberModel copyWith({
    String? uid,
    Timestamp? joinedAt,
  }) {
    return CommunityMemberModel(
      uid: uid ?? this.uid,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}