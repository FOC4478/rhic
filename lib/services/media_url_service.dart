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
  // GET SIGNED SERMON DOWNLOAD URL
  // ============================================================

  Future<String> getDownloadUrl({
    required String storagePath,
  }) async {
    final cleanedPath =
        storagePath.trim();

    if (cleanedPath.isEmpty) {
      throw Exception(
        'Media storage path is empty.',
      );
    }

    // ----------------------------------------------------------
    // CURRENT FIREBASE USER
    // ----------------------------------------------------------

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Please sign in to access this media.',
      );
    }

    // ----------------------------------------------------------
    // FIREBASE ID TOKEN
    // ----------------------------------------------------------

    final idToken =
        await user.getIdToken(true);

    if (idToken == null ||
        idToken.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate with the media server.',
      );
    }

    // ----------------------------------------------------------
    // REQUEST SIGNED URL FROM BACKEND
    // ----------------------------------------------------------

    final response =
        await http.post(
      Uri.parse(
        '$baseUrl/download-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'objectKey':
            cleanedPath,
      }),
    );

    // ----------------------------------------------------------
    // HANDLE BACKEND ERRORS
    // ----------------------------------------------------------

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Media server returned ${response.statusCode}.';

      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          if (decoded['message'] != null) {
            message =
                decoded['message'].toString();
          } else if (decoded['error'] != null) {
            message =
                decoded['error'].toString();
          }
        }
      } catch (_) {}

      throw Exception(message);
    }

    // ----------------------------------------------------------
    // DECODE RESPONSE
    // ----------------------------------------------------------

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid response from media server.',
      );
    }

    final downloadUrl =
        decoded['downloadUrl']
            ?.toString()
            .trim();

    if (downloadUrl == null ||
        downloadUrl.isEmpty) {
      throw Exception(
        'Media server did not return a download URL.',
      );
    }

    return downloadUrl;
  }

  // ============================================================
  // GET SIGNED EVENT FLYER DOWNLOAD URL
  // ============================================================

  Future<String> getEventDownloadUrl({
    required String storagePath,
  }) async {
    final cleanedPath =
        storagePath.trim();

    if (cleanedPath.isEmpty) {
      throw Exception(
        'Event flyer storage path is empty.',
      );
    }

    // ----------------------------------------------------------
    // CURRENT FIREBASE USER
    // ----------------------------------------------------------

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Please sign in to access this event.',
      );
    }

    // ----------------------------------------------------------
    // FIREBASE ID TOKEN
    // ----------------------------------------------------------

    final idToken =
        await user.getIdToken(true);

    if (idToken == null ||
        idToken.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate with the media server.',
      );
    }

    // ----------------------------------------------------------
    // REQUEST SIGNED EVENT URL
    // ----------------------------------------------------------

    final response =
        await http.post(
      Uri.parse(
        '$baseUrl/event-download-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'objectKey':
            cleanedPath,
      }),
    );

    // ----------------------------------------------------------
    // HANDLE BACKEND ERRORS
    // ----------------------------------------------------------

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Event media server returned ${response.statusCode}.';

      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map) {
          if (decoded['message'] != null) {
            message =
                decoded['message'].toString();
          } else if (decoded['error'] != null) {
            message =
                decoded['error'].toString();
          }
        }
      } catch (_) {}

      throw Exception(message);
    }

    // ----------------------------------------------------------
    // DECODE RESPONSE
    // ----------------------------------------------------------

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid response from event media server.',
      );
    }

    final downloadUrl =
        decoded['downloadUrl']
            ?.toString()
            .trim();

    if (downloadUrl == null ||
        downloadUrl.isEmpty) {
      throw Exception(
        'Event media server did not return a download URL.',
      );
    }

    return downloadUrl;
  }

  // ============================================================
  // GET SIGNED GALLERY IMAGE DOWNLOAD URL
  // ============================================================

  Future<String> getGalleryDownloadUrl({
    required String storagePath,
  }) async {
    final cleanedPath =
        storagePath.trim();

    if (cleanedPath.isEmpty) {
      throw Exception(
        'A B2 gallery image object key is required.',
      );
    }

    // ----------------------------------------------------------
    // CURRENT FIREBASE USER
    // ----------------------------------------------------------

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in.',
      );
    }

    // ----------------------------------------------------------
    // FIREBASE ID TOKEN
    // ----------------------------------------------------------

    final idToken =
        await user.getIdToken(true);

    if (idToken == null ||
        idToken.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate your account.',
      );
    }

    // ----------------------------------------------------------
    // REQUEST SIGNED GALLERY URL
    // ----------------------------------------------------------

    final response =
        await http.post(
      Uri.parse(
        '$baseUrl/gallery-download-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'objectKey':
            cleanedPath,
      }),
    );

    // ----------------------------------------------------------
    // HANDLE BACKEND ERRORS
    // ----------------------------------------------------------

    if (response.statusCode != 200) {
      String message =
          'Unable to create gallery image URL.';

      try {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map &&
            decoded['message'] != null) {
          message =
              decoded['message'].toString();
        }
      } catch (_) {}

      throw Exception(message);
    }

    // ----------------------------------------------------------
    // DECODE RESPONSE
    // ----------------------------------------------------------

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['downloadUrl'] == null) {
      throw Exception(
        'The gallery server returned an invalid response.',
      );
    }

    final downloadUrl =
        decoded['downloadUrl']
            .toString()
            .trim();

    if (downloadUrl.isEmpty) {
      throw Exception(
        'The server returned an empty gallery image URL.',
      );
    }

    return downloadUrl;
  }
}