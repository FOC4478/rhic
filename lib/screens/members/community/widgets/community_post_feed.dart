
import 'package:flutter/material.dart';

import '../../../../models/community_post_model.dart';
import '../../../../repositories/content_repository.dart';
import 'community_post_card.dart';

class CommunityPostFeed extends StatelessWidget {
  final String groupId;

  const CommunityPostFeed({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPostModel>>(
      stream: ContentRepository.instance
          .communityPostsStream(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildError();
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _buildEmpty();
        }

        return Column(
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              child: CommunityPostCard(
                post: post,
                groupId: groupId,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE8C9ED),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.forum_outlined,
            size: 45,
            color: Color(0xFF8E3FC1),
          ),
          const SizedBox(height: 12),
          const Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D004D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Posts from this community will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Center(
        child: Text(
          'Unable to load community posts.',
          style: TextStyle(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}