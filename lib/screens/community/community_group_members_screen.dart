import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community_group_model.dart';
import '../../repositories/content_repository.dart';

class CommunityGroupMembersScreen extends StatelessWidget {
  final String groupId;

  const CommunityGroupMembersScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FA),
      appBar: AppBar(
        title: const Text(
          'Group Members',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,
      ),
      body: StreamBuilder<CommunityGroupModel?>(
        stream: ContentRepository.instance
            .communityGroupStream(groupId),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          if (groupSnapshot.hasError) {
            return _buildError();
          }

          final group = groupSnapshot.data;

          if (group == null) {
            return _buildNotFound();
          }

          final isAdmin =
              currentUser != null &&
              currentUser.uid == group.adminId;

          return Column(
            children: [
              // ==================================================
              // MEMBER COUNT HEADER
              // ==================================================

              _buildHeader(group),

              // ==================================================
              // MEMBERS
              // ==================================================

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: ContentRepository.instance
                      .communityGroupMembersStream(
                    groupId,
                  ),
                  builder: (
                    context,
                    membersSnapshot,
                  ) {
                    if (membersSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6B1FA2),
                        ),
                      );
                    }

                    if (membersSnapshot.hasError) {
                      return _buildError();
                    }

                    final documents =
                        membersSnapshot.data?.docs ?? [];

                    if (documents.isEmpty) {
                      return _buildEmptyMembers();
                    }

                    return ListView.builder(
                      physics:
                          const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        10,
                        20,
                        30,
                      ),
                      itemCount: documents.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final member =
                            documents[index];

                        return _MemberTile(
                          member: member,
                          group: group,
                          isAdmin: isAdmin,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    CommunityGroupModel group,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        18,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF1D9F7),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.people_alt_outlined,
              color: Color(0xFF6B1FA2),
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Community Members',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D004D),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyMembers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 55,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'No members yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D004D),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'People who join this group will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOT FOUND
  // ============================================================

  Widget _buildNotFound() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Group not found.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MEMBER TILE
// ============================================================

class _MemberTile extends StatelessWidget {
  final QueryDocumentSnapshot<
      Map<String, dynamic>> member;

  final CommunityGroupModel group;
  final bool isAdmin;

  const _MemberTile({
    required this.member,
    required this.group,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final data = member.data();

    final uid =
        data['uid']?.toString() ?? member.id;

    final name =
        data['name']?.toString() ??
        data['displayName']?.toString() ??
        'RHIC Member';

    final photoUrl =
        data['photoUrl']?.toString() ??
        data['photoURL']?.toString() ??
        '';

    final memberIsAdmin =
        uid == group.adminId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),

        // ======================================================
        // PROFILE PHOTO
        // ======================================================

        leading: CircleAvatar(
          radius: 24,
          backgroundColor:
              const Color(0xFFF1D9F7),
          backgroundImage:
              photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
          child: photoUrl.isEmpty
              ? const Icon(
                  Icons.person_outline,
                  color: Color(0xFF6B1FA2),
                )
              : null,
        ),

        // ======================================================
        // NAME + ROLE
        // ======================================================

        title: Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D004D),
                ),
              ),
            ),

            if (memberIsAdmin) ...[
              const SizedBox(width: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF1D9F7),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Text(
                  'HOD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color:
                        Color(0xFF6B1FA2),
                  ),
                ),
              ),
            ],
          ],
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),
          child: Text(
            memberIsAdmin
                ? 'Group Administrator'
                : 'Member',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),

        // ======================================================
        // ADMIN MENU
        // ======================================================

        trailing: isAdmin && !memberIsAdmin
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color:
                      Colors.grey.shade600,
                ),
                onSelected: (value) {
                  if (value == 'remove') {
                    _confirmRemoveMember(
                      context,
                      uid,
                      name,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_remove_outlined,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Remove member',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  // ============================================================
  // REMOVE MEMBER CONFIRMATION
  // ============================================================

  Future<void> _confirmRemoveMember(
    BuildContext context,
    String uid,
    String name,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove member?',
          ),
          content: Text(
            'Remove $name from this community group?',
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
                'Remove',
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

    if (confirmed != true) {
      return;
    }

    try {
      await ContentRepository.instance
          .removeCommunityGroupMember(
        groupId: group.id,
        uid: uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name was removed from the group.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to remove member.',
          ),
        ),
      );
    }
  }
}