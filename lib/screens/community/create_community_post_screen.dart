import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community_post_model.dart';
import '../../repositories/content_repository.dart';

class CreateCommunityPostScreen extends StatefulWidget {
  final String groupId;

  const CreateCommunityPostScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<CreateCommunityPostScreen> createState() =>
      _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState
    extends State<CreateCommunityPostScreen> {
  final TextEditingController _controller =
      TextEditingController();

  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;

    final content = _controller.text.trim();

    if (user == null) {
      _showMessage(
        'Please sign in before creating a post.',
      );
      return;
    }

    if (content.isEmpty) {
      _showMessage(
        'Write something first.',
      );
      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      // --------------------------------------------------------
      // CREATE POST MODEL
      // --------------------------------------------------------

      final post = CommunityPostModel(
        id: '',
        groupId: widget.groupId,
        authorId: user.uid,
        authorName:
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'RHIC Member',
        authorPhotoUrl: user.photoURL ?? '',
        content: content,
        imageUrls: const [],
        likeCount: 0,
        commentCount: 0,
        isEdited: false,
        createdAt: null,
        updatedAt: null,
        isPinned: false,
      );

      // --------------------------------------------------------
      // SAVE POST
      // --------------------------------------------------------

      await ContentRepository.instance.createCommunityPost(
        post: post,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to create post.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'RHIC Member';

    final photoUrl = user?.photoURL ?? '';

    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D004D),
        elevation: 0,

        actions: [
          TextButton(
            onPressed: _posting
                ? null
                : _createPost,
            child: Text(
              _posting ? 'Posting...' : 'Post',
              style: TextStyle(
                color: _posting
                    ? Colors.grey
                    : const Color(0xFF6B1FA2),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ====================================================
            // USER INFORMATION
            // ====================================================

            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color(0xFFF1D9F7),
                  backgroundImage:
                      photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                  child: photoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color:
                              Color(0xFF6B1FA2),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                      color: Color(0xFF3D004D),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ====================================================
            // POST CONTENT
            // ====================================================

            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical:
                    TextAlignVertical.top,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'What would you like to share with the community?',
                  filled: true,
                  fillColor:
                      const Color(0xFFF9F4FA),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                    borderSide:
                        BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.all(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}