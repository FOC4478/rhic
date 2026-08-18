import 'package:cloud_firestore/cloud_firestore.dart';

class TeachingModel {
  final String id;
  final String title;
  final String description;
  final String speaker;
  final String category;
  final String imageUrl;
  final String audioUrl;
  final String videoUrl;
  final String date;
  final String duration;
  final bool isPublished;
  final Timestamp? createdAt;

  const TeachingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.speaker,
    required this.category,
    required this.imageUrl,
    required this.audioUrl,
    required this.videoUrl,
    required this.date,
    required this.duration,
    required this.isPublished,
    required this.createdAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory TeachingModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return TeachingModel(
      id: snapshot.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      speaker: data['speaker']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      audioUrl: data['audioUrl']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '',
      isPublished: data['isPublished'] == true,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'speaker': speaker,
      'category': category,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'date': date,
      'duration': duration,
      'isPublished': isPublished,
      'createdAt': createdAt,
    };
  }
}