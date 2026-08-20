import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final bool isPublished;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory GalleryItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return GalleryItem(
      id: snapshot.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      isPublished: data['isPublished'] == true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isPublished': isPublished,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}