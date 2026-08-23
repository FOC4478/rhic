import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/teaching_model.dart';

class ResourceRepository {
  ResourceRepository._();

  static final ResourceRepository instance =
      ResourceRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _downloadsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('downloads');
  }

  // ============================================================
  // SAVE DOWNLOAD
  // ============================================================

  Future<void> saveDownload({
    required String userId,
    required TeachingModel teaching,
    required String downloadType,
  }) async {
    await _downloadsCollection(userId)
        .doc(teaching.id)
        .set(
      {
        'teachingId': teaching.id,
        'title': teaching.title,
        'description': teaching.description,
        'speaker': teaching.speaker,
        'category': teaching.category,
        'imageUrl': teaching.imageUrl,
        'audioUrl': teaching.audioUrl,
        'videoUrl': teaching.videoUrl,
        'date': teaching.date,
        'duration': teaching.duration,
        'downloadType': downloadType,
        'downloadedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // VIDEO DOWNLOADS STREAM
  // ============================================================

  Stream<List<TeachingModel>> videoDownloadsStream(
    String userId,
  ) {
    return _downloadsCollection(userId)
        .where(
          'downloadType',
          isEqualTo: 'video',
        )
        .orderBy(
          'downloadedAt',
          descending: true,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(
          (doc) {
            final data = doc.data();

            return TeachingModel(
              id: data['teachingId']?.toString() ?? doc.id,
              title: data['title']?.toString() ?? '',
              description:
                  data['description']?.toString() ?? '',
              speaker:
                  data['speaker']?.toString() ?? '',
              category:
                  data['category']?.toString() ?? '',
              imageUrl:
                  data['imageUrl']?.toString() ?? '',
              audioUrl:
                  data['audioUrl']?.toString() ?? '',
              videoUrl:
                  data['videoUrl']?.toString() ?? '',
              date: data['date']?.toString() ?? '',
              duration:
                  data['duration']?.toString() ?? '',
              isPublished: true,
              createdAt: null,
            );
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // AUDIO DOWNLOADS STREAM
  // ============================================================

  Stream<List<TeachingModel>> audioDownloadsStream(
    String userId,
  ) {
    return _downloadsCollection(userId)
        .where(
          'downloadType',
          isEqualTo: 'audio',
        )
        .orderBy(
          'downloadedAt',
          descending: true,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(
          (doc) {
            final data = doc.data();

            return TeachingModel(
              id: data['teachingId']?.toString() ?? doc.id,
              title: data['title']?.toString() ?? '',
              description:
                  data['description']?.toString() ?? '',
              speaker:
                  data['speaker']?.toString() ?? '',
              category:
                  data['category']?.toString() ?? '',
              imageUrl:
                  data['imageUrl']?.toString() ?? '',
              audioUrl:
                  data['audioUrl']?.toString() ?? '',
              videoUrl:
                  data['videoUrl']?.toString() ?? '',
              date: data['date']?.toString() ?? '',
              duration:
                  data['duration']?.toString() ?? '',
              isPublished: true,
              createdAt: null,
            );
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // REMOVE DOWNLOAD
  // ============================================================

  Future<void> removeDownload({
    required String userId,
    required String teachingId,
  }) async {
    await _downloadsCollection(userId)
        .doc(teachingId)
        .delete();
  }

  // ============================================================
  // CHECK DOWNLOAD
  // ============================================================

  Stream<bool> isDownloaded({
    required String userId,
    required String teachingId,
  }) {
    return _downloadsCollection(userId)
        .doc(teachingId)
        .snapshots()
        .map(
      (snapshot) => snapshot.exists,
    );
  }
}