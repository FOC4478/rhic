import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance =
      NotificationRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _userNotifications(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  // ============================================================
  // NOTIFICATIONS STREAM
  // ============================================================

  Stream<List<NotificationModel>> notificationsStream({
    String? uid,
  }) {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      return Stream.value(const <NotificationModel>[]);
    }

    return _userNotifications(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(NotificationModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  Stream<int> unreadCountStream({
    String? uid,
  }) {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      return Stream.value(0);
    }

    return _userNotifications(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================
  // GET ONE NOTIFICATION
  // ============================================================

  Future<NotificationModel?> getNotification(
    String notificationId, {
    String? uid,
  }) async {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      return null;
    }

    final document =
        await _userNotifications(userId).doc(notificationId).get();

    if (!document.exists) {
      return null;
    }

    return NotificationModel.fromFirestore(document);
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  Future<void> markAsRead(
    String notificationId, {
    String? uid,
  }) async {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      throw StateError('No authenticated user.');
    }

    await _userNotifications(userId)
        .doc(notificationId)
        .update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK AS UNREAD
  // ============================================================

  Future<void> markAsUnread(
    String notificationId, {
    String? uid,
  }) async {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      throw StateError('No authenticated user.');
    }

    await _userNotifications(userId)
        .doc(notificationId)
        .update({
      'read': false,
      'readAt': null,
    });
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead({
    String? uid,
  }) async {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      throw StateError('No authenticated user.');
    }

    final snapshot = await _userNotifications(userId)
        .where('read', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> deleteNotification(
    String notificationId, {
    String? uid,
  }) async {
    final userId = uid ?? currentUserId;

    if (userId == null) {
      throw StateError('No authenticated user.');
    }

    await _userNotifications(userId)
        .doc(notificationId)
        .delete();
  }

  // ============================================================
  // CREATE ONE NOTIFICATION
  // ============================================================
  //
  // Mainly useful for local/admin-side Firestore operations.
  // Admin notifications should normally go through the backend
  // so FCM push notifications are also sent.
  // ============================================================

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? imageObjectKey,
    String? actionRoute,
    String? actionId,
    String? createdBy,
    Map<String, dynamic> data = const {},
  }) async {
    final cleanedUserId = userId.trim();
    final cleanedTitle = title.trim();
    final cleanedBody = body.trim();

    if (cleanedUserId.isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    if (cleanedTitle.isEmpty) {
      throw ArgumentError('Notification title cannot be empty.');
    }

    if (cleanedBody.isEmpty) {
      throw ArgumentError('Notification body cannot be empty.');
    }

    final notificationReference =
        _userNotifications(cleanedUserId).doc();

    final notification = NotificationModel(
      id: notificationReference.id,
      userId: cleanedUserId,
      title: cleanedTitle,
      body: cleanedBody,
      type: type.trim().isEmpty ? 'general' : type.trim(),
      imageObjectKey: imageObjectKey,
      actionRoute: actionRoute,
      actionId: actionId,
      isRead: false,
      createdAt: DateTime.now(),
      createdBy: createdBy ?? currentUserId,
      data: data,
    );

    await notificationReference.set(
      notification.toFirestore(),
    );
  }

  // ============================================================
  // CREATE NOTIFICATIONS FOR MULTIPLE USERS
  // ============================================================
  //
  // Firestore allows a maximum of 500 writes per batch.
  // We use 450 to leave some room and keep this safe.
  // ============================================================

  Future<void> createNotificationsForUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'general',
    String? imageObjectKey,
    String? actionRoute,
    String? actionId,
    String? createdBy,
    Map<String, dynamic> data = const {},
  }) async {
    final cleanedUserIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final cleanedTitle = title.trim();
    final cleanedBody = body.trim();

    if (cleanedUserIds.isEmpty) {
      return;
    }

    if (cleanedTitle.isEmpty) {
      throw ArgumentError('Notification title cannot be empty.');
    }

    if (cleanedBody.isEmpty) {
      throw ArgumentError('Notification body cannot be empty.');
    }

    const maxBatchSize = 450;

    for (var start = 0;
        start < cleanedUserIds.length;
        start += maxBatchSize) {
      final end = (start + maxBatchSize > cleanedUserIds.length)
          ? cleanedUserIds.length
          : start + maxBatchSize;

      final chunk = cleanedUserIds.sublist(start, end);

      final batch = _firestore.batch();

      for (final userId in chunk) {
        final reference = _userNotifications(userId).doc();

        final notification = NotificationModel(
          id: reference.id,
          userId: userId,
          title: cleanedTitle,
          body: cleanedBody,
          type: type.trim().isEmpty ? 'general' : type.trim(),
          imageObjectKey: imageObjectKey,
          actionRoute: actionRoute,
          actionId: actionId,
          isRead: false,
          createdAt: DateTime.now(),
          createdBy: createdBy ?? currentUserId,
          data: data,
        );

        batch.set(
          reference,
          notification.toFirestore(),
        );
      }

      await batch.commit();
    }
  }
}