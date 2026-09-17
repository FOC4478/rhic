import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMemberModel {
  final String id;
  final String uid;
  final String name;
  final String photoObjectKey;
  final Timestamp? joinedAt;

  const CommunityMemberModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.photoObjectKey,
    required this.joinedAt,
  });

  factory CommunityMemberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return CommunityMemberModel(
      id: snapshot.id,
      uid: data['uid']?.toString() ?? snapshot.id,
      name: data['name']?.toString() ?? 'RHIC Member',
      photoObjectKey:
          data['photoObjectKey']?.toString() ?? '',
      joinedAt: data['joinedAt'] is Timestamp
          ? data['joinedAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid.trim(),
      'name': name.trim(),
      'photoObjectKey': photoObjectKey.trim(),
      'joinedAt':
          joinedAt ?? FieldValue.serverTimestamp(),
    };
  }
}