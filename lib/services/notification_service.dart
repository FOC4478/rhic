// lib/services/notification_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // LOCAL NOTIFICATIONS
  // ============================================================

  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<String>?
      _tokenRefreshSubscription;

  StreamSubscription<RemoteMessage>?
      _foregroundMessageSubscription;

  StreamSubscription<RemoteMessage>?
      _messageOpenedAppSubscription;

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;

  // ============================================================
  // ANDROID CHANNEL
  // ============================================================

  static const String _channelId =
      'rhic_notifications';

  static const String _channelName =
      'RHIC Notifications';

  static const String _channelDescription =
      'Notifications from RHIC';

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    if (_initialized) {
      return;
    }

    try {
      await _initializeLocalNotifications();

      await _requestPermission();

      await _messaging
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await refreshTokenForCurrentUser();

      // ----------------------------------------------------------
      // TOKEN REFRESH
      // ----------------------------------------------------------

      _tokenRefreshSubscription ??=
          _messaging.onTokenRefresh.listen(
        (String token) async {
          await _saveToken(token);
        },
      );

      // ----------------------------------------------------------
      // FOREGROUND MESSAGE
      // ----------------------------------------------------------

      _foregroundMessageSubscription ??=
          FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) async {
          await _handleForegroundMessage(message);
        },
      );

      // ----------------------------------------------------------
      // BACKGROUND MESSAGE TAP
      // ----------------------------------------------------------

      _messageOpenedAppSubscription ??=
          FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) async {
          await _handleMessageOpenedApp(message);
        },
      );

      // ----------------------------------------------------------
      // TERMINATED APP MESSAGE
      // ----------------------------------------------------------

      final RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'RHIC notification opened from terminated app.',
        );

        debugPrint(
          'RHIC notification data: '
          '${initialMessage.data}',
        );
      }

      _initialized = true;

      debugPrint(
        'RHIC NotificationService initialized.',
      );
    } catch (error) {
      debugPrint(
        'RHIC NotificationService initialization error: '
        '$error',
      );
    }
  }

  // ============================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ============================================================

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
        iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          _handleLocalNotificationResponse,
    );

    // ----------------------------------------------------------
    // ANDROID CHANNEL
    // ----------------------------------------------------------

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin?
        androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      channel,
    );
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<void> _requestPermission() async {
    final NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint(
      'RHIC notification permission: '
      '${settings.authorizationStatus}',
    );
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  Future<void> refreshTokenForCurrentUser() async {
    if (kIsWeb) {
      return;
    }

    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        debugPrint(
          'RHIC notification token not saved: '
          'no authenticated user.',
        );
        return;
      }

      final String? token =
          await _messaging.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        debugPrint(
          'RHIC FCM token is unavailable.',
        );
        return;
      }

      await _saveToken(token);
    } catch (error) {
      debugPrint(
        'Unable to refresh RHIC notification token: '
        '$error',
      );
    }
  }

  // ============================================================
  // SAVE TOKEN
  // ============================================================

  Future<void> _saveToken(
    String token,
  ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    final String cleanedToken =
        token.trim();

    if (cleanedToken.isEmpty) {
      return;
    }

    try {
      final String deviceId =
          _createDeviceId(cleanedToken);

      final DocumentReference<
          Map<String, dynamic>> deviceRef =
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('devices')
              .doc(deviceId);

      await deviceRef.set(
        {
          'token': cleanedToken,
          'platform': _platformName(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint(
        'RHIC FCM token saved for user: '
        '${user.uid}',
      );
    } catch (error) {
      debugPrint(
        'Unable to save RHIC FCM token: '
        '$error',
      );
    }
  }

  // ============================================================
  // DEVICE ID
  // ============================================================

  String _createDeviceId(
    String token,
  ) {
    final int hash =
        token.hashCode.abs();

    return 'device_$hash';
  }

  // ============================================================
  // PLATFORM
  // ============================================================

  String _platformName() {
    if (defaultTargetPlatform ==
        TargetPlatform.android) {
      return 'android';
    }

    if (defaultTargetPlatform ==
        TargetPlatform.iOS) {
      return 'ios';
    }

    return 'unknown';
  }

  // ============================================================
  // FOREGROUND MESSAGE
  // ============================================================

  Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    try {
      debugPrint(
        'RHIC foreground notification received.',
      );

      debugPrint(
        'Title: '
        '${message.notification?.title}',
      );

      debugPrint(
        'Body: '
        '${message.notification?.body}',
      );

      debugPrint(
        'Data: '
        '${message.data}',
      );

      final RemoteNotification? notification =
          message.notification;

      if (notification == null) {
        return;
      }

      final String title =
          notification.title?.trim() ?? '';

      final String body =
          notification.body?.trim() ?? '';

      if (title.isEmpty &&
          body.isEmpty) {
        return;
      }

      final String payload =
          _encodePayload(
        message.data,
      );

      await _showLocalNotification(
        title: title.isEmpty
            ? 'RHIC'
            : title,
        body: body,
        payload: payload,
      );
    } catch (error) {
      debugPrint(
        'RHIC foreground notification error: '
        '$error',
      );
    }
  }

  // ============================================================
  // SHOW LOCAL NOTIFICATION
  // ============================================================

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails
        iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails
        notificationDetails =
        NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .remainder(2147483647),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // ============================================================
  // BACKGROUND NOTIFICATION TAP
  // ============================================================

  Future<void> _handleMessageOpenedApp(
    RemoteMessage message,
  ) async {
    debugPrint(
      'RHIC notification opened.',
    );

    debugPrint(
      'RHIC notification data: '
      '${message.data}',
    );
  }

  // ============================================================
  // LOCAL NOTIFICATION TAP
  // ============================================================

  void _handleLocalNotificationResponse(
    NotificationResponse response,
  ) {
    debugPrint(
      'RHIC local notification selected: '
      '${response.payload}',
    );
  }

  // ============================================================
  // ENCODE PAYLOAD
  // ============================================================

  String _encodePayload(
    Map<String, dynamic> data,
  ) {
    if (data.isEmpty) {
      return '';
    }

    final List<String> parts = [];

    data.forEach(
      (
        String key,
        dynamic value,
      ) {
        if (value == null) {
          return;
        }

        final String cleanKey =
            key.trim();

        final String cleanValue =
            value.toString().trim();

        if (cleanKey.isEmpty ||
            cleanValue.isEmpty) {
          return;
        }

        parts.add(
          '${Uri.encodeComponent(cleanKey)}'
          '='
          '${Uri.encodeComponent(cleanValue)}',
        );
      },
    );

    return parts.join('&');
  }

  // ============================================================
  // DELETE DEVICE TOKEN
  // ============================================================

  Future<void> deleteCurrentDeviceToken() async {
    if (kIsWeb) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final String? token =
          await _messaging.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        return;
      }

      final String deviceId =
          _createDeviceId(token);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .delete();

      debugPrint(
        'RHIC device notification token removed.',
      );
    } catch (error) {
      debugPrint(
        'Unable to delete RHIC device token: '
        '$error',
      );
    }
  }

  // ============================================================
  // CLEAN UP
  // ============================================================

  Future<void> dispose() async {
    await _tokenRefreshSubscription
        ?.cancel();

    await _foregroundMessageSubscription
        ?.cancel();

    await _messageOpenedAppSubscription
        ?.cancel();

    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _messageOpenedAppSubscription = null;

    _initialized = false;
  }
}