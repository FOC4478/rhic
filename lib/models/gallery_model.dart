import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imageObjectKey;
  final bool isPublished;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String createdBy;

  const GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageObjectKey,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory GalleryItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return GalleryItem(
      id: snapshot.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageObjectKey:
          data['imageObjectKey']?.toString() ?? '',
      isPublished: data['isPublished'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
      createdBy: data['createdBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageObjectKey': imageObjectKey,
      'isPublished': isPublished,
      'createdBy': createdBy,
      'createdAt':
          createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt':
          updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  GalleryItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageObjectKey,
    bool? isPublished,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
  }) {
    return GalleryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageObjectKey:
          imageObjectKey ?? this.imageObjectKey,
      isPublished:
          isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}