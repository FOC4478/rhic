import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class B2UploadResult {
  final String objectKey;
  final String bucket;
  final String region;
  final String mediaType;
  final String contentType;

  const B2UploadResult({
    required this.objectKey,
    required this.bucket,
    required this.region,
    required this.mediaType,
    required this.contentType,
  });
}

class B2UploadService {
  B2UploadService._();

  static final B2UploadService instance =
      B2UploadService._();

  // ============================================================
  // BACKEND URL
  // ============================================================

  static const String backendBaseUrl =
      'http://localhost:3000';

  // ============================================================
  // GET FIREBASE ID TOKEN
  // ============================================================

  Future<String> _getIdToken() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in.',
      );
    }

    final idToken =
        await user.getIdToken(true);

    if (idToken == null ||
        idToken.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate your account.',
      );
    }

    return idToken;
  }

  // ============================================================
  // UPLOAD FILE
  // ============================================================

  Future<B2UploadResult> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String mediaType,

    // sermon = normal sermon media
    // book   = private bookstore ebook PDF
    String resourceType = 'sermon',
  }) async {
    if (bytes.isEmpty) {
      throw Exception(
        'The selected file is empty.',
      );
    }

    final idToken =
        await _getIdToken();

    // ==========================================================
    // STEP 1
    // REQUEST TEMPORARY B2 UPLOAD URL
    // ==========================================================

    final response = await http.post(
      Uri.parse(
        '$backendBaseUrl/upload-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'fileName': fileName,
        'contentType': contentType,
        'mediaType': mediaType,
        'resourceType': resourceType,
      }),
    );

    if (response.statusCode != 200) {
      String message =
          'Unable to create upload URL.';

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

    // ==========================================================
    // STEP 2
    // VALIDATE RESPONSE
    // ==========================================================

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['uploadUrl'] == null ||
        decoded['objectKey'] == null) {
      throw Exception(
        'The upload server returned an invalid response.',
      );
    }

    final uploadUrl =
        decoded['uploadUrl'].toString();

    final objectKey =
        decoded['objectKey'].toString();

    final bucket =
        decoded['bucket']?.toString() ?? '';

    final region =
        decoded['region']?.toString() ?? '';

    // ==========================================================
    // STEP 3
    // UPLOAD DIRECTLY TO B2
    // ==========================================================

    final uploadResponse =
        await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type':
            contentType,
      },
      body: bytes,
    );

    if (uploadResponse.statusCode < 200 ||
        uploadResponse.statusCode >= 300) {
      throw Exception(
        'Backblaze upload failed '
        '(${uploadResponse.statusCode}).',
      );
    }

    // ==========================================================
    // STEP 4
    // RETURN OBJECT INFORMATION
    // ==========================================================

    return B2UploadResult(
      objectKey: objectKey,
      bucket: bucket,
      region: region,
      mediaType: mediaType,
      contentType: contentType,
    );
  }

  // ============================================================
  // GET SIGNED SERMON DOWNLOAD URL
  // ============================================================
  //
  // Use this only for sermon media.
  //
  // Example:
  //
  // getDownloadUrl(
  //   objectKey: sermonObjectKey,
  // );
  //
  // Paid books must use getEbookDownloadUrl().
  // ============================================================

  Future<String> getDownloadUrl({
    required String objectKey,
  }) async {
    if (objectKey.trim().isEmpty) {
      throw Exception(
        'A B2 object key is required.',
      );
    }

    final idToken =
        await _getIdToken();

    final response =
        await http.post(
      Uri.parse(
        '$backendBaseUrl/download-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'objectKey':
            objectKey.trim(),
      }),
    );

    if (response.statusCode != 200) {
      String message =
          'Unable to create download URL.';

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

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['downloadUrl'] == null) {
      throw Exception(
        'The download server returned an invalid response.',
      );
    }

    final downloadUrl =
        decoded['downloadUrl'].toString();

    if (downloadUrl.trim().isEmpty) {
      throw Exception(
        'The server returned an empty download URL.',
      );
    }

    return downloadUrl;
  }

  // ============================================================
  // GET SIGNED PURCHASED EBOOK URL
  // ============================================================
  //
  // IMPORTANT:
  // The client sends ONLY the book ID.
  //
  // The backend:
  // 1. verifies the Firebase user
  // 2. finds the book
  // 3. gets ebookObjectKey from Firestore
  // 4. checks for an approved purchase
  // 5. creates a temporary B2 URL
  //
  // The client does NOT send the private object key.
  // ============================================================

  Future<String> getEbookDownloadUrl({
    required String bookId,
  }) async {
    if (bookId.trim().isEmpty) {
      throw Exception(
        'Book ID is required.',
      );
    }

    final idToken =
        await _getIdToken();

    final response =
        await http.post(
      Uri.parse(
        '$backendBaseUrl/book-download-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'bookId':
            bookId.trim(),
      }),
    );

    if (response.statusCode != 200) {
      String message =
          'Unable to access this ebook.';

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

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['downloadUrl'] == null) {
      throw Exception(
        'The ebook server returned an invalid response.',
      );
    }

    final downloadUrl =
        decoded['downloadUrl'].toString();

    if (downloadUrl.trim().isEmpty) {
      throw Exception(
        'The server returned an empty ebook URL.',
      );
    }

    return downloadUrl;
  }


  // ============================================================
  // GET SIGNED BOOK COVER URL
  // ============================================================
  //
  // The client sends only the book ID.
  // The backend gets coverObjectKey from Firestore and
  // returns a temporary signed B2 URL.
  // ============================================================

  Future<String> getBookCoverUrl({
    required String bookId,
  }) async {
    if (bookId.trim().isEmpty) {
      throw Exception(
        'Book ID is required.',
      );
    }

    final idToken =
        await _getIdToken();

    final response = await http.post(
      Uri.parse(
        '$backendBaseUrl/book-cover-url',
      ),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $idToken',
      },
      body: jsonEncode({
        'bookId':
            bookId.trim(),
      }),
    );

    if (response.statusCode != 200) {
      String message =
          'Unable to load book cover.';

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

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['coverUrl'] == null) {
      throw Exception(
        'The cover server returned an invalid response.',
      );
    }

    final coverUrl =
        decoded['coverUrl'].toString();

    if (coverUrl.trim().isEmpty) {
      throw Exception(
        'The server returned an empty cover URL.',
      );
    }

    return coverUrl;
  }



}