import 'package:cloud_firestore/cloud_firestore.dart';

class SermonModel {
  final String id;

  final String title;
  final String description;
  final String speaker;
  final String category;

  // ============================================================
  // BACKBLAZE B2 STORAGE
  // ============================================================

  final String imageStoragePath;

  /// B2 object key for the sermon video.
  final String videoStoragePath;

  /// B2 object key for the sermon audio.
  final String audioStoragePath;

  /// B2 object key for the sermon ebook.
  final String ebookStoragePath;


  final String imageUrl;
  final String videoUrl;
  final String audioUrl;
  final String ebookUrl;

  // ============================================================
  // SERMON INFORMATION
  // ============================================================

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

    required this.imageStoragePath,

    required this.videoStoragePath,
    required this.audioStoragePath,
    required this.ebookStoragePath,

    required this.imageUrl,

    required this.videoUrl,
    required this.audioUrl,
    required this.ebookUrl,

    required this.date,
    required this.duration,

    required this.isPublished,

    required this.createdAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

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

      // ========================================================
      // B2 STORAGE PATHS
      // ========================================================

      imageStoragePath:
          data['imageStoragePath']?.toString() ?? '',

      videoStoragePath:
          data['videoStoragePath']?.toString() ?? '',

      audioStoragePath:
          data['audioStoragePath']?.toString() ?? '',

      ebookStoragePath:
          data['ebookStoragePath']?.toString() ?? '',

      // ========================================================
      // LEGACY URLS
      // ========================================================

      imageUrl:
          data['imageUrl']?.toString() ?? '',

      videoUrl:
          data['videoUrl']?.toString() ?? '',

      audioUrl:
          data['audioUrl']?.toString() ?? '',

      ebookUrl:
          data['ebookUrl']?.toString() ?? '',

      // ========================================================
      // OTHER DATA
      // ========================================================

      date:
          data['date']?.toString() ?? '',

      duration:
          data['duration']?.toString() ?? '',

      isPublished:
          data['isPublished'] == true,

      createdAt:
          data['createdAt'] is Timestamp
              ? data['createdAt'] as Timestamp
              : null,
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

      // ========================================================
      // B2 STORAGE PATHS
      // ========================================================

      'imageStoragePath': imageStoragePath,
      'videoStoragePath': videoStoragePath,
      'audioStoragePath': audioStoragePath,
      'ebookStoragePath': ebookStoragePath,

      // ========================================================
      // LEGACY URLS
      // ========================================================

      // Kept temporarily for backwards compatibility.
      //
      // New B2 sermons should leave these empty.
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'ebookUrl': ebookUrl,

      // ========================================================
      // OTHER DATA
      // ========================================================

      'date': date,
      'duration': duration,

      'isPublished': isPublished,

      'createdAt':
          createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // ============================================================
  // MEDIA HELPERS
  // ============================================================

  /// Whether a B2 video exists.
  bool get hasVideo {
    return videoStoragePath.trim().isNotEmpty ||
        videoUrl.trim().isNotEmpty;
  }

  /// Whether a B2 audio file exists.
  bool get hasAudio {
    return audioStoragePath.trim().isNotEmpty ||
        audioUrl.trim().isNotEmpty;
  }

  /// Whether a B2 ebook exists.
  bool get hasEbook {
    return ebookStoragePath.trim().isNotEmpty ||
        ebookUrl.trim().isNotEmpty;
  }

  /// Whether a B2 cover image exists.
  bool get hasImage {
    return imageStoragePath.trim().isNotEmpty ||
        imageUrl.trim().isNotEmpty;
  }
}

