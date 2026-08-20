import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroupModel {
  final String id;
  final String name;
  final String description;
  final String coverImageUrl;

  final String adminId;
  final String adminName;

  final String department;
  final bool requiresApproval;
  final bool isPublished;

  final int memberCount;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.adminId,
    required this.adminName,
    required this.department,
    required this.requiresApproval,
    required this.isPublished,
    required this.memberCount,
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
      coverImageUrl: data['coverImageUrl']?.toString() ?? '',
      adminId: data['adminId']?.toString() ?? '',
      adminName: data['adminName']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      requiresApproval: data['requiresApproval'] == true,
      isPublished: data['isPublished'] == true,
      memberCount: data['memberCount'] is int
          ? data['memberCount'] as int
          : 0,
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
      'coverImageUrl': coverImageUrl,
      'adminId': adminId,
      'adminName': adminName,
      'department': department,
      'requiresApproval': requiresApproval,
      'isPublished': isPublished,
      'memberCount': memberCount,
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
    String? coverImageUrl,
    String? adminId,
    String? adminName,
    String? department,
    bool? requiresApproval,
    bool? isPublished,
    int? memberCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CommunityGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      department: department ?? this.department,
      requiresApproval:
          requiresApproval ?? this.requiresApproval,
      isPublished:
          isPublished ?? this.isPublished,
      memberCount:
          memberCount ?? this.memberCount,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}