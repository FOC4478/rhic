import 'package:flutter/material.dart';

import '../repositories/notification_repository.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconColor = Colors.white,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationRepository.instance
          .unreadCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.notifications_none,
                color: iconColor,
                size: iconSize,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7931E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99
                        ? '99+'
                        : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}