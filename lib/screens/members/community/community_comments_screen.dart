import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/community_post_model.dart';
import '../../../models/community_comment_model.dart';
import '../../../repositories/content_repository.dart';

class CommunityCommentsScreen extends StatefulWidget {
  final String groupId;
  final CommunityPostModel post;

  const CommunityCommentsScreen({
    super.key,
    required this.groupId,
    required this.post,
  });

  @override
  State<CommunityCommentsScreen> createState() =>
      _CommunityCommentsScreenState();
}

class _CommunityCommentsScreenState
    extends State<CommunityCommentsScreen> {
  final TextEditingController _controller =
      TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND COMMENT
  // ============================================================

  Future<void> _sendComment() async {
    final user = FirebaseAuth.instance.currentUser;

    final text = _controller.text.trim();

    if (user == null || text.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final comment = CommunityCommentModel(
        id: '',
        postId: widget.post.id,
        authorId: user.uid,
        authorName: user.displayName ?? 'RHIC Member',
        authorPhotoUrl: user.photoURL ?? '',
        content: text,
        createdAt: null,
      );

      await ContentRepository.instance.addCommunityComment(
        groupId: widget.groupId,
        comment: comment,
      );

      if (!mounted) return;

      _controller.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to add comment.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Comments',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommunityCommentModel>>(
              stream: ContentRepository.instance
                  .communityCommentsStream(
                groupId: widget.groupId,
                postId: widget.post.id,
              ),
              builder: (context, snapshot) {
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B1FA2),
                    ),
                  );
                }

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return _buildError();
                }

                final comments = snapshot.data ?? [];

                // ------------------------------------------------
                // EMPTY
                // ------------------------------------------------

                if (comments.isEmpty) {
                  return _buildEmptyState();
                }

                // ------------------------------------------------
                // COMMENTS
                // ------------------------------------------------

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return _CommentTile(
                      comment: comments[index],
                    );
                  },
                );
              },
            ),
          ),

          // ======================================================
          // COMMENT INPUT
          // ======================================================

          _buildCommentInput(),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D004D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to comment on this post.',
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
            const SizedBox(height: 12),
            const Text(
              'Unable to load comments',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please try again later.',
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
  // COMMENT INPUT
  // ============================================================

  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          15,
          10,
          15,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: .06,
              ),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ----------------------------------------------------
            // TEXT FIELD
            // ----------------------------------------------------

            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) {
                  _sendComment();
                },
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  filled: true,
                  fillColor: const Color(0xFFF7F2F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ----------------------------------------------------
            // SEND BUTTON
            // ----------------------------------------------------

            GestureDetector(
              onTap: _sending ? null : _sendComment,
              child: Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6B1FA2),
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// COMMENT TILE
// ================================================================

class _CommentTile extends StatelessWidget {
  final CommunityCommentModel comment;

  const _CommentTile({
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // PROFILE PHOTO
          // ======================================================

          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF1D9F7),
            backgroundImage: comment.authorPhotoUrl.isNotEmpty
                ? NetworkImage(
                    comment.authorPhotoUrl,
                  )
                : null,
            child: comment.authorPhotoUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Color(0xFF6B1FA2),
                  )
                : null,
          ),

          const SizedBox(width: 10),

          // ======================================================
          // COMMENT CONTENT
          // ======================================================

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D004D),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}