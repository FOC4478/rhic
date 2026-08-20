import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;

  final String content;

  final List<String> imageUrls;

  final int likeCount;
  final int commentCount;

  final bool isEdited;
  final bool isPinned;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityPostModel({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.content,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.isEdited,
    required this.isPinned,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory CommunityPostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return CommunityPostModel(
      id: snapshot.id,
      groupId: data['groupId']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? '',
      authorPhotoUrl:
          data['authorPhotoUrl']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      imageUrls: List<String>.from(
        data['imageUrls'] ?? const [],
      ),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      commentCount:
          (data['commentCount'] as num?)?.toInt() ?? 0,
      isEdited: data['isEdited'] == true,
      isPinned: data['isPinned'] == true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isEdited': isEdited,
      'isPinned': isPinned,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}