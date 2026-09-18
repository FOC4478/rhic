import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../repositories/content_repository.dart';
import 'admin_user_details_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() =>
      _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ContentRepository _repository =
      ContentRepository.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final query =
        _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    final data = document.data() ?? {};

    final firstName =
        data['firstName']?.toString().toLowerCase() ?? '';

    final lastName =
        data['lastName']?.toString().toLowerCase() ?? '';

    final fullName =
        data['fullName']?.toString().toLowerCase() ?? '';

    final email =
        data['email']?.toString().toLowerCase() ?? '';

    final uid =
        data['uid']?.toString().toLowerCase() ?? document.id;

    return firstName.contains(query) ||
        lastName.contains(query) ||
        fullName.contains(query) ||
        email.contains(query) ||
        uid.toLowerCase().contains(query);
  }

  bool _matchesFilter(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final verified = data['emailVerified'] == true;

    final status =
        data['accountStatus']?.toString().toLowerCase() ??
            'active';

    switch (_filter) {
      case 'verified':
        return verified;

      case 'unverified':
        return !verified;

      case 'active':
        return status == 'active';

      case 'disabled':
        return status == 'disabled';

      default:
        return true;
    }
  }

  String _displayName(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final fullName =
        data['fullName']?.toString().trim() ?? '';

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final firstName =
        data['firstName']?.toString().trim() ?? '';

    final lastName =
        data['lastName']?.toString().trim() ?? '';

    final name =
        '$firstName $lastName'.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Unnamed User';
  }

  String _email(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return data['email']?.toString() ?? 'No email';
  }

  String _role(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return data['role']?.toString().toLowerCase() ??
        'member';
  }

  String _status(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return data['accountStatus']
            ?.toString()
            .toLowerCase() ??
        'active';
  }

  bool _isVerified(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return data['emailVerified'] == true;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _openUser(
    DocumentSnapshot<Map<String, dynamic>> user,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailsScreen(
          userId: user.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6B1FA2),
        foregroundColor: Colors.white,
        title: const Text(
          'Users',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<
          List<DocumentSnapshot<Map<String, dynamic>>>>(
        stream: _repository.adminUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {});
              },
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

          final users = snapshot.data ?? [];

          final filteredUsers = users
              .where(_matchesSearch)
              .where(_matchesFilter)
              .toList();

          return Column(
            children: [
              _buildHeader(users.length),
              _buildSearch(),
              _buildFilters(),
              Expanded(
                child: filteredUsers.isEmpty
                    ? _EmptyUsers(
                        searchActive:
                            _searchController.text
                                .trim()
                                .isNotEmpty ||
                                _filter != 'all',
                      )
                    : RefreshIndicator(
                        color:
                            const Color(0xFF6B1FA2),
                        onRefresh: () async {
                          setState(() {});
                          await Future<void>.delayed(
                            const Duration(milliseconds: 300),
                          );
                        },
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount:
                              filteredUsers.length,
                          separatorBuilder:
                              (_, __) =>
                                  const SizedBox(height: 10),
                          itemBuilder:
                              (context, index) {
                            final user =
                                filteredUsers[index];

                            return _UserCard(
                              user: user,
                              name: _displayName(user),
                              email: _email(user),
                              role: _role(user),
                              status: _status(user),
                              verified:
                                  _isVerified(user),
                              initials: _initials(
                                _displayName(user),
                              ),
                              onTap: () =>
                                  _openUser(user),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int totalUsers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF6B1FA2),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'User Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage RHIC member accounts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '$totalUsers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Users',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText:
              'Search name, email or user ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon:
                          const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = <String, String>{
      'all': 'All',
      'verified': 'Verified',
      'unverified': 'Unverified',
      'active': 'Active',
      'disabled': 'Disabled',
    };

    return SizedBox(
      height: 52,
      child: ListView(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection: Axis.horizontal,
        children: filters.entries.map((entry) {
          final selected =
              _filter == entry.key;

          return Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filter = entry.key;
                });
              },
              selectedColor:
                  const Color(0xFF6B1FA2),
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black87,
                fontWeight:
                    selected
                        ? FontWeight.w700
                        : FontWeight.w500,
              ),
              backgroundColor: Colors.white,
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> user;
  final String name;
  final String email;
  final String role;
  final String status;
  final bool verified;
  final String initials;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.verified,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final isDisabled = status == 'disabled';

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    const Color(0xFF6B1FA2)
                        .withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF6B1FA2),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified,
                            size: 17,
                            color:
                                Color(0xFF1976D2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _StatusBadge(
                          text: isAdmin
                              ? 'ADMIN'
                              : 'MEMBER',
                          background:
                              isAdmin
                                  ? const Color(
                                      0xFFFFF3E0,
                                    )
                                  : const Color(
                                      0xFFF0E7F5,
                                    ),
                          foreground:
                              isAdmin
                                  ? const Color(
                                      0xFFE65100,
                                    )
                                  : const Color(
                                      0xFF6B1FA2,
                                    ),
                        ),
                        _StatusBadge(
                          text: verified
                              ? 'VERIFIED'
                              : 'UNVERIFIED',
                          background:
                              verified
                                  ? const Color(
                                      0xFFE8F5E9,
                                    )
                                  : const Color(
                                      0xFFFFF3E0,
                                    ),
                          foreground:
                              verified
                                  ? const Color(
                                      0xFF2E7D32,
                                    )
                                  : const Color(
                                      0xFFE65100,
                                    ),
                        ),
                        _StatusBadge(
                          text: isDisabled
                              ? 'DISABLED'
                              : 'ACTIVE',
                          background:
                              isDisabled
                                  ? const Color(
                                      0xFFFFEBEE,
                                    )
                                  : const Color(
                                      0xFFE8F5E9,
                                    ),
                          foreground:
                              isDisabled
                                  ? const Color(
                                      0xFFC62828,
                                    )
                                  : const Color(
                                      0xFF2E7D32,
                                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _StatusBadge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  final bool searchActive;

  const _EmptyUsers({
    required this.searchActive,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              searchActive
                  ? Icons.search_off
                  : Icons.people_outline,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              searchActive
                  ? 'No users found'
                  : 'No users yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searchActive
                  ? 'Try another search or filter.'
                  : 'Registered users will appear here.',
              textAlign: TextAlign.center,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}