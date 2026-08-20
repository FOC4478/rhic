import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/community_post_model.dart';
import '../../../repositories/content_repository.dart';
import '../community_comments_screen.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final String groupId;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEDE5F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // AUTHOR
            Row(
              children: [
                _buildAvatar(),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.more_horiz,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // CONTENT
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF303030),
                ),
              ),

            // IMAGE
            if (post.authorPhotoUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),
                child: Image.network(
                  post.authorPhotoUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const SizedBox();
                  },
                ),
              ),
            ],

            const SizedBox(height: 15),

            // COUNTS
            Row(
              children: [
                const Icon(
                  Icons.favorite,
                  size: 16,
                  color: Color(0xFF6B1FA2),
                ),
                const SizedBox(width: 5),
                Text(
                  '${post.likeCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${post.commentCount} comments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),

            // ACTIONS
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<bool>(
                    stream: user == null
                        ? null
                        : ContentRepository.instance
                            .isPostLiked(
                            groupId: groupId,
                            postId: post.id,
                            uid: user.uid,
                          ),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      final liked =
                          snapshot.data ?? false;

                      return _PostActionButton(
                        icon: liked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: 'Like',
                        active: liked,
                        onTap: user == null
                            ? null
                            : () {
                                ContentRepository
                                    .instance
                                    .togglePostLike(
                                  groupId: groupId,
                                  postId: post.id,
                                  uid: user.uid,
                                );
                              },
                      );
                    },
                  ),
                ),

                Expanded(
                  child: _PostActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Comment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommunityCommentsScreen(
                            groupId: groupId,
                            post: post,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: _PostActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Post sharing will be available soon.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (post.authorPhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage:
            NetworkImage(post.authorPhotoUrl),
      );
    }

    return const CircleAvatar(
      radius: 22,
      backgroundColor: Color(0xFFF1D9F7),
      child: Icon(
        Icons.person,
        color: Color(0xFF6B1FA2),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }

    final date = timestamp.toDate();

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12
        ? 'PM'
        : 'AM';

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute $period';
  }
}

class _PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _PostActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: active
                  ? const Color(0xFF6B1FA2)
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active
                    ? const Color(0xFF6B1FA2)
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}