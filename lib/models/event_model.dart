import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String imageUrl;
  final bool isFeatured;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.imageUrl,
    required this.isFeatured,
    required this.isPublished,
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
      description: data['description']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      time: data['time']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      isFeatured: data['isFeatured'] == true,
      isPublished: data['isPublished'] == true,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
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
    String? description,
    String? date,
    String? time,
    String? location,
    String? imageUrl,
    bool? isFeatured,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}