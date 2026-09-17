import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class MediaUrlService {
  MediaUrlService._();

  static final MediaUrlService instance =
      MediaUrlService._();

  static const String baseUrl =
      'http://localhost:3000';

  // ============================================================
  // INTERNAL AUTH TOKEN
  // ============================================================

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Please sign in to access this media.',
      );
    }

    final idToken = await user.getIdToken(true);

    if (idToken == null || idToken.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate with the media server.',
      );
    }

    return idToken;
  }

  // ============================================================
  // GENERIC B2 OBJECT KEY DOWNLOAD URL
  // ============================================================

  Future<String> getDownloadUrl({
    required String storagePath,
  }) async {
    return _getSignedUrl(
      endpoint: '/download-url',
      objectKey: storagePath,
      emptyKeyMessage:
          'Media storage path is empty.',
      serverErrorMessage:
          'Media server did not return a download URL.',
    );
  }

  // ============================================================
  // COMMUNITY MEDIA
  // ============================================================
 

  Future<String> getCommunityMediaUrl({
    required String objectKey,
  }) async {
    return _getSignedUrl(
      endpoint: '/community-download-url',
      objectKey: objectKey,
      emptyKeyMessage:
          'A B2 community media object key is required.',
      serverErrorMessage:
          'The community media server did not return a download URL.',
    );
  }

  // ============================================================
  // EVENT FLYER
  // ============================================================

  Future<String> getEventDownloadUrl({
    required String storagePath,
  }) async {
    return _getSignedUrl(
      endpoint: '/event-download-url',
      objectKey: storagePath,
      emptyKeyMessage:
          'Event flyer storage path is empty.',
      serverErrorMessage:
          'Event media server did not return a download URL.',
    );
  }

  // ============================================================
  // GALLERY IMAGE
  // ============================================================

  Future<String> getGalleryDownloadUrl({
    required String storagePath,
  }) async {
    return _getSignedUrl(
      endpoint: '/gallery-download-url',
      objectKey: storagePath,
      emptyKeyMessage:
          'A B2 gallery image object key is required.',
      serverErrorMessage:
          'The gallery server did not return a download URL.',
    );
  }

  // ============================================================
  // INTERNAL SIGNED URL REQUEST
  // ============================================================

  Future<String> _getSignedUrl({
    required String endpoint,
    required String objectKey,
    required String emptyKeyMessage,
    required String serverErrorMessage,
  }) async {
    final cleanedKey = objectKey.trim();

    if (cleanedKey.isEmpty) {
      throw Exception(emptyKeyMessage);
    }

    final idToken = await _getIdToken();

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'objectKey': cleanedKey,
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Media server returned ${response.statusCode}.';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          if (decoded['message'] != null) {
            message = decoded['message'].toString();
          } else if (decoded['error'] != null) {
            message = decoded['error'].toString();
          }
        }
      } catch (_) {}

      throw Exception(message);
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid response from media server.',
      );
    }

    final downloadUrl =
        decoded['downloadUrl']?.toString().trim();

    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw Exception(serverErrorMessage);
    }

    return downloadUrl;
  }
}