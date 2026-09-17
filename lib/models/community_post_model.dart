import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostModel {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String authorPhotoObjectKey;
  final String content;
  final List<String> imageObjectKeys;
  final int likeCount;
  final int commentCount;
  final bool isPinned;
  final bool isEdited;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityPostModel({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoObjectKey,
    required this.content,
    required this.imageObjectKeys,
    required this.likeCount,
    required this.commentCount,
    required this.isPinned,
    required this.isEdited,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityPostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    final rawImages = data['imageObjectKeys'];

    return CommunityPostModel(
      id: snapshot.id,
      groupId: data['groupId']?.toString() ?? '',
      authorId: data['authorId']?.toString() ?? '',
      authorName:
          data['authorName']?.toString() ?? 'RHIC Member',
      authorPhotoObjectKey:
          data['authorPhotoObjectKey']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      imageObjectKeys: rawImages is List
          ? rawImages
              .map((e) => e.toString())
              .where(
                (e) => e.trim().isNotEmpty,
              )
              .toList()
          : const [],
      likeCount: _toInt(data['likeCount']),
      commentCount: _toInt(data['commentCount']),
      isPinned: data['isPinned'] == true,
      isEdited: data['isEdited'] == true,
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
      'groupId': groupId.trim(),
      'authorId': authorId.trim(),
      'authorName': authorName.trim(),
      'authorPhotoObjectKey':
          authorPhotoObjectKey.trim(),
      'content': content.trim(),
      'imageObjectKeys': imageObjectKeys
          .where(
            (key) => key.trim().isNotEmpty,
          )
          .map((key) => key.trim())
          .toList(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isPinned': isPinned,
      'isEdited': isEdited,
      'createdAt':
          createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt':
          updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  CommunityPostModel copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? authorName,
    String? authorPhotoObjectKey,
    String? content,
    List<String>? imageObjectKeys,
    int? likeCount,
    int? commentCount,
    bool? isPinned,
    bool? isEdited,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhotoObjectKey:
          authorPhotoObjectKey ??
              this.authorPhotoObjectKey,
      content: content ?? this.content,
      imageObjectKeys:
          imageObjectKeys ?? this.imageObjectKeys,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}