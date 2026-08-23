import 'package:cloud_firestore/cloud_firestore.dart';

enum ResourceType {
  video,
  audio,
  book,
}

class ResourceModel {
  final String id;

  final String title;
  final String description;

  final ResourceType type;

  final String imageUrl;
  final String resourceUrl;

  final String? author;
  final String? duration;

  final bool isPublished;

  final DateTime? createdAt;

  const ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.imageUrl,
    required this.resourceUrl,
    this.author,
    this.duration,
    required this.isPublished,
    this.createdAt,
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory ResourceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ResourceModel(
      id: doc.id,

      title: data['title']?.toString() ?? '',

      description:
          data['description']?.toString() ?? '',

      type: _resourceTypeFromString(
        data['type']?.toString() ?? 'video',
      ),

      imageUrl:
          data['imageUrl']?.toString() ?? '',

      resourceUrl:
          data['resourceUrl']?.toString() ?? '',

      author:
          data['author']?.toString(),

      duration:
          data['duration']?.toString(),

      isPublished:
          data['isPublished'] == true,

      createdAt:
          (data['createdAt'] as Timestamp?)
              ?.toDate(),
    );
  }

  // ============================================================
  // TYPE CONVERTER
  // ============================================================

  static ResourceType _resourceTypeFromString(
    String type,
  ) {
    switch (type.toLowerCase()) {
      case 'audio':
        return ResourceType.audio;

      case 'book':
        return ResourceType.book;

      case 'video':
      default:
        return ResourceType.video;
    }
  }

  // ============================================================
  // TYPE STRING
  // ============================================================

  String get typeName {
    switch (type) {
      case ResourceType.video:
        return 'video';

      case ResourceType.audio:
        return 'audio';

      case ResourceType.book:
        return 'book';
    }
  }
}