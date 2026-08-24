import 'package:cloud_firestore/cloud_firestore.dart';

class SermonModel {
  final String id;

  final String title;
  final String description;
  final String speaker;

  final String category;

  final String imageUrl;

  final String videoUrl;
  final String audioUrl;
  final String ebookUrl;

  final String date;
  final String duration;

  final bool isPublished;

  final Timestamp? createdAt;

  const SermonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.speaker,
    required this.category,
    required this.imageUrl,
    required this.videoUrl,
    required this.audioUrl,
    required this.ebookUrl,
    required this.date,
    required this.duration,
    required this.isPublished,
    required this.createdAt,
  });

  factory SermonModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SermonModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      speaker: data['speaker']?.toString() ?? '',
      category: data['category']?.toString() ?? 'General',
      imageUrl: data['imageUrl']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      audioUrl: data['audioUrl']?.toString() ?? '',
      ebookUrl: data['ebookUrl']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '',
      isPublished: data['isPublished'] == true,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'speaker': speaker,
      'category': category,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'ebookUrl': ebookUrl,
      'date': date,
      'duration': duration,
      'isPublished': isPublished,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  bool get hasVideo => videoUrl.trim().isNotEmpty;

  bool get hasAudio => audioUrl.trim().isNotEmpty;

  bool get hasEbook => ebookUrl.trim().isNotEmpty;
}