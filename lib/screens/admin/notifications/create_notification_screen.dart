import 'package:flutter/material.dart';

import '../../../services/admin_notification_service.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({
    super.key,
  });

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState
    extends State<CreateNotificationScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _bodyController =
      TextEditingController();

  final TextEditingController _userIdController =
      TextEditingController();

  final TextEditingController _routeController =
      TextEditingController();

  final TextEditingController _imageObjectKeyController =
      TextEditingController();

  bool _sendToAll = true;
  bool _sending = false;

  String _type = 'announcement';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _userIdController.dispose();
    _routeController.dispose();
    _imageObjectKeyController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND
  // ============================================================

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _sending = true;
    });

    try {
      final String title =
          _titleController.text.trim();

      final String body =
          _bodyController.text.trim();

      final String route =
          _routeController.text.trim();

      final String imageObjectKey =
          _imageObjectKeyController.text.trim();

      final String? cleanRoute =
          route.isEmpty ? null : route;

      final String? cleanImageObjectKey =
          imageObjectKey.isEmpty
              ? null
              : imageObjectKey;

      final Map<String, dynamic> result;

      if (_sendToAll) {
        result =
            await AdminNotificationService.instance
                .sendToAllMembers(
          title: title,
          body: body,
          type: _type,
          route: cleanRoute,
          imageObjectKey: cleanImageObjectKey,
        );
      } else {
        final String userId =
            _userIdController.text.trim();

        result =
            await AdminNotificationService.instance
                .sendToMember(
          userId: userId,
          title: title,
          body: body,
          type: _type,
          route: cleanRoute,
          imageObjectKey: cleanImageObjectKey,
        );
      }

      if (!mounted) return;

      final dynamic resultData =
          result['result'];

      final int sent = _toInt(
        resultData is Map
            ? resultData['sent']
            : result['sent'],
      );

      final int failed = _toInt(
        resultData is Map
            ? resultData['failed']
            : result['failed'],
      );

      final int membersProcessed = _toInt(
        resultData is Map
            ? resultData['membersProcessed']
            : result['membersProcessed'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _sendToAll
                ? 'Notification sent. '
                    'Members processed: $membersProcessed, '
                    'devices sent: $sent, '
                    'failed: $failed.'
                : 'Notification sent. '
                    'Devices sent: $sent, '
                    'failed: $failed.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              Theme.of(context).colorScheme.error,
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
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Notification',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ==================================================
            // AUDIENCE
            // ==================================================

            const Text(
              'Notification Audience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(
                    Icons.groups_outlined,
                  ),
                  label: Text(
                    'All Members',
                  ),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(
                    Icons.person_outline,
                  ),
                  label: Text(
                    'Specific Member',
                  ),
                ),
              ],
              selected: {_sendToAll},
              onSelectionChanged: _sending
                  ? null
                  : (selection) {
                      setState(() {
                        _sendToAll =
                            selection.first;
                      });
                    },
            ),

            if (!_sendToAll) ...[
              const SizedBox(height: 20),

              TextFormField(
                controller: _userIdController,
                enabled: !_sending,
                decoration: const InputDecoration(
                  labelText: 'Member User ID',
                  hintText: 'Firebase Auth UID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_sendToAll) {
                    return null;
                  }

                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter the member user ID.';
                  }

                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            // ==================================================
            // TYPE
            // ==================================================

            const Text(
              'Notification Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                'announcement',
                'event',
                'sermon',
                'book',
                'community',
                'giving',
                'payment',
                'general',
              ].map(
                (type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type == 'announcement'
                              ? Icons.campaign_outlined
                              : type == 'event'
                                  ? Icons.event_outlined
                                  : type == 'sermon'
                                      ? Icons.play_circle_outline
                                      : type == 'book'
                                          ? Icons.menu_book_outlined
                                          : type == 'community'
                                              ? Icons.groups_outlined
                                              : type == 'giving'
                                                  ? Icons
                                                      .volunteer_activism_outlined
                                                  : type == 'payment'
                                                      ? Icons
                                                          .payments_outlined
                                                      : Icons
                                                          .notifications_outlined,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          type == 'announcement'
                              ? 'Announcement'
                              : type == 'event'
                                  ? 'Event'
                                  : type == 'sermon'
                                      ? 'Sermon'
                                      : type == 'book'
                                          ? 'Book'
                                          : type == 'community'
                                              ? 'Community'
                                              : type == 'giving'
                                                  ? 'Giving'
                                                  : type == 'payment'
                                                      ? 'Payment'
                                                      : 'General',
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
              onChanged: _sending
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _type = value;
                      });
                    },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // CONTENT
            // ==================================================

            const Text(
              'Notification Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              enabled: !_sending,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText:
                    'e.g. Sunday Service Reminder',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter a notification title.';
                }

                if (value.trim().length > 100) {
                  return 'Title is too long.';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _bodyController,
              enabled: !_sending,
              maxLength: 500,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText:
                    'Enter your notification message...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter a notification message.';
                }

                if (value.trim().length > 500) {
                  return 'Message is too long.';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            // ==================================================
            // ROUTE
            // ==================================================

            TextFormField(
              controller: _routeController,
              enabled: !_sending,
              decoration: const InputDecoration(
                labelText: 'App Route (optional)',
                hintText: '/events or /sermons',
                border: OutlineInputBorder(),
                helperText:
                    'Example: /notifications, /events, /sermons',
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // IMAGE OBJECT KEY
            // ==================================================

            TextFormField(
              controller:
                  _imageObjectKeyController,
              enabled: !_sending,
              decoration: const InputDecoration(
                labelText:
                    'Image Object Key (optional)',
                hintText:
                    'notifications/banner.jpg',
                border: OutlineInputBorder(),
                helperText:
                    'Use a B2 object key, never a URL.',
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SEND BUTTON
            // ==================================================

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                      ),
                label: Text(
                  _sending
                      ? 'Sending...'
                      : _sendToAll
                          ? 'Send to All Members'
                          : 'Send Notification',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // INFO
            // ==================================================

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The notification will be saved '
                      'to the member notification inbox '
                      'and sent to their registered mobile '
                      'devices.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}