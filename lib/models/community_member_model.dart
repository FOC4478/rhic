import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMemberModel {
  final String uid;
  final String name;
  final String photoUrl;
  final Timestamp? joinedAt;

  const CommunityMemberModel({
    required this.uid,
    required this.name,
    required this.photoUrl,
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
      name: data['name']?.toString() ??
          data['displayName']?.toString() ??
          'RHIC Member',
      photoUrl: data['photoUrl']?.toString() ??
          data['photoURL']?.toString() ??
          '',
      joinedAt: data['joinedAt'] as Timestamp?,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'joinedAt': joinedAt,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CommunityMemberModel copyWith({
    String? uid,
    String? name,
    String? photoUrl,
    Timestamp? joinedAt,
  }) {
    return CommunityMemberModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}