import 'package:cloud_firestore/cloud_firestore.dart';

class ChurchEvent {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String date;
  final String time;
  final String location;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChurchEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.location,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  factory ChurchEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return ChurchEvent(
      id: snapshot.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      date: data['date'] as String? ?? '',
      time: data['time'] as String? ?? '',
      location: data['location'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? false,
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'date': date,
      'time': time,
      'location': location,
      'isPublished': isPublished,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}