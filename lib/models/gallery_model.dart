import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryItem {
  final String id;
  final String imageUrl;
  final String caption;
  final String category;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GalleryItem({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.category,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  factory GalleryItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return GalleryItem(
      id: snapshot.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      category: data['category'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'caption': caption,
      'category': category,
      'isPublished': isPublished,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}