import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminNotificationService {
  AdminNotificationService._();

  static final AdminNotificationService instance =
      AdminNotificationService._();

  // ============================================================
  // BACKEND URL
  // ============================================================

  static const String backendBaseUrl = 'http://localhost:3000';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // SEND TO ALL MEMBERS
  // ============================================================

  Future<Map<String, dynamic>> sendToAllMembers({
    required String title,
    required String body,
    String type = 'general',
    String? route,
    String? imageObjectKey,
    Map<String, dynamic>? data,
  }) async {
    final cleanedTitle = title.trim();
    final cleanedBody = body.trim();
    final cleanedType = type.trim().isEmpty
        ? 'general'
        : type.trim();

    if (cleanedTitle.isEmpty) {
      throw ArgumentError(
        'Notification title cannot be empty.',
      );
    }

    if (cleanedBody.isEmpty) {
      throw ArgumentError(
        'Notification body cannot be empty.',
      );
    }

    final response = await _post(
      '/api/admin/notifications/send-all',
      {
        'title': cleanedTitle,
        'body': cleanedBody,
        'type': cleanedType,
        'route': _cleanNullable(route),
        'imageObjectKey': _cleanNullable(imageObjectKey),
        'data': _normalizeData(data),
      },
    );

    return _handleResponse(response);
  }

  // ============================================================
  // SEND TO ONE MEMBER
  // ============================================================

  Future<Map<String, dynamic>> sendToMember({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? route,
    String? imageObjectKey,
    Map<String, dynamic>? data,
  }) async {
    final cleanedUserId = userId.trim();
    final cleanedTitle = title.trim();
    final cleanedBody = body.trim();
    final cleanedType = type.trim().isEmpty
        ? 'general'
        : type.trim();

    if (cleanedUserId.isEmpty) {
      throw ArgumentError(
        'User ID cannot be empty.',
      );
    }

    if (cleanedTitle.isEmpty) {
      throw ArgumentError(
        'Notification title cannot be empty.',
      );
    }

    if (cleanedBody.isEmpty) {
      throw ArgumentError(
        'Notification body cannot be empty.',
      );
    }

    final response = await _post(
      '/api/admin/notifications/send-member',
      {
        'userId': cleanedUserId,
        'title': cleanedTitle,
        'body': cleanedBody,
        'type': cleanedType,
        'route': _cleanNullable(route),
        'imageObjectKey': _cleanNullable(imageObjectKey),
        'data': _normalizeData(data),
      },
    );

    return _handleResponse(response);
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<Map<String, dynamic>> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final cleanedUserId = userId.trim();
    final cleanedNotificationId =
        notificationId.trim();

    if (cleanedUserId.isEmpty) {
      throw ArgumentError(
        'User ID cannot be empty.',
      );
    }

    if (cleanedNotificationId.isEmpty) {
      throw ArgumentError(
        'Notification ID cannot be empty.',
      );
    }

    final String encodedUserId =
        Uri.encodeComponent(cleanedUserId);

    final String encodedNotificationId =
        Uri.encodeComponent(
      cleanedNotificationId,
    );

    final response = await _request(
      method: 'DELETE',
      path:
          '/api/admin/notifications/'
          '$encodedUserId/'
          '$encodedNotificationId',
    );

    return _handleResponse(response);
  }

  // ============================================================
  // POST
  // ============================================================

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _request(
      method: 'POST',
      path: path,
      body: body,
    );
  }

  // ============================================================
  // AUTHENTICATED REQUEST
  // ============================================================

  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be signed in as an administrator.',
      );
    }

    try {
      final String? idToken =
          await user.getIdToken();

      if (idToken == null ||
          idToken.trim().isEmpty) {
        throw Exception(
          'Unable to obtain Firebase authentication token.',
        );
      }

      final Uri uri = Uri.parse(
        '$backendBaseUrl$path',
      );

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      switch (method) {
        case 'POST':
          return await http.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );

        case 'DELETE':
          return await http.delete(
            uri,
            headers: headers,
          );

        default:
          throw Exception(
            'Unsupported HTTP method: $method',
          );
      }
    } catch (error) {
      debugPrint(
        'Admin notification request error: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // RESPONSE
  // ============================================================

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    Map<String, dynamic> decoded = {};

    try {
      if (response.body.trim().isNotEmpty) {
        final dynamic result =
            jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          decoded = result;
        }
      }
    } catch (_) {
      decoded = {};
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return decoded;
    }

    String message =
        'Notification request failed.';

    final dynamic serverMessage =
        decoded['message'];

    final dynamic serverError =
        decoded['error'];

    if (serverMessage is String &&
        serverMessage.trim().isNotEmpty) {
      message = serverMessage;
    } else if (serverError is String &&
        serverError.trim().isNotEmpty) {
      message = serverError;
    }

    if (response.statusCode == 401) {
      message =
          'Your session has expired. Please sign in again.';
    } else if (response.statusCode == 403) {
      message =
          'You do not have administrator permission.';
    }

    throw Exception(
      '$message (HTTP ${response.statusCode})',
    );
  }

  // ============================================================
  // CLEAN OPTIONAL STRING
  // ============================================================

  String? _cleanNullable(String? value) {
    if (value == null) {
      return null;
    }

    final String cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }

  // ============================================================
  // NORMALIZE DATA
  // ============================================================

  Map<String, String> _normalizeData(
    Map<String, dynamic>? data,
  ) {
    if (data == null || data.isEmpty) {
      return {};
    }

    final Map<String, String> result = {};

    data.forEach(
      (String key, dynamic value) {
        final String cleanedKey = key.trim();

        if (cleanedKey.isEmpty || value == null) {
          return;
        }

        result[cleanedKey] = value.toString();
      },
    );

    return result;
  }
}