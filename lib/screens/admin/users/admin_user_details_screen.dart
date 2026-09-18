import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../repositories/content_repository.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminUserDetailsScreen> createState() =>
      _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState
    extends State<AdminUserDetailsScreen> {
  final ContentRepository _repository =
      ContentRepository.instance;

  bool _busy = false;

  String _name(Map<String, dynamic> data) {
    final fullName =
        data['fullName']?.toString().trim() ?? '';

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final firstName =
        data['firstName']?.toString().trim() ?? '';

    final lastName =
        data['lastName']?.toString().trim() ?? '';

    return '$firstName $lastName'.trim().isEmpty
        ? 'Unnamed User'
        : '$firstName $lastName'.trim();
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return 'Not available';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _changeRole(
    String currentRole,
  ) async {
    final newRole =
        await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Change User Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_outline,
                ),
                title: const Text('Member'),
                trailing:
                    currentRole == 'member'
                        ? const Icon(
                            Icons.check,
                            color:
                                Color(0xFF6B1FA2),
                          )
                        : null,
                onTap: () =>
                    Navigator.pop(
                  context,
                  'member',
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings_outlined,
                ),
                title: const Text('Admin'),
                trailing:
                    currentRole == 'admin'
                        ? const Icon(
                            Icons.check,
                            color:
                                Color(0xFF6B1FA2),
                          )
                        : null,
                onTap: () =>
                    Navigator.pop(
                  context,
                  'admin',
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (newRole == null ||
        newRole == currentRole) {
      return;
    }

    await _runAction(() async {
      await _repository.updateUserRole(
        uid: widget.userId,
        role: newRole,
      );
    });
  }

  Future<void> _changeStatus(
    String currentStatus,
  ) async {
    final newStatus =
        await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Change Account Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                ),
                title: const Text('Active'),
                trailing:
                    currentStatus == 'active'
                        ? const Icon(
                            Icons.check,
                            color:
                                Color(0xFF6B1FA2),
                          )
                        : null,
                onTap: () =>
                    Navigator.pop(
                  context,
                  'active',
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.block,
                ),
                title: const Text('Disabled'),
                trailing:
                    currentStatus == 'disabled'
                        ? const Icon(
                            Icons.check,
                            color:
                                Color(0xFF6B1FA2),
                          )
                        : null,
                onTap: () =>
                    Navigator.pop(
                  context,
                  'disabled',
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (newStatus == null ||
        newStatus == currentStatus) {
      return;
    }

    await _runAction(() async {
      await _repository.updateUserAccountStatus(
        uid: widget.userId,
        accountStatus: newStatus,
      );
    });
  }

  Future<void> _deleteUser() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete User?',
          ),
          content: const Text(
            'This will permanently delete the user profile from Firestore. '
            'The Firebase Authentication account must also be removed '
            'through the trusted backend.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(() async {
      await _repository.deleteUserProfile(
        widget.userId,
      );
    });

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _runAction(
    Future<void> Function() action,
  ) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'User updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor:
              Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F5F8),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF6B1FA2),
        foregroundColor: Colors.white,
        title: const Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _repository
            .userProfileStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load user.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          final document = snapshot.data;

          if (document == null ||
              !document.exists) {
            return const Center(
              child: Text(
                'User no longer exists.',
              ),
            );
          }

          final data = document.data() ?? {};

          final name = _name(data);

          final email =
              data['email']?.toString() ??
                  'Not available';

          final firstName =
              data['firstName']?.toString() ?? '';

          final lastName =
              data['lastName']?.toString() ?? '';

          final language =
              data['language']?.toString() ?? 'en';

          final role =
              data['role']?.toString().toLowerCase() ??
                  'member';

          final status =
              data['accountStatus']
                      ?.toString()
                      .toLowerCase() ??
                  'active';

          final verified =
              data['emailVerified'] == true;

          final createdAt =
              _formatDate(data['createdAt']);

          final updatedAt =
              _formatDate(data['updatedAt']);

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHeader(
                    name: name,
                    email: email,
                    verified: verified,
                    role: role,
                    status: status,
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Personal Information',
                    children: [
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'First Name',
                        value: firstName.isEmpty
                            ? 'Not available'
                            : firstName,
                      ),
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Last Name',
                        value: lastName.isEmpty
                            ? 'Not available'
                            : lastName,
                      ),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                      ),
                      _InfoTile(
                        icon: Icons.language,
                        label: 'Language',
                        value: language,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Account',
                    children: [
                      _InfoTile(
                        icon:
                            Icons.admin_panel_settings_outlined,
                        label: 'Role',
                        value:
                            role.toUpperCase(),
                      ),
                      _InfoTile(
                        icon:
                            Icons.verified_user_outlined,
                        label: 'Email Verification',
                        value: verified
                            ? 'Verified'
                            : 'Not verified',
                      ),
                      _InfoTile(
                        icon: Icons.toggle_on_outlined,
                        label: 'Account Status',
                        value:
                            status.toUpperCase(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Registration',
                    children: [
                      _InfoTile(
                        icon:
                            Icons.calendar_today_outlined,
                        label: 'Created',
                        value: createdAt,
                      ),
                      _InfoTile(
                        icon:
                            Icons.update_outlined,
                        label: 'Last Updated',
                        value: updatedAt,
                      ),
                      _InfoTile(
                        icon: Icons.fingerprint,
                        label: 'User ID',
                        value: widget.userId,
                        selectable: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Admin Actions',
                    children: [
                      ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color:
                              Color(0xFF6B1FA2),
                        ),
                        title:
                            const Text(
                          'Change Role',
                        ),
                        subtitle: Text(
                          role == 'admin'
                              ? 'Administrator'
                              : 'Member',
                        ),
                        trailing:
                            const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: _busy
                            ? null
                            : () =>
                                _changeRole(
                                  role,
                                ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          status == 'disabled'
                              ? Icons
                                  .check_circle_outline
                              : Icons.block,
                          color:
                              const Color(
                            0xFF6B1FA2,
                          ),
                        ),
                        title:
                            const Text(
                          'Account Status',
                        ),
                        subtitle: Text(
                          status == 'disabled'
                              ? 'Disabled'
                              : 'Active',
                        ),
                        trailing:
                            const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: _busy
                            ? null
                            : () =>
                                _changeStatus(
                                  status,
                                ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color:
                              Colors.red.shade700,
                        ),
                        title: Text(
                          'Delete User',
                          style: TextStyle(
                            color:
                                Colors.red.shade700,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        subtitle:
                            const Text(
                          'Delete Firestore profile',
                        ),
                        onTap: _busy
                            ? null
                            : _deleteUser,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
              if (_busy)
                Positioned.fill(
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: 0.08),
                    child: const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(0xFF6B1FA2),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final bool verified;
  final String role;
  final String status;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.verified,
    required this.role,
    required this.status,
  });

  String _initials() {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                const Color(0xFF6B1FA2)
                    .withValues(alpha: 0.12),
            child: Text(
              _initials(),
              style: const TextStyle(
                color: Color(0xFF6B1FA2),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment:
                WrapAlignment.center,
            children: [
              _Badge(
                text: role.toUpperCase(),
              ),
              _Badge(
                text: verified
                    ? 'VERIFIED'
                    : 'UNVERIFIED',
              ),
              _Badge(
                text: status.toUpperCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF0E7F5),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B1FA2),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B1FA2),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selectable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 14,
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