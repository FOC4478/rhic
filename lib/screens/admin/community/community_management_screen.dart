import 'package:flutter/material.dart';

import '../../../models/community_group_model.dart';
import '../../../models/community_member_model.dart';
import '../../../models/community_post_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../services/media_url_service.dart';

class CommunityManagementScreen extends StatefulWidget {
  final String groupId;

  const CommunityManagementScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<CommunityManagementScreen> createState() =>
      _CommunityManagementScreenState();
}

class _CommunityManagementScreenState
    extends State<CommunityManagementScreen>
    with SingleTickerProviderStateMixin {
  final ContentRepository _repository = ContentRepository.instance;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3D004D),
        foregroundColor: Colors.white,
        title: StreamBuilder<CommunityGroupModel?>(
          stream: _repository.communityGroupStream(
            widget.groupId,
          ),
          builder: (context, snapshot) {
            return Text(
              snapshot.data?.name ?? 'Community Management',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFF7931E),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Members',
            ),
            Tab(
              icon: Icon(Icons.article),
              text: 'Posts',
            ),
            Tab(
              icon: Icon(Icons.person_add),
              text: 'Requests',
            ),
          ],
        ),
      ),
      body: StreamBuilder<CommunityGroupModel?>(
        stream: _repository.communityGroupStream(
          widget.groupId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load community.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          final group = snapshot.data;

          if (group == null) {
            return const Center(
              child: Text(
                'Community not found.',
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                group: group,
                repository: _repository,
                onRefresh: () {
                  setState(() {});
                },
              ),
              _MembersTab(
                group: group,
                repository: _repository,
              ),
              _PostsTab(
                group: group,
                repository: _repository,
              ),
              _RequestsTab(
                group: group,
                repository: _repository,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final CommunityGroupModel group;
  final ContentRepository repository;
  final VoidCallback onRefresh;

  const _OverviewTab({
    required this.group,
    required this.repository,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OverviewHeader(
            group: group,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;

              final cards = [
                _InfoCard(
                  icon: Icons.people,
                  title: 'Members',
                  value: group.memberCount.toString(),
                ),
                _InfoCard(
                  icon: Icons.public,
                  title: 'Status',
                  value: group.isPublished
                      ? 'Published'
                      : 'Unpublished',
                ),
                _InfoCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Community Admin',
                  value: group.adminName.isEmpty
                      ? 'Not assigned'
                      : group.adminName,
                ),
                _InfoCard(
                  icon: Icons.approval,
                  title: 'Membership',
                  value: group.requiresApproval
                      ? 'Approval Required'
                      : 'Open Join',
                ),
              ];

              if (isSmall) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 3.2,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Community Information',
            child: Column(
              children: [
                _DetailRow(
                  label: 'Name',
                  value: group.name,
                ),
                _DetailRow(
                  label: 'Department',
                  value: group.department.isEmpty
                      ? 'Not specified'
                      : group.department,
                ),
                _DetailRow(
                  label: 'Admin',
                  value: group.adminName.isEmpty
                      ? 'Not assigned'
                      : group.adminName,
                ),
                _DetailRow(
                  label: 'Admin UID',
                  value: group.adminId.isEmpty
                      ? 'Not assigned'
                      : group.adminId,
                ),
                _DetailRow(
                  label: 'Membership policy',
                  value: group.requiresApproval
                      ? 'Members require approval'
                      : 'Anyone can join',
                ),
                _DetailRow(
                  label: 'Visibility',
                  value: group.isPublished
                      ? 'Published to members'
                      : 'Hidden from members',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final CommunityGroupModel group;
  final ContentRepository repository;

  const _MembersTab({
    required this.group,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityMemberModel>>(
      stream: repository.communityGroupMembersStream(
        group.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load members.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6B1FA2),
            ),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return const _NoData(
            icon: Icons.people_outline,
            title: 'No members yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];

            final isGroupAdmin = member.uid == group.adminId;

            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                leading: _MemberAvatar(
                  objectKey: member.photoObjectKey,
                ),
                title: Text(
                  member.name.isEmpty
                      ? 'RHIC Member'
                      : member.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  isGroupAdmin
                      ? 'Community Admin'
                      : 'Member',
                ),
                trailing: isGroupAdmin
                    ? const Chip(
                        label: Text(
                          'Admin',
                        ),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'remove') {
                            await _removeMember(
                              context,
                              group,
                              member,
                              repository,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text(
                              'Remove Member',
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    CommunityGroupModel group,
    CommunityMemberModel member,
    ContentRepository repository,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Member?',
          ),
          content: Text(
            'Remove ${member.name} from ${group.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await repository.removeCommunityGroupMember(
        groupId: group.id,
        uid: member.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Member removed.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _PostsTab extends StatelessWidget {
  final CommunityGroupModel group;
  final ContentRepository repository;

  const _PostsTab({
    required this.group,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPostModel>>(
      stream: repository.communityPostsStream(
        group.id,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load posts.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6B1FA2),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return const _NoData(
            icon: Icons.article_outlined,
            title: 'No posts yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            return _AdminPostCard(
              post: post,
              group: group,
              repository: repository,
            );
          },
        );
      },
    );
  }
}

class _AdminPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final CommunityGroupModel group;
  final ContentRepository repository;

  const _AdminPostCard({
    required this.post,
    required this.group,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE7D3EF),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF6B1FA2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName.isEmpty
                            ? 'RHIC Member'
                            : post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (post.isPinned)
                        const Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B1FA2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'pin') {
                      try {
                        await repository.toggleCommunityPostPin(
                          groupId: group.id,
                          postId: post.id,
                          isPinned: !post.isPinned,
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }

                      return;
                    }

                    if (value == 'delete') {
                      if (!context.mounted) return;

                      await _deletePost(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(
                        post.isPinned
                            ? 'Unpin Post'
                            : 'Pin Post',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Post',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  '${post.likeCount}',
                ),
                const SizedBox(width: 20),
                const Icon(
                  Icons.comment_outlined,
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  '${post.commentCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post?',
          ),
          content: const Text(
            'This post will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await repository.deleteCommunityPost(
        groupId: group.id,
        postId: post.id,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _RequestsTab extends StatelessWidget {
  final CommunityGroupModel group;
  final ContentRepository repository;

  const _RequestsTab({
    required this.group,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            const Text(
              'Membership Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3D004D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.requiresApproval
                  ? 'This community requires membership approval.'
                  : 'This community currently allows members to join directly.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'The approval request system will be connected when we update the Community membership model.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final CommunityGroupModel group;

  const _OverviewHeader({
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _CommunityCoverImage(
            objectKey: group.coverImageObjectKey,
            width: 80,
            height: 80,
            borderRadius: 14,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D004D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  group.description.isEmpty
                      ? 'No description'
                      : group.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityCoverImage extends StatelessWidget {
  final String objectKey;
  final double width;
  final double height;
  final double borderRadius;

  const _CommunityCoverImage({
    required this.objectKey,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cleanedKey = objectKey.trim();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE7D3EF),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: cleanedKey.isEmpty
          ? const Icon(
              Icons.groups,
              size: 38,
              color: Color(0xFF6B1FA2),
            )
          : FutureBuilder<String>(
              future: MediaUrlService.instance.getCommunityMediaUrl(
                objectKey: cleanedKey,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6B1FA2),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.trim().isEmpty) {
                  return const Icon(
                    Icons.groups,
                    size: 38,
                    color: Color(0xFF6B1FA2),
                  );
                }

                return Image.network(
                  snapshot.data!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.groups,
                      size: 38,
                      color: Color(0xFF6B1FA2),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String objectKey;

  const _MemberAvatar({
    required this.objectKey,
  });

  @override
  Widget build(BuildContext context) {
    final cleanedKey = objectKey.trim();

    if (cleanedKey.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFE7D3EF),
        child: Icon(
          Icons.person,
          color: Color(0xFF6B1FA2),
        ),
      );
    }

    return FutureBuilder<String>(
      future: MediaUrlService.instance.getCommunityMediaUrl(
        objectKey: cleanedKey,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            backgroundColor: Color(0xFFE7D3EF),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6B1FA2),
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.trim().isEmpty) {
          return const CircleAvatar(
            backgroundColor: Color(0xFFE7D3EF),
            child: Icon(
              Icons.person,
              color: Color(0xFF6B1FA2),
            ),
          );
        }

        return CircleAvatar(
          backgroundColor: const Color(0xFFE7D3EF),
          backgroundImage: NetworkImage(
            snapshot.data!,
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B1FA2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3D004D),
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  final IconData icon;
  final String title;

  const _NoData({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 65,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}