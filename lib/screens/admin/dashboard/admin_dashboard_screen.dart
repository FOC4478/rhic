import 'package:flutter/material.dart';
import 'package:church_app/screens/admin/books/admin_books_screen.dart';
import 'package:church_app/screens/admin/sermons/admin_sermons_screen.dart';
import 'package:church_app/services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;

  final List<_AdminMenuItem> _menuItems = const [
    _AdminMenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
    ),
    _AdminMenuItem(
      title: 'Sermons',
      icon: Icons.play_circle_outline,
    ),
    _AdminMenuItem(
      title: 'Books',
      icon: Icons.library_books_outlined,
    ),
    _AdminMenuItem(
      title: 'Events',
      icon: Icons.event_outlined,
    ),
    _AdminMenuItem(
      title: 'Gallery',
      icon: Icons.photo_library_outlined,
    ),
    _AdminMenuItem(
      title: 'Giving',
      icon: Icons.volunteer_activism_outlined,
    ),
    _AdminMenuItem(
      title: 'Community',
      icon: Icons.groups_outlined,
    ),
    _AdminMenuItem(
      title: 'Users',
      icon: Icons.people_outline,
    ),
    _AdminMenuItem(
      title: 'Notifications',
      icon: Icons.notifications_none_outlined,
    ),
    _AdminMenuItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
    ),
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF7F5F8),

          // ------------------------------------------------------
          // MOBILE DRAWER
          // ------------------------------------------------------

          drawer: isDesktop
              ? null
              : Drawer(
                  width: 280,
                  backgroundColor: const Color(0xFF350044),
                  child: _buildSidebar(context),
                ),

          // ------------------------------------------------------
          // MAIN BODY
          // ------------------------------------------------------

          body: Row(
            children: [
              // Desktop sidebar
              if (isDesktop)
                SizedBox(
                  width: 260,
                  child: _buildSidebar(context),
                ),

              // Main area
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(
                      context,
                      isDesktop,
                    ),

                    Expanded(
                      child: _buildCurrentPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardPage();

      case 1:
        return const AdminSermonsScreen();

      case 2:
  return const AdminBooksScreen();

      case 3:
        return _buildComingSoonPage(
          title: 'Events',
          icon: Icons.event_outlined,
          description:
              'Create and manage church events.',
        );

      case 4:
        return _buildComingSoonPage(
          title: 'Gallery',
          icon: Icons.photo_library_outlined,
          description:
              'Manage photos and gallery content.',
        );

      case 5:
        return _buildComingSoonPage(
          title: 'Giving',
          icon: Icons.volunteer_activism_outlined,
          description:
              'Manage giving records and payment settings.',
        );

      case 6:
        return _buildComingSoonPage(
          title: 'Community',
          icon: Icons.groups_outlined,
          description:
              'Manage community groups and posts.',
        );

      case 7:
        return _buildComingSoonPage(
          title: 'Users',
          icon: Icons.people_outline,
          description:
              'Manage registered users.',
        );

      case 8:
        return _buildComingSoonPage(
          title: 'Notifications',
          icon: Icons.notifications_none_outlined,
          description:
              'Send and manage notifications.',
        );

      case 9:
        return _buildComingSoonPage(
          title: 'Settings',
          icon: Icons.settings_outlined,
          description:
              'Manage your RHIC admin settings.',
        );

      default:
        return _buildDashboardPage();
    }
  }

  // ============================================================
  // SELECT MENU
  // ============================================================

  void _selectMenu(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Close drawer on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: const Color(0xFF350044),
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // BRAND
            // ----------------------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                28,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        'RHIC',
                        style: TextStyle(
                          color: Color(0xFF350044),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RHIC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Admin Portal',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // MENU
            // ----------------------------------------------------

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];

                  final bool selected =
                      _selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 4,
                    ),
                    child: ListTile(
                      onTap: () => _selectMenu(index),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),

                      selected: selected,

                      selectedTileColor:
                          Colors.white.withValues(
                        alpha: 0.14,
                      ),

                      leading: Icon(
                        item.icon,
                        color: selected
                            ? Colors.white
                            : Colors.white60,
                        size: 21,
                      ),

                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),

                      trailing: selected
                          ? const Icon(
                              Icons.chevron_right,
                              color: Colors.white54,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),

            // ----------------------------------------------------
            // LOGOUT
            // ----------------------------------------------------

            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                onTap: _logout,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                leading: const Icon(
                  Icons.logout,
                  color: Colors.white70,
                ),

                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(
    BuildContext context,
    bool isDesktop,
  ) {
    final String pageTitle =
        _menuItems[_selectedIndex].title;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE9E5EA),
          ),
        ),
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // MOBILE MENU BUTTON
          // ------------------------------------------------------

          if (!isDesktop)
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu),
            ),

          if (!isDesktop)
            const SizedBox(width: 8),

          // ------------------------------------------------------
          // TITLE
          // ------------------------------------------------------

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  pageTitle,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your RHIC platform',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // NOTIFICATION
          // ------------------------------------------------------

          IconButton(
            onPressed: () {
              _selectMenu(8);
            },
            icon: const Icon(
              Icons.notifications_none,
            ),
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // ADMIN PROFILE
          // ------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5F8),
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      Color(0xFF350044),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),

                SizedBox(width: 9),

                Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD PAGE
  // ============================================================

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Admin 👋',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Here is an overview of your RHIC platform.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          // ------------------------------------------------------
          // STATISTICS
          // ------------------------------------------------------

          LayoutBuilder(
            builder: (context, constraints) {
            return GridView.builder(
            shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: 4,
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 300,
    crossAxisSpacing: 18,
    mainAxisSpacing: 18,
    mainAxisExtent: 105,
  ),
  itemBuilder: (context, index) {
    const cards = [
      _StatCard(
        title: 'Total Users',
        value: '—',
        icon: Icons.people_outline,
      ),
      _StatCard(
        title: 'Sermons',
        value: '—',
        icon: Icons.play_circle_outline,
      ),
      _StatCard(
        title: 'Books',
        value: '—',
        icon: Icons.library_books_outlined,
      ),
      _StatCard(
        title: 'Events',
        value: '—',
        icon: Icons.event_outlined,
      ),
    ];

    return cards[index];
  },
);
            },
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // QUICK ACTIONS
          // ------------------------------------------------------

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          LayoutBuilder(
            builder: (context, constraints) {
              int columns = 1;

              if (constraints.maxWidth >= 1000) {
                columns = 4;
              } else if (constraints.maxWidth >= 650) {
                columns = 2;
              }

              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio:
                    constraints.maxWidth < 500
                        ? 3.2
                        : 2.5,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                children: [
                  _QuickAction(
                    title: 'Add Sermon',
                    icon:
                        Icons.add_circle_outline,
                    onTap: () =>
                        _selectMenu(1),
                  ),

                  _QuickAction(
                    title: 'Add Book',
                    icon:
                        Icons.library_add_outlined,
                    onTap: () =>
                        _selectMenu(2),
                  ),

                  _QuickAction(
                    title: 'Create Event',
                    icon:
                        Icons.event_available_outlined,
                    onTap: () =>
                        _selectMenu(3),
                  ),

                  _QuickAction(
                    title: 'Manage Users',
                    icon:
                        Icons.people_outline,
                    onTap: () =>
                        _selectMenu(7),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // RECENT ACTIVITY
          // ------------------------------------------------------

          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE9E5EA),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.history,
                  size: 38,
                  color: Colors.black26,
                ),

                SizedBox(height: 10),

                Text(
                  'No recent activity yet.',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Admin activity will appear here.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------------
          // SYSTEM STATUS
          // ------------------------------------------------------

          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE9E5EA),
              ),
            ),
            child: const Column(
              children: [
                _SystemStatusRow(
                  title: 'Firebase',
                  status: 'Connected',
                  icon:
                      Icons.cloud_done_outlined,
                ),

                Divider(height: 24),

                _SystemStatusRow(
                  title: 'Authentication',
                  status: 'Active',
                  icon: Icons.lock_outline,
                ),

                Divider(height: 24),

                _SystemStatusRow(
                  title: 'Admin Portal',
                  status: 'Active',
                  icon: Icons
                      .admin_panel_settings_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================================
  // COMING SOON PAGE
  // ============================================================

  Widget _buildComingSoonPage({
    required String title,
    required IconData icon,
    required String description,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE9E5EA),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF350044)
                      .withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color:
                      const Color(0xFF350044),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 22),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F8),
                  borderRadius:
                      BorderRadius.circular(30),
                ),
                child: const Text(
                  'Management section',
                  style: TextStyle(
                    color:
                        Color(0xFF350044),
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),

          content: const Text(
            'Are you sure you want to logout?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF350044),
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/admin/login',
      (route) => false,
    );
  }
}

// ================================================================
// ADMIN MENU ITEM
// ================================================================

class _AdminMenuItem {
  final String title;
  final IconData icon;

  const _AdminMenuItem({
    required this.title,
    required this.icon,
  });
}

// ================================================================
// STAT CARD
// ================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9E5EA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF350044)
                  .withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
                  const Color(0xFF350044),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
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

// ================================================================
// QUICK ACTION
// ================================================================

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: const Color(
                0xFFE9E5EA,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(0xFF350044),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SYSTEM STATUS
// ================================================================

class _SystemStatusRow extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;

  const _SystemStatusRow({
    required this.title,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF350044)
                .withValues(alpha: 0.08),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color:
                const Color(0xFF350044),
            size: 21,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF087F75)
                .withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Color(0xFF087F75),
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}