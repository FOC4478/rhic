import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../library/library_screen.dart';
import '../../../models/order_model.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const Color purple = Color(0xFF6B1FA2);
  static const Color darkPurple = Color(0xFF3D004D);
  static const Color background = Color(0xFFFCFAFD);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final name =
              data['name']?.toString().trim().isNotEmpty == true
                  ? data['name'].toString()
                  : user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!
                      : 'User';

          final email = user.email ?? '';

          final photoUrl =
              data['photoUrl']?.toString() ??
                  user.photoURL ??
                  '';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              35,
            ),
            children: [
              _ProfileHeader(
                name: name,
                email: email,
                photoUrl: photoUrl,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const _SectionTitle(
                title: 'My Activity',
              ),

              const SizedBox(height: 10),

              _AccountCard(
                icon: Icons.menu_book_outlined,
                title: 'My Library',
                subtitle:
                    'Access your saved and downloaded resources',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LibraryScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle:
                    'View your book orders and payment status',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrdersScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.favorite_border,
                title: 'My Favorites',
                subtitle:
                    'View resources you have saved',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FavoritesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'Account',
              ),

              const SizedBox(height: 10),

              _AccountCard(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle:
                    'Change your name and profile information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle:
                    'View your notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle:
                    'Manage your app preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.lock_outline,
                title: 'Security',
                subtitle:
                    'Manage your password and account security',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SecurityScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const _SectionTitle(
                title: 'Support',
              ),

              const SizedBox(height: 10),

              _AccountCard(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle:
                    'Get help with the RHIC app',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle:
                    'Read how your information is handled',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),

              _AccountCard(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle:
                    'Read the RHIC app terms',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const TermsConditionsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _SignOutCard(
                onTap: () => _showSignOutDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSignOutDialog(
    BuildContext context,
  ) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Sign out?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: darkPurple,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out of your RHIC account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: purple,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }
}

// ============================================================
// PROFILE HEADER
// ============================================================

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6B1FA2),
            Color(0xFF3D004D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white24,
            backgroundImage:
                photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
            child: photoUrl.isEmpty
                ? Text(
                    _initials(name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }
}

// ============================================================
// ACCOUNT CARD
// ============================================================

class _AccountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF2E8F5),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6B1FA2),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF3D004D),
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF3D004D),
      ),
    );
  }
}

// ============================================================
// EDIT PROFILE
// ============================================================

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController =
      TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    final user =
        FirebaseAuth.instance.currentUser;

    _nameController.text =
        user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final name =
        _nameController.text.trim();

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': name,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updateDisplayName(name);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update profile: $e',
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

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor:
                    const Color(0xFFEDE0F2),
                child: const Icon(
                  Icons.person,
                  size: 45,
                  color: Color(0xFF6B1FA2),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Full Name',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D004D),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _nameController,
              textCapitalization:
                  TextCapitalization.words,
              decoration:
                  _inputDecoration(
                'Enter your name',
                Icons.person_outline,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter your name.';
                }

                if (value.trim().length < 2) {
                  return 'Name is too short.';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Email Address',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D004D),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              initialValue: user?.email ?? '',
              readOnly: true,
              decoration:
                  _inputDecoration(
                'Email address',
                Icons.email_outlined,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6B1FA2),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.grey.shade300,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(26),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ORDERS
// ============================================================

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('book_orders')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        );

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your orders.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No orders yet',
              message:
                  'Your digital book orders will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order =
                  OrderModel.fromFirestore(
                docs[index],
              );

              return _OrderCard(
                order: order,
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({
    required this.order,
  });

  Color _statusColor() {
    switch (order.status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    final itemCount = order.items.fold<int>(
  0,
  (totalItems, item) => totalItems + item.quantity,
);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OrderDetailsScreen(
              order: order,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF6B1FA2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF3D004D),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        statusColor.withAlpha(25),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.currency} ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF3D004D),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ORDER DETAILS
// ============================================================

class OrderDetailsScreen
    extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoBox(
            title: 'Payment Status',
            child: Text(
              order.status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _statusColor(
                  order.status,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _InfoBox(
            title: 'Payment Method',
            child: Text(
              order.paymentMethod
                  .replaceAll('_', ' ')
                  .toUpperCase(),
            ),
          ),

          if (order.paymentReference
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoBox(
              title: 'Payment Reference',
              child: Text(
                order.paymentReference,
              ),
            ),
          ],

          const SizedBox(height: 20),

          const Text(
            'Books',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 10),

          ...order.items.map(
            (item) => Container(
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: SizedBox(
                      width: 55,
                      height: 70,
                      child: item.coverUrl
                              .isNotEmpty
                          ? Image.network(
                              item.coverUrl,
                              fit: BoxFit.cover,
                            )
                          : const ColoredBox(
                              color:
                                  Color(0xFFF3EAF5),
                              child: Icon(
                                Icons
                                    .menu_book_outlined,
                                color:
                                    Color(0xFF6B1FA2),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF3D004D),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${item.currency} ${item.price.toStringAsFixed(2)} × ${item.quantity}',
                          style:
                              const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.currency} ${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF6B1FA2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${order.currency} ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        Color(0xFF3D004D),
                  ),
                ),
              ],
            ),
          ),

          if (order.adminNote
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoBox(
              title: 'Administrator Note',
              child: Text(
                order.adminNote,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

// ============================================================
// FAVORITES
// ============================================================

class FavoritesScreen
    extends StatelessWidget {
  const FavoritesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your favorites.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _EmptyState(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message:
                  'Resources you save as favorites will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data =
                  docs[index].data();

              return ListTile(
                tileColor: Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                leading: const CircleAvatar(
                  backgroundColor:
                      Color(0xFFEDE0F2),
                  child: Icon(
                    Icons.favorite,
                    color:
                        Color(0xFF6B1FA2),
                  ),
                ),
                title: Text(
                  data['title']?.toString() ??
                      'Favorite resource',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  data['type']?.toString() ??
                      'Resource',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// NOTIFICATIONS
// ============================================================

class NotificationsScreen
    extends StatelessWidget {
  const NotificationsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Unable to load notifications.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _EmptyState(
              icon:
                  Icons.notifications_none,
              title: 'No notifications',
              message:
                  'You are all caught up.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data =
                  docs[index].data();

              final isRead =
                  data['isRead'] == true;

              return Container(
                padding:
                    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isRead
                          ? Icons
                              .notifications_none
                          : Icons
                              .notifications_active,
                      color:
                          const Color(0xFF6B1FA2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title']
                                    ?.toString() ??
                                'Notification',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            data['message']
                                    ?.toString() ??
                                '',
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsScreen
    extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool notifications = true;
  bool emailUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 10),

          _SettingsTile(
            icon: Icons.notifications_none,
            title: 'Push Notifications',
            subtitle:
                'Receive notifications from RHIC',
            trailing: Switch(
              value: notifications,
              activeThumbColor:
                  const Color(0xFF6B1FA2),
              onChanged: (value) {
                setState(() {
                  notifications = value;
                });
              },
            ),
          ),

          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email Updates',
            subtitle:
                'Receive important updates by email',
            trailing: Switch(
              value: emailUpdates,
              activeThumbColor:
                  const Color(0xFF6B1FA2),
              onChanged: (value) {
                setState(() {
                  emailUpdates = value;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Language',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3D004D),
            ),
          ),

          const SizedBox(height: 10),

          _SettingsTile(
            icon: Icons.language,
            title: 'App Language',
            subtitle:
                'Change the language used in RHIC',
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Language selection is managed from the language settings.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(
          Icons.circle,
          color: Color(0xFF6B1FA2),
          size: 10,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

// ============================================================
// SECURITY
// ============================================================

class SecurityScreen
    extends StatelessWidget {
  const SecurityScreen({
    super.key,
  });

  Future<void> _changePassword(
    BuildContext context,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    final email = user?.email;

    if (email == null ||
        email.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No email address is associated with this account.',
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset instructions have been sent to your email.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to send password reset email: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Security',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF6B1FA2),
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your account',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ??
                            'No email',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _AccountCard(
            icon: Icons.lock_reset,
            title: 'Change Password',
            subtitle:
                'Receive an email to reset your password',
            onTap: () {
              _changePassword(context);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELP & SUPPORT
// ============================================================

class HelpSupportScreen
    extends StatelessWidget {
  const HelpSupportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _HelpTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Book Orders',
            text:
                'After making a bank transfer for a digital book, your order remains pending until an administrator verifies the payment.',
          ),
          _HelpTile(
            icon: Icons.menu_book_outlined,
            title: 'My Library',
            text:
                'Your purchased or downloaded resources can be accessed from My Library.',
          ),
          _HelpTile(
            icon: Icons.person_outline,
            title: 'Account',
            text:
                'You can update your name from the Edit Profile section.',
          ),
          _HelpTile(
            icon: Icons.support_agent_outlined,
            title: 'Need More Help?',
            text:
                'Contact the RHIC administration for assistance with payments, orders, account access, or other issues.',
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(0xFF6B1FA2),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF3D004D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              height: 1.5,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRIVACY POLICY
// ============================================================

class PrivacyPolicyScreen
    extends StatelessWidget {
  const PrivacyPolicyScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Privacy Policy',
      sections: [
        _LegalSection(
          title: 'Your Information',
          text:
              'RHIC may store information required to provide account, content, community, library, and digital shop features.',
        ),
        _LegalSection(
          title: 'Account Information',
          text:
              'Your account information is used to identify your account and provide personalized features.',
        ),
        _LegalSection(
          title: 'Digital Purchases',
          text:
              'Order information may be stored to process and verify digital book purchases.',
        ),
        _LegalSection(
          title: 'Security',
          text:
              'Reasonable technical measures are used to protect information stored within the application and its connected services.',
        ),
      ],
    );
  }
}

// ============================================================
// TERMS
// ============================================================

class TermsConditionsScreen
    extends StatelessWidget {
  const TermsConditionsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Terms & Conditions',
      sections: [
        _LegalSection(
          title: 'Use of RHIC',
          text:
              'By using the RHIC application, you agree to use its features responsibly and in accordance with applicable laws and RHIC policies.',
        ),
        _LegalSection(
          title: 'Digital Books',
          text:
              'Digital books purchased through RHIC are provided for the purchaser’s permitted personal use.',
        ),
        _LegalSection(
          title: 'Payments',
          text:
              'Bank-transfer payments may remain pending until an administrator verifies the payment.',
        ),
        _LegalSection(
          title: 'Account Responsibility',
          text:
              'You are responsible for maintaining access to your account and keeping your account credentials secure.',
        ),
      ],
    );
  }
}

// ============================================================
// LEGAL SCREEN
// ============================================================

class _LegalScreen
    extends StatelessWidget {
  final String title;
  final List<_LegalSection> sections;

  const _LegalScreen({
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFCFAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF3D004D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...sections.map(
            (section) => Container(
              margin:
                  const EdgeInsets.only(
                bottom: 14,
              ),
              padding:
                  const EdgeInsets.all(18),
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
                    section.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF3D004D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.text,
                    style:
                        const TextStyle(
                      height: 1.6,
                      color: Colors.grey,
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

class _LegalSection {
  final String title;
  final String text;

  const _LegalSection({
    required this.title,
    required this.text,
  });
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
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
              icon,
              size: 65,
              color:
                  const Color(0xFFD4CAD8),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SIGN OUT
// ============================================================

class _SignOutCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(20),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.redAccent,
          ),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.redAccent,
          ),
        ),
        subtitle: const Text(
          'Sign out of your RHIC account',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INFO BOX
// ============================================================

class _InfoBox extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoBox({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

InputDecoration _inputDecoration(
  String hint,
  IconData icon,
) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(
      icon,
      color: const Color(0xFF6B1FA2),
    ),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder:
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder:
        OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF6B1FA2),
      ),
    ),
  );
}