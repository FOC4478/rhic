import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroupModel {
  final String id;
  final String name;
  final String description;
  final String department;
  final String imageUrl;
  final String adminId;
  final int memberCount;
  final bool isPublished;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.imageUrl,
    required this.adminId,
    required this.memberCount,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FIRESTORE → MODEL
  // ============================================================

  factory CommunityGroupModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return CommunityGroupModel(
      id: snapshot.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      adminId: data['adminId']?.toString() ?? '',
      memberCount: data['memberCount'] is int
          ? data['memberCount'] as int
          : 0,
      isPublished: data['isPublished'] == true,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  // ============================================================
  // MODEL → FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'department': department,
      'imageUrl': imageUrl,
      'adminId': adminId,
      'memberCount': memberCount,
      'isPublished': isPublished,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CommunityGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? department,
    String? imageUrl,
    String? adminId,
    int? memberCount,
    bool? isPublished,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CommunityGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      department: department ?? this.department,
      imageUrl: imageUrl ?? this.imageUrl,
      adminId: adminId ?? this.adminId,
      memberCount: memberCount ?? this.memberCount,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}