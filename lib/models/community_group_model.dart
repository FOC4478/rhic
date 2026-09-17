import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroupModel {
  final String id;
  final String name;
  final String description;
  final String department;
  final String coverImageObjectKey;
  final bool requiresApproval;
  final String adminId;
  final String adminName;
  final int memberCount;
  final bool isPublished;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CommunityGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.coverImageObjectKey,
    required this.requiresApproval,
    required this.adminId,
    required this.adminName,
    required this.memberCount,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityGroupModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return CommunityGroupModel(
      id: snapshot.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      department: data['department']?.toString() ?? '',
      coverImageObjectKey:
          data['coverImageObjectKey']?.toString() ?? '',
          requiresApproval: data['requiresApproval'] as bool? ?? false,
      adminId: data['adminId']?.toString() ?? '',
      adminName: data['adminName']?.toString() ?? '',
      memberCount: _toInt(data['memberCount']),
      isPublished: data['isPublished'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

Map<String, dynamic> toFirestore() {
  return {
    'name': name.trim(),
    'description': description.trim(),
    'department': department.trim(),
    'coverImageObjectKey':
        coverImageObjectKey.trim(),
    'requiresApproval': requiresApproval,
    'adminId': adminId.trim(),
    'adminName': adminName.trim(),
    'memberCount': memberCount,
    'isPublished': isPublished,
    'createdAt':
        createdAt ?? FieldValue.serverTimestamp(),
    'updatedAt':
        updatedAt ?? FieldValue.serverTimestamp(),
  };
}

  CommunityGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? department,
    String? coverImageObjectKey,
    String? adminId,
    String? adminName,
    int? memberCount,
    bool? isPublished,
    bool? requiresApproval,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CommunityGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      department: department ?? this.department,
      coverImageObjectKey:
          coverImageObjectKey ?? this.coverImageObjectKey,
          requiresApproval: requiresApproval ?? this.requiresApproval,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      memberCount: memberCount ?? this.memberCount,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}