import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community_group_model.dart';
import '../../repositories/content_repository.dart';
import 'community_group_members_screen.dart';
import 'create_community_post_screen.dart';
import 'widgets/community_post_feed.dart';

class CommunityGroupDetailsScreen extends StatefulWidget {
  final String groupId;

  const CommunityGroupDetailsScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<CommunityGroupDetailsScreen> createState() =>
      _CommunityGroupDetailsScreenState();
}

class _CommunityGroupDetailsScreenState
    extends State<CommunityGroupDetailsScreen> {
  bool _joining = false;

  // ============================================================
  // JOIN GROUP
  // ============================================================

  Future<void> _joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before joining a group.',
      );
      return;
    }

    if (_joining) return;

    setState(() {
      _joining = true;
    });

    try {
      await ContentRepository.instance.joinCommunityGroup(
        groupId: widget.groupId,
        uid: user.uid,
      );

      if (!mounted) return;

      _showMessage(
        'You joined this group.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to join this group. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  // ============================================================
  // LEAVE GROUP
  // ============================================================

  Future<void> _leaveGroup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _joining) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Leave group?',
          ),
          content: const Text(
            'You will no longer be a member of this community group.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Leave',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true) {
      return;
    }

    setState(() {
      _joining = true;
    });

    try {
      await ContentRepository.instance.leaveCommunityGroup(
        groupId: widget.groupId,
        uid: user.uid,
      );

      if (!mounted) return;

      _showMessage(
        'You left the group.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to leave this group. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // OPEN CREATE POST
  // ============================================================

  Future<void> _openCreatePost(
    CommunityGroupModel group,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in before creating a post.',
      );
      return;
    }

    try {
      final isMember = await ContentRepository.instance
          .isCommunityGroupMember(
            groupId: group.id,
            uid: user.uid,
          )
          .first;

      if (!mounted) return;

      if (!isMember) {
        _showMessage(
          'Join this group before creating a post.',
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateCommunityPostScreen(
            groupId: group.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to open post creator.',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<CommunityGroupModel?>(
          stream: ContentRepository.instance
              .communityGroupStream(
            widget.groupId,
          ),
          builder: (context, snapshot) {
            // ==================================================
            // LOADING
            // ==================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6B1FA2),
                ),
              );
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (snapshot.hasError) {
              return _buildError();
            }

            // ==================================================
            // GROUP
            // ==================================================

            final group = snapshot.data;

            if (group == null) {
              return _buildNotFound();
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ==============================================
                // GROUP HEADER
                // ==============================================

                SliverToBoxAdapter(
                  child: _buildHeader(group),
                ),

                // ==============================================
                // GROUP INFORMATION
                // ==============================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      0,
                    ),
                    child: _buildGroupInformation(
                      group,
                    ),
                  ),
                ),

                // ==============================================
                // MEMBERSHIP
                // ==============================================

                if (user != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        20,
                        20,
                        0,
                      ),
                      child: StreamBuilder<bool>(
                        stream: ContentRepository.instance
                            .isCommunityGroupMember(
                          groupId: group.id,
                          uid: user.uid,
                        ),
                        builder: (
                          context,
                          memberSnapshot,
                        ) {
                          final isMember =
                              memberSnapshot.data ?? false;

                          return _buildMembershipButton(
                            isMember,
                          );
                        },
                      ),
                    ),
                  ),

                // ==============================================
                // COMMUNITY HEADER
                // ==============================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      30,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Community',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3D004D),
                            ),
                          ),
                        ),

                        // MEMBERS
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommunityGroupMembersScreen(
                                  groupId: group.id,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Members',
                            style: TextStyle(
                              color: Color(0xFF6B1FA2),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // CREATE POST
                        IconButton(
                          tooltip: 'Create post',
                          onPressed: () {
                            _openCreatePost(group);
                          },
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFF6B1FA2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==============================================
                // COMMUNITY POST FEED
                // ==============================================

                SliverToBoxAdapter(
                  child: CommunityPostFeed(
                    groupId: widget.groupId,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // GROUP HEADER
  // ============================================================

  Widget _buildHeader(
    CommunityGroupModel group,
  ) {
    return SizedBox(
      height: 270,
      child: Stack(
        children: [
          Positioned.fill(
            child: group.coverImageUrl.isNotEmpty
                ? Image.network(
                    group.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _buildHeaderFallback();
                    },
                  )
                : _buildHeaderFallback(),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: .30,
                    ),
                    Colors.black.withValues(
                      alpha: .70,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: .35,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (group.department.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: .18,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      group.department,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER FALLBACK
  // ============================================================

  Widget _buildHeaderFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF58156F),
            Color(0xFF9B2F87),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.groups,
          color: Colors.white,
          size: 70,
        ),
      ),
    );
  }

  // ============================================================
  // GROUP INFORMATION
  // ============================================================

  Widget _buildGroupInformation(
    CommunityGroupModel group,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.people_outline,
              color: Color(0xFF6B1FA2),
              size: 21,
            ),
            const SizedBox(width: 7),
            Text(
              '${group.memberCount} '
              '${group.memberCount == 1 ? 'member' : 'members'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),

        if (group.description.isNotEmpty) ...[
          const SizedBox(height: 15),
          Text(
            group.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MEMBERSHIP BUTTON
  // ============================================================

  Widget _buildMembershipButton(
    bool isMember,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _joining
            ? null
            : isMember
                ? _leaveGroup
                : _joinGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: isMember
              ? const Color(0xFFF4EDF7)
              : const Color(0xFF6B1FA2),
          foregroundColor: isMember
              ? const Color(0xFF6B1FA2)
              : Colors.white,
          disabledBackgroundColor: isMember
              ? const Color(0xFFF4EDF7)
              : const Color(0xFF6B1FA2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: _joining
            ? SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isMember
                      ? const Color(0xFF6B1FA2)
                      : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    isMember
                        ? Icons.check_circle_outline
                        : Icons.group_add_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMember
                        ? 'Joined'
                        : 'Join Group',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
              'Unable to load group',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 55,
              color: Color(0xFF6B1FA2),
            ),
            const SizedBox(height: 15),
            const Text(
              'Group not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF6B1FA2),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Go Back',
              ),
            ),
          ],
        ),
      ),
    );
  }
}