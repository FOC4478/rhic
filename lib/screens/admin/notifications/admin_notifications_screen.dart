import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/admin_notification_service.dart';
import 'create_notification_screen.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({
    super.key,
  });

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = false;

  // ============================================================
  // OPEN CREATE NOTIFICATION
  // ============================================================

  Future<void> _openCreateNotification() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateNotificationScreen(),
      ),
    );
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> _deleteNotification(
    String userId,
    String notificationId,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete notification'),
          content: const Text(
            'Delete this notification from this member?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await AdminNotificationService.instance.deleteNotification(
        userId: userId,
        notificationId: notificationId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // SORT NOTIFICATIONS
  // ============================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _sortNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final sorted = List<
        QueryDocumentSnapshot<Map<String, dynamic>>
      >.from(documents);

    sorted.sort((a, b) {
      final Timestamp? aTimestamp =
          a.data()['createdAt'] is Timestamp
              ? a.data()['createdAt'] as Timestamp
              : null;

      final Timestamp? bTimestamp =
          b.data()['createdAt'] is Timestamp
              ? b.data()['createdAt'] as Timestamp
              : null;

      if (aTimestamp == null && bTimestamp == null) {
        return 0;
      }

      if (aTimestamp == null) {
        return 1;
      }

      if (bTimestamp == null) {
        return -1;
      }

      return bTimestamp.compareTo(aTimestamp);
    });

    return sorted;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
        actions: [
          IconButton(
            tooltip: 'Create notification',
            onPressed: _openCreateNotification,
            icon: const Icon(
              Icons.add_alert_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateNotification,
        icon: const Icon(
          Icons.notifications_active_outlined,
        ),
        label: const Text(
          'Create',
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collectionGroup('notifications')
                .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load notifications.\n\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final documents = _sortNotifications(
                snapshot.data?.docs ?? [],
              );

              if (documents.isEmpty) {
                return _EmptyNotifications(
                  onCreate: _openCreateNotification,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ),
                itemCount: documents.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (
                  context,
                  index,
                ) {
                  final document = documents[index];

                  final data = document.data();

                  final String userId =
                      document.reference.parent.parent?.id ?? '';

                  return _NotificationCard(
                    data: data,
                    onDelete: userId.isEmpty
                        ? null
                        : () => _deleteNotification(
                              userId,
                              document.id,
                            ),
                  );
                },
              );
            },
          ),

          // ======================================================
          // LOADING OVERLAY
          // ======================================================

          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// NOTIFICATION CARD
// ================================================================

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.data,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String title =
        data['title']?.toString() ?? 'Notification';

    final String body =
        data['body']?.toString() ?? '';

    final String type =
        data['type']?.toString() ?? 'general';

    final bool read =
        data['read'] == true;

    final Timestamp? timestamp =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    final String dateText = timestamp == null
        ? ''
        : _formatDate(timestamp.toDate());

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor:
              const Color(0xFF6B1FA2).withValues(
            alpha: 0.12,
          ),
          child: Icon(
            _notificationIcon(type),
            color: const Color(0xFF6B1FA2),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight:
                read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                '$type'
                '${dateText.isEmpty ? '' : ' • $dateText'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),
        trailing: onDelete == null
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete!();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData _notificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payment':
        return Icons.payments_outlined;

      case 'event':
        return Icons.event_outlined;

      case 'sermon':
        return Icons.play_circle_outline;

      case 'book':
        return Icons.menu_book_outlined;

      case 'community':
        return Icons.groups_outlined;

      case 'giving':
        return Icons.volunteer_activism_outlined;

      case 'announcement':
        return Icons.campaign_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a notification to send '
              'an announcement to your members.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(
                Icons.add_alert,
              ),
              label: const Text(
                'Create Notification',
              ),
            ),
          ],
        ),
      ),
    );
  }
}