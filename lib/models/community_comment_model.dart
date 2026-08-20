import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityCommentModel {
  final String id;
  final String postId;

  final String authorId;
  final String authorName;
  final String authorPhotoUrl;

  final String content;

  final Timestamp? createdAt;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.content,
    required this.createdAt,
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
      authorPhotoUrl:
          data['authorPhotoUrl']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'createdAt': createdAt,
    };
  }
}