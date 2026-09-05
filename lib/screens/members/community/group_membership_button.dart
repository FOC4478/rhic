import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../repositories/content_repository.dart';

class GroupMembershipButton extends StatefulWidget {
  final String groupId;

  const GroupMembershipButton({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupMembershipButton> createState() =>
      _GroupMembershipButtonState();
}

class _GroupMembershipButtonState
    extends State<GroupMembershipButton> {
  bool _isLoading = false;

  Future<void> _joinGroup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please sign in to join this group.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ContentRepository.instance
          .joinCommunityGroup(
        groupId: widget.groupId,
        uid: user.uid,
      );

      if (mounted) {
        _showMessage(
          'You joined the group.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to join the group.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _leaveGroup() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Leave Group?',
          ),
          content: const Text(
            'You will no longer have access to this group.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ContentRepository.instance
          .leaveCommunityGroup(
        groupId: widget.groupId,
        uid: user.uid,
      );

      if (mounted) {
        _showMessage(
          'You left the group.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to leave the group.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/login',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF6B1FA2),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(26),
            ),
          ),
          child: const Text(
            'Sign in to join',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: ContentRepository.instance
          .isCommunityGroupMember(
        groupId: widget.groupId,
        uid: user.uid,
      ),
      builder: (
        context,
        snapshot,
      ) {
        final isMember =
            snapshot.data ?? false;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : isMember
                    ? _leaveGroup
                    : _joinGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: isMember
                  ? const Color(0xFFF1EAF4)
                  : const Color(0xFF6B1FA2),
              foregroundColor: isMember
                  ? const Color(0xFF6B1FA2)
                  : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(26),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isMember
                          ? const Color(
                              0xFF6B1FA2,
                            )
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
                        size: 21,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMember
                            ? 'Joined'
                            : 'Join Group',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}