import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorPhotoObjectKey;
  final String content;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoObjectKey,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityCommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return CommunityCommentModel(
      id: snapshot.id,
      postId: data['postId']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorName:
          data['authorName']?.toString() ?? 'RHIC Member',
      authorPhotoObjectKey:
          data['authorPhotoObjectKey']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId.trim(),
      'authorId': authorId.trim(),
      'authorName': authorName.trim(),
      'authorPhotoObjectKey':
          authorPhotoObjectKey.trim(),
      'content': content.trim(),
      'createdAt':
          createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt':
          updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}