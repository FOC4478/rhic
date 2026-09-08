import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class SermonUploadResult {
  final String downloadUrl;
  final String storagePath;

  const SermonUploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });
}

class SermonUploadService {
  SermonUploadService._();

  static final SermonUploadService instance =
      SermonUploadService._();

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  Future<SermonUploadResult> uploadVideo({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      bytes: bytes,
      fileName: fileName,
      folder: 'sermons/videos',
      contentType: _videoContentType(fileName),
    );
  }

  Future<SermonUploadResult> uploadAudio({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      bytes: bytes,
      fileName: fileName,
      folder: 'sermons/audio',
      contentType: _audioContentType(fileName),
    );
  }

  Future<SermonUploadResult> uploadEbook({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _upload(
      bytes: bytes,
      fileName: fileName,
      folder: 'sermons/ebooks',
      contentType: 'application/pdf',
    );
  }

  Future<SermonUploadResult> _upload({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String contentType,
  }) async {
    final timestamp =
        DateTime.now().millisecondsSinceEpoch;

    final safeName = fileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    final path =
        '$folder/${timestamp}_$safeName';

    final reference =
        _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: contentType,
    );

    await reference.putData(
      bytes,
      metadata,
    );

    final url =
        await reference.getDownloadURL();

    return SermonUploadResult(
      downloadUrl: url,
      storagePath: path,
    );
  }

  Future<void> deleteFile(
    String storagePath,
  ) async {
    if (storagePath.trim().isEmpty) {
      return;
    }

    try {
      await _storage
          .ref()
          .child(storagePath)
          .delete();
    } catch (_) {
      // File may already have been deleted.
    }
  }

  String _videoContentType(
    String fileName,
  ) {
    final extension =
        fileName.toLowerCase();

    if (extension.endsWith('.webm')) {
      return 'video/webm';
    }

    if (extension.endsWith('.mov')) {
      return 'video/quicktime';
    }

    return 'video/mp4';
  }

  String _audioContentType(
    String fileName,
  ) {
    final extension =
        fileName.toLowerCase();

    if (extension.endsWith('.wav')) {
      return 'audio/wav';
    }

    if (extension.endsWith('.m4a')) {
      return 'audio/mp4';
    }

    if (extension.endsWith('.aac')) {
      return 'audio/aac';
    }

    return 'audio/mpeg';
  }
}