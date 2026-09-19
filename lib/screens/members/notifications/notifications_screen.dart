import 'package:flutter/material.dart';

import '../../../models/notification_model.dart';
import '../../../repositories/notification_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
  });

  static const Color primaryPurple =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  @override
  Widget build(BuildContext context) {
    final repository =
        NotificationRepository.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      appBar: AppBar(
        backgroundColor: darkPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: repository.notificationsStream(),
            builder: (context, snapshot) {
              final notifications =
                  snapshot.data ?? const [];

              final hasUnread = notifications.any(
                (notification) =>
                    !notification.isRead,
              );

              if (!hasUnread) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: () async {
                  try {
                    await repository.markAllAsRead();
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to mark notifications as read: $error',
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Read all',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: repository.notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(
              message:
                  'Unable to load notifications.',
              onRetry: () {},
            );
          }

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
              ),
            );
          }

          final notifications =
              snapshot.data ?? const [];

          if (notifications.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: primaryPurple,
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification =
                    notifications[index];

                return _NotificationTile(
                  notification: notification,
                  onTap: () => _openNotification(
                    context,
                    notification,
                  ),
                  onDelete: () =>
                      _deleteNotification(
                    context,
                    notification,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // OPEN NOTIFICATION
  // ============================================================

  Future<void> _openNotification(
    BuildContext context,
    NotificationModel notification,
  ) async {
    final repository =
        NotificationRepository.instance;

    // ----------------------------------------------------------
    // MARK AS READ
    // ----------------------------------------------------------

    if (!notification.isRead) {
      try {
        await repository.markAsRead(
          notification.id,
        );
      } catch (error) {
        debugPrint(
          'Unable to mark notification as read: '
          '$error',
        );
      }
    }

    if (!context.mounted) {
      return;
    }

    // ----------------------------------------------------------
    // OPEN ACTION ROUTE
    // ----------------------------------------------------------

    final String? route =
        notification.actionRoute;

    if (route == null ||
        route.trim().isEmpty) {
      return;
    }

    String normalizedRoute =
        route.trim();

    if (!normalizedRoute.startsWith('/')) {
      normalizedRoute =
          '/$normalizedRoute';
    }

    try {
      await Navigator.of(context).pushNamed(
        normalizedRoute,
        arguments: notification.actionId,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open notification: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

  Future<void> _deleteNotification(
    BuildContext context,
    NotificationModel notification,
  ) async {
    try {
      await NotificationRepository.instance
          .deleteNotification(
        notification.id,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete notification: $error',
          ),
        ),
      );
    }
  }
}

// ============================================================
// NOTIFICATION TILE
// ============================================================

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool unread =
        !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction:
          DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: Material(
        color: unread
            ? const Color(0xFFF0E7F6)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                      BoxDecoration(
                    color: unread
                        ? const Color(
                            0xFF6B1FA2,
                          )
                        : const Color(
                            0xFFE9E6EC,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _notificationIcon(
                      notification.type,
                    ),
                    color: unread
                        ? Colors.white
                        : const Color(
                            0xFF6B1FA2,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 9,
                              height: 9,
                              decoration:
                                  const BoxDecoration(
                                color: Color(
                                  0xFF6B1FA2,
                                ),
                                shape:
                                    BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(
                          notification.createdAt,
                        ),
                        style: TextStyle(
                          color:
                              Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  IconData _notificationIcon(
    String type,
  ) {
    switch (type) {
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

      case 'payment':
        return Icons.payments_outlined;

      default:
        return Icons.notifications_none_outlined;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '';
    }

    final DateTime now =
        DateTime.now();

    final Duration difference =
        now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration:
                  const BoxDecoration(
                color: Color(0xFFEDE5F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 42,
                color: Color(0xFF6B1FA2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child:
                  const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}