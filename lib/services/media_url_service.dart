
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class MediaUrlService {
  MediaUrlService._();

  static final MediaUrlService instance =
      MediaUrlService._();

  // ============================================================
  // BACKEND URL
  // ============================================================
  //
  // Chrome Web + backend running on the same computer:
  //
  // http://localhost:3000
  //
  // When testing on a physical phone, replace localhost
  // with your computer's LAN IP.
  // ============================================================

  static const String baseUrl =
      'http://localhost:3000';

  // ============================================================
  // GET SIGNED DOWNLOAD URL
  // ============================================================

  Future<String> getDownloadUrl({
    required String storagePath,
  }) async {
    final cleanedPath = storagePath.trim();

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

    final response = await http.post(
      Uri.parse(
        '$baseUrl/download-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },

      // IMPORTANT:
      body: jsonEncode({
        'objectKey': cleanedPath,
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

    // IMPORTANT:
    // Backend returns "downloadUrl", NOT "url".
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
}

