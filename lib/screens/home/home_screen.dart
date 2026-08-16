import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // USER NAME
  // ============================================================

  String get _firstName {
    final user = _auth.currentUser;

    if (user == null) {
      return 'Friend';
    }

    final displayName = user.displayName;

    if (displayName == null || displayName.trim().isEmpty) {
      return 'Friend';
    }

    return displayName.trim().split(' ').first;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // We will connect these screens as we build them.
    switch (index) {
      case 0:
        break;

      case 1:
        // My Library
        break;

      case 2:
        // Resources
        break;

      case 3:
        // Account
        break;
    }
  }

  // ============================================================
  // FEATURED EVENT
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _featuredEventStream() {
    return _firestore
        .collection('featured_events')
        .doc('current')
        .snapshots();
  }

  // ============================================================
  // UPCOMING EVENTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _eventsStream() {
    return _firestore
        .collection('events')
        .where(
          'isActive',
          isEqualTo: true,
        )
        .orderBy(
          'eventDate',
          descending: false,
        )
        .limit(4)
        .snapshots();
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _galleryStream() {
    return _firestore
        .collection('gallery')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(6)
        .snapshots();
  }

  // ============================================================
  // OPEN FEATURED EVENT
  // ============================================================

  void _openFeaturedEvent(
    Map<String, dynamic> data,
  ) {
    Navigator.pushNamed(
      context,
      '/event-details',
      arguments: data,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(),
            _buildPlaceholder(
              'My Library',
              Icons.library_books_outlined,
            ),
            _buildPlaceholder(
              'Resources',
              Icons.headphones_outlined,
            ),
            _buildPlaceholder(
              'Account',
              Icons.person_outline,
            ),
          ],
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // HOME CONTENT
  // ============================================================

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Row(
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Hello',
                        style: TextStyle(
                          color: Color(0xFF6B238E),
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'cursive',
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _firstName,
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notification
                _headerIcon(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/notifications',
                    );
                  },
                ),

                const SizedBox(width: 10),

                // RHIC logo
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 3;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/rhic_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return Container(
                            color: const Color(
                              0xFF5B126D,
                            ),
                            alignment:
                                Alignment.center,
                            child: const Text(
                              'RHIC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==================================================
            // FEATURED EVENT
            // ==================================================

            StreamBuilder<
                DocumentSnapshot<
                    Map<String, dynamic>>>(
              stream: _featuredEventStream(),
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return _featuredLoadingCard();
                }

                if (!snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return _emptyFeaturedEvent();
                }

                final data =
                    snapshot.data!.data();

                if (data == null) {
                  return _emptyFeaturedEvent();
                }

                final bool isActive =
                    data['isActive'] ?? true;

                if (!isActive) {
                  return _emptyFeaturedEvent();
                }

                return _buildFeaturedEvent(data);
              },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // MAIN ACTION BUTTONS
            // ==================================================

            Row(
              children: [

                Expanded(
                  child: _largeActionButton(
                    title: 'RHIC Give',
                    icon: Icons.volunteer_activism,
                    backgroundColor:
                        const Color(0xFF6B238E),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/give',
                      );
                    },
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: _largeActionButton(
                    title: 'RHIC Churches',
                    icon: Icons.church_outlined,
                    backgroundColor:
                        const Color(0xFFFF7043),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/churches',
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================

            _buildQuickActions(),

            const SizedBox(height: 30),

            // ==================================================
            // UPCOMING EVENTS
            // ==================================================

            _sectionHeader(
              title: 'Upcoming Events',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/events',
                );
              },
            ),

            const SizedBox(height: 14),

            _buildEvents(),

            const SizedBox(height: 30),

            // ==================================================
            // GALLERY
            // ==================================================

            _sectionHeader(
              title: 'Gallery',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/gallery',
                );
              },
            ),

            const SizedBox(height: 14),

            _buildGallery(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FEATURED EVENT CARD
  // ============================================================

  Widget _buildFeaturedEvent(
    Map<String, dynamic> data,
  ) {
    final String title =
        data['title'] ?? 'Featured Event';

    final String date =
        data['date'] ?? '';

    final String imageUrl =
        data['imageUrl'] ?? '';

    return GestureDetector(
      onTap: () => _openFeaturedEvent(data),
      child: Container(
        height: 390,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(28),
          color: const Color(0xFF5B126D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 
                0.08,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(28),
          child: Stack(
            children: [

              // IMAGE
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return _eventFallback();
                        },
                      )
                    : _eventFallback(),
              ),

              // DARK GRADIENT
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 
                          0.75,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ARROW
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFF6B238E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              // TEXT
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 8),

                      Text(
                        date,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EVENT FALLBACK
  // ============================================================

  Widget _eventFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B238E),
            Color(0xFF350044),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.event,
          color: Colors.white,
          size: 70,
        ),
      ),
    );
  }

  // ============================================================
  // FEATURED LOADING
  // ============================================================

  Widget _featuredLoadingCard() {
    return Container(
      height: 390,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAF4),
        borderRadius:
            BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6B238E),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY FEATURED EVENT
  // ============================================================

  Widget _emptyFeaturedEvent() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF4ECF7),
        borderRadius:
            BorderRadius.circular(28),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 50,
              color: Color(0xFF6B238E),
            ),
            SizedBox(height: 12),
            Text(
              'No featured event available',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color: Color(0xFF5B126D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LARGE ACTION BUTTON
  // ============================================================

  Widget _largeActionButton({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              color: Colors.white,
              size: 27,
            ),

            const SizedBox(width: 10),

            Flexible(
              child: Text(
                title,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Praise Report',
        'icon': Icons.volunteer_activism_outlined,
        'route': '/praise-report',
      },
      {
        'title': 'RHIC Kids',
        'icon': Icons.child_friendly_outlined,
        'route': '/rhic-kids',
      },
      {
        'title': 'Family Process',
        'icon': Icons.family_restroom_outlined,
        'route': '/family-process',
      },
      {
        'title': 'Events',
        'icon': Icons.calendar_month_outlined,
        'route': '/events',
      },
      {
        'title': 'Gallery',
        'icon': Icons.photo_library_outlined,
        'route': '/gallery',
      },
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 22,
      runSpacing: 22,
      children: actions.map((action) {
        return _quickAction(
          title: action['title'] as String,
          icon: action['icon'] as IconData,
          onTap: () {
            Navigator.pushNamed(
              context,
              action['route'] as String,
            );
          },
        );
      }).toList(),
    );
  }

  // ============================================================
  // QUICK ACTION ITEM
  // ============================================================

  Widget _quickAction({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 88,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [

            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFF5DFF2),
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color:
                      const Color(0xFFE3B9DD),
                ),
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF6B238E),
              ),
            ),

            const SizedBox(height: 9),

            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF4A4A4A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required String title,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF222222),
            ),
          ),
        ),

        GestureDetector(
          onTap: onTap,
          child: const Text(
            'See all',
            style: TextStyle(
              color: Color(0xFF6B238E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EVENTS
  // ============================================================

  Widget _buildEvents() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _eventsStream(),
      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B238E),
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _emptySection(
            icon: Icons.event_outlined,
            text: 'No upcoming events',
          );
        }

        final events =
            snapshot.data!.docs;

        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount: events.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(width: 14),
            itemBuilder: (context, index) {

              final data =
                  events[index].data();

              return _eventSmallCard(data);
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // SMALL EVENT CARD
  // ============================================================

  Widget _eventSmallCard(
    Map<String, dynamic> data,
  ) {
    final title =
        data['title'] ?? 'Event';

    final date =
        data['date'] ?? '';

    final imageUrl =
        data['imageUrl'] ?? '';

    return SizedBox(
      width: 220,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/event-details',
            arguments: data,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            color:
                const Color(0xFFF4ECF7),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [

              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return _eventFallback();
                        },
                      )
                    : _eventFallback(),
              ),

              Positioned.fill(
                child: Container(
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 
                          0.8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    if (date.isNotEmpty)
                      Text(
                        date,
                        style:
                            const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _buildGallery() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _galleryStream(),
      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B238E),
              ),
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _emptySection(
            icon: Icons.photo_library_outlined,
            text: 'No gallery photos yet',
          );
        }

        final photos =
            snapshot.data!.docs;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: photos.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {

            final data =
                photos[index].data();

            final imageUrl =
                data['imageUrl'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/gallery',
                );
              },
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return Container(
                            color:
                                const Color(
                              0xFFF4ECF7,
                            ),
                            child: const Icon(
                              Icons.image,
                              color: Color(
                                0xFF6B238E,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color:
                            const Color(
                          0xFFF4ECF7,
                        ),
                        child: const Icon(
                          Icons.image,
                          color:
                              Color(0xFF6B238E),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY SECTION
  // ============================================================

  Widget _emptySection({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3FA),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [

          Icon(
            icon,
            size: 35,
            color: const Color(0xFF6B238E),
          ),

          const SizedBox(height: 8),

          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER ICON
  // ============================================================

  Widget _headerIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF333333),
          size: 24,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected:
          _onNavigationChanged,
      backgroundColor: Colors.white,
      elevation: 8,
      height: 72,
      indicatorColor:
          const Color(0xFFE9D8EF),
      destinations: const [

        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
          ),
          selectedIcon: Icon(
            Icons.home,
          ),
          label: 'Home',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.library_books_outlined,
          ),
          selectedIcon: Icon(
            Icons.library_books,
          ),
          label: 'My Library',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.headphones_outlined,
          ),
          selectedIcon: Icon(
            Icons.headphones,
          ),
          label: 'Resources',
        ),

        NavigationDestination(
          icon: Icon(
            Icons.person_outline,
          ),
          selectedIcon: Icon(
            Icons.person,
          ),
          label: 'Account',
        ),
      ],
    );
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _buildPlaceholder(
    String title,
    IconData icon,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          Icon(
            icon,
            size: 60,
            color: const Color(0xFF6B238E),
          ),

          const SizedBox(height: 15),

          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'This section will be built next.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}