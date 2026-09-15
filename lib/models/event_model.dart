// lib/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime eventDate;
  final String imageObjectKey;
  final bool isFeatured;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  const EventModel({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.imageObjectKey,
    required this.isFeatured,
    required this.isPublished,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory EventModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return EventModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      eventDate:
          _timestampToDateTime(data['eventDate']) ?? DateTime.now(),
      imageObjectKey:
          data['imageObjectKey']?.toString() ?? '',
      isFeatured: data['isFeatured'] == true,
      isPublished: data['isPublished'] == true,
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'eventDate': Timestamp.fromDate(eventDate),
      'imageObjectKey': imageObjectKey,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'createdBy': createdBy,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    DateTime? eventDate,
    String? imageObjectKey,
    bool? isFeatured,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      imageObjectKey: imageObjectKey ?? this.imageObjectKey,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}