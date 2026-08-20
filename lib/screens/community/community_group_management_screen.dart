import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community_group_model.dart';
import '../../repositories/content_repository.dart';

class CommunityGroupManagementScreen extends StatelessWidget {
  final CommunityGroupModel group;

  const CommunityGroupManagementScreen({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    final isAdmin =
        currentUser != null &&
        currentUser.uid == group.adminId;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Group Management',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3D004D),
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 55,
                  color: Color(0xFF6B1FA2),
                ),
                SizedBox(height: 15),
                Text(
                  'Access restricted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D004D),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Only the HOD or group administrator can manage this group.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FA),
      appBar: AppBar(
        title: const Text(
          'Group Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // =====================================================
          // GROUP HEADER
          // =====================================================

          _buildGroupHeader(),

          const SizedBox(height: 24),

          const Text(
            'Manage Community',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 12),

          // =====================================================
          // MEMBERS
          // =====================================================

          _ManagementTile(
            icon: Icons.people_outline,
            title: 'Members',
            subtitle:
                '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/community-group-members',
                arguments: group.id,
              );
            },
          ),

          // =====================================================
          // POSTS
          // =====================================================

          _ManagementTile(
            icon: Icons.article_outlined,
            title: 'Manage Posts',
            subtitle:
                'Edit, delete and pin community posts',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/community-group-posts',
                arguments: group.id,
              );
            },
          ),

          // =====================================================
          // EDIT GROUP
          // =====================================================

          _ManagementTile(
            icon: Icons.edit_outlined,
            title: 'Edit Group',
            subtitle:
                'Change group name, description and image',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/edit-community-group',
                arguments: group,
              );
            },
          ),

          // =====================================================
          // CHANGE HOD
          // =====================================================

          _ManagementTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Change HOD',
            subtitle:
                'Transfer group administration',
            onTap: () {
              Navigator.pushNamed(
                context,
                '/change-community-admin',
                arguments: group,
              );
            },
          ),

          const SizedBox(height: 30),

          // =====================================================
          // GROUP INFORMATION
          // =====================================================

          const Text(
            'Group Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 12),

          _InformationCard(
            children: [
              _InfoRow(
                label: 'Department',
                value: group.department.isEmpty
                    ? 'Not specified'
                    : group.department,
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'HOD',
                value: group.adminName,
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Members',
                value: '${group.memberCount}',
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Status',
                value: group.isPublished
                    ? 'Published'
                    : 'Unpublished',
              ),
            ],
          ),

          const SizedBox(height: 30),

          // =====================================================
          // DANGER ZONE
          // =====================================================

          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 12),

          _ManagementTile(
            icon: Icons.visibility_off_outlined,
            title: 'Disable Group',
            subtitle:
                'Hide this group from the RHIC Community',
            iconColor: Colors.red,
            titleColor: Colors.red,
            onTap: () {
              _showDisableConfirmation(context);
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // GROUP HEADER
  // ============================================================

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Group image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 70,
              height: 70,
              child: group.coverImageUrl.isNotEmpty
                  ? Image.network(
                      group.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _groupImageFallback();
                      },
                    )
                  : _groupImageFallback(),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D004D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'HOD: ${group.adminName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupImageFallback() {
    return Container(
      color: const Color(0xFFF1D9F7),
      child: const Icon(
        Icons.groups,
        color: Color(0xFF6B1FA2),
        size: 35,
      ),
    );
  }

  // ============================================================
  // DISABLE GROUP
  // ============================================================

  Future<void> _showDisableConfirmation(
    BuildContext context,
  ) async {
    final shouldDisable =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Disable group?',
          ),
          content: const Text(
            'This will hide the group from the RHIC Community. You can enable it again later.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Disable',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDisable != true) {
      return;
    }

    try {
      await ContentRepository.instance
          .updateCommunityGroup(
        groupId: group.id,
        name: group.name,
        description: group.description,
        department: group.department,
        coverImageUrl: group.coverImageUrl,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Group settings updated.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update group.',
          ),
        ),
      );
    }
  }
}

// ============================================================
// MANAGEMENT TILE
// ============================================================

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  final Color? iconColor;
  final Color? titleColor;

  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (iconColor ??
                    const Color(0xFF6B1FA2))
                .withValues(alpha: .10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                iconColor ?? const Color(0xFF6B1FA2),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color:
                titleColor ?? const Color(0xFF3D004D),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================
// INFORMATION CARD
// ============================================================

class _InformationCard extends StatelessWidget {
  final List<Widget> children;

  const _InformationCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ============================================================
// INFORMATION ROW
// ============================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D004D),
            ),
          ),
        ),
      ],
    );
  }
}