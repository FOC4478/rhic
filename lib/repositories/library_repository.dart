import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sermon_model.dart';

class LibraryRepository {
  LibraryRepository._();

  static final LibraryRepository instance =
      LibraryRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // USER DOWNLOADS
  // users/{userId}/downloads/{sermonId}
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _downloadsCollection(
    String userId,
  ) {
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
    required SermonModel sermon,
    required String downloadType,
  }) async {
    await _downloadsCollection(userId)
        .doc(sermon.id)
        .set(
      {
        // ======================================================
        // SERMON ID
        // ======================================================

        'sermonId': sermon.id,

        // ======================================================
        // BASIC SERMON INFORMATION
        // ======================================================

        'title': sermon.title,
        'description': sermon.description,
        'speaker': sermon.speaker,
        'category': sermon.category,

        // ======================================================
        // IMAGE
        // ======================================================

        'imageUrl': sermon.imageUrl,
        'imageStoragePath': sermon.imageStoragePath,

        // ======================================================
        // RESOURCE URLS
        // ======================================================

        'videoUrl': sermon.videoUrl,
        'audioUrl': sermon.audioUrl,
        'ebookUrl': sermon.ebookUrl,

        // ======================================================
        // STORAGE PATHS
        // ======================================================

        'videoStoragePath': sermon.videoStoragePath,
        'audioStoragePath': sermon.audioStoragePath,
        'ebookStoragePath': sermon.ebookStoragePath,

        // ======================================================
        // ADDITIONAL INFORMATION
        // ======================================================

        'date': sermon.date,
        'duration': sermon.duration,

        // ======================================================
        // DOWNLOAD TYPE
        //
        // video
        // audio
        // ebook
        // ======================================================

        'downloadType': downloadType,

        // ======================================================
        // DOWNLOAD TIMESTAMP
        // ======================================================

        'downloadedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // ALL DOWNLOADS
  // ============================================================

  Stream<List<SermonModel>> downloadsStream(
    String userId,
  ) {
    return _downloadsCollection(userId)
        .orderBy(
          'downloadedAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(_sermonFromDownload)
                .toList();
          },
        );
  }

  // ============================================================
  // VIDEO DOWNLOADS
  // ============================================================

  Stream<List<SermonModel>> videoDownloadsStream(
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
            return snapshot.docs
                .map(_sermonFromDownload)
                .toList();
          },
        );
  }

  // ============================================================
  // AUDIO DOWNLOADS
  // ============================================================

  Stream<List<SermonModel>> audioDownloadsStream(
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
            return snapshot.docs
                .map(_sermonFromDownload)
                .toList();
          },
        );
  }

  // ============================================================
  // CONVERT DOWNLOAD DOCUMENT → SERMON MODEL
  // ============================================================

  SermonModel _sermonFromDownload(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return SermonModel(
      // ========================================================
      // BASIC INFORMATION
      // ========================================================

      id: data['sermonId']?.toString() ?? doc.id,

      title:
          data['title']?.toString() ?? '',

      description:
          data['description']?.toString() ?? '',

      speaker:
          data['speaker']?.toString() ?? '',

      category:
          data['category']?.toString() ?? 'General',

      // ========================================================
      // IMAGE
      // ========================================================

      imageUrl:
          data['imageUrl']?.toString() ?? '',

      imageStoragePath:
          data['imageStoragePath']?.toString() ?? '',

      // ========================================================
      // RESOURCE URLS
      // ========================================================

      videoUrl:
          data['videoUrl']?.toString() ?? '',

      audioUrl:
          data['audioUrl']?.toString() ?? '',

      ebookUrl:
          data['ebookUrl']?.toString() ?? '',

      // ========================================================
      // STORAGE PATHS
      // ========================================================

      videoStoragePath:
          data['videoStoragePath']?.toString() ?? '',

      audioStoragePath:
          data['audioStoragePath']?.toString() ?? '',

      ebookStoragePath:
          data['ebookStoragePath']?.toString() ?? '',

      // ========================================================
      // ADDITIONAL INFORMATION
      // ========================================================

      date:
          data['date']?.toString() ?? '',

      duration:
          data['duration']?.toString() ?? '',

      // ========================================================
      // PUBLISHED STATUS
      // ========================================================
      //
      // If it exists in the user's library, it is available
      // to that user.
      // ========================================================

      isPublished: true,

      // ========================================================
      // CREATED / DOWNLOADED AT
      // ========================================================

      createdAt:
          data['downloadedAt'] is Timestamp
              ? data['downloadedAt'] as Timestamp
              : null,
    );
  }

  // ============================================================
  // REMOVE DOWNLOAD
  // ============================================================

  Future<void> removeDownload({
    required String userId,
    required String sermonId,
  }) async {
    await _downloadsCollection(userId)
        .doc(sermonId)
        .delete();
  }

  // ============================================================
  // CHECK IF DOWNLOADED
  // ============================================================

  Stream<bool> isDownloaded({
    required String userId,
    required String sermonId,
  }) {
    return _downloadsCollection(userId)
        .doc(sermonId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists,
        );
  }

  // ============================================================
  // GET ONE DOWNLOADED SERMON
  // ============================================================

  Future<SermonModel?> getDownloadedSermon({
    required String userId,
    required String sermonId,
  }) async {
    final doc = await _downloadsCollection(userId)
        .doc(sermonId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return _sermonFromDownload(doc);
  }
}