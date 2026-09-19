import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? imageObjectKey;
  final String? actionRoute;
  final String? actionId;
  final bool isRead;
  final DateTime? createdAt;
  final String? createdBy;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.imageObjectKey,
    this.actionRoute,
    this.actionId,
    required this.isRead,
    this.createdAt,
    this.createdBy,
    this.data = const {},
  });

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data() ?? <String, dynamic>{};

    return NotificationModel(
      id: document.id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      imageObjectKey: map['imageObjectKey'] as String?,
      actionRoute: map['actionRoute'] as String?,
      actionId: map['actionId'] as String?,

      // Backend stores this as "read".
      isRead: map['read'] as bool? ?? false,

      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy'] as String?,
      data: _parseData(map['data']),
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory NotificationModel.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    return NotificationModel(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      imageObjectKey: map['imageObjectKey'] as String?,
      actionRoute: map['actionRoute'] as String?,
      actionId: map['actionId'] as String?,

      // Backend stores this as "read".
      isRead: map['read'] as bool? ?? false,

      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy'] as String?,
      data: _parseData(map['data']),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'imageObjectKey': imageObjectKey,
      'actionRoute': actionRoute,
      'actionId': actionId,

      // Backend notificationService.js uses "read".
      'read': isRead,

      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),

      'createdBy': createdBy,
      'data': data,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? imageObjectKey,
    String? actionRoute,
    String? actionId,
    bool? isRead,
    DateTime? createdAt,
    String? createdBy,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      imageObjectKey: imageObjectKey ?? this.imageObjectKey,
      actionRoute: actionRoute ?? this.actionRoute,
      actionId: actionId ?? this.actionId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      data: data ?? this.data,
    );
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // DATA PARSER
  // ============================================================

  static Map<String, dynamic> _parseData(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}