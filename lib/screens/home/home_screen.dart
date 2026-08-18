import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:church_app/l10n/app_localizations.dart';

import '../../models/featured_event_model.dart';
import '../../repositories/content_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _eventController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _eventScaleAnimation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // PAGE ANIMATION
    // ============================================================

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: Curves.easeOutCubic,
      ),
    );

    // ============================================================
    // EVENT ANIMATION
    // ============================================================

    _eventController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _eventScaleAnimation = CurvedAnimation(
      parent: _eventController,
      curve: Curves.easeOutBack,
    );

    _pageController.forward();

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _eventController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onNavigationTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;

      case 1:
        Navigator.pushNamed(context, '/library');
        break;

      case 2:
        Navigator.pushNamed(context, '/resources');
        break;

      case 3:
        Navigator.pushNamed(context, '/account');
        break;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ==================================================
                // HEADER
                // ==================================================

                SliverToBoxAdapter(
                  child: _buildHeader(l10n),
                ),

                // ==================================================
                // FEATURED EVENT
                // ==================================================

                SliverToBoxAdapter(
                  child: ScaleTransition(
                    scale: _eventScaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      child: _FeaturedEventCard(
                        closeText: l10n.close,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 22),
                ),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.volunteer_activism,
                            title: l10n.give,
                            subtitle: l10n.supportRhic,
                            colors: const [
                              Color(0xFF6B1FA2),
                              Color(0xFF8E3FC1),
                            ],
                            onTap: () {
                        Navigator.pushNamed(
                        context,
                        '/events',
                      );
                      },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.church,
                            title: l10n.ourChurches,
                            subtitle: l10n.findALocation,
                            colors: const [
                              Color(0xFFF36C21),
                              Color(0xFFFF8A45),
                            ],
                            onTap: () {
                              _showComingSoon(
                                context,
                                l10n.churchLocations,
                                l10n.comingSoon(
                                  l10n.churchLocations,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 25),
                ),

                // ==================================================
                // EXPLORE
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    child: Text(
                      l10n.exploreRhic,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202020),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // ==================================================
                // FEATURE TILES
                // ==================================================

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate(
                      [
                       _FeatureTile(
                     icon: Icons.record_voice_over,
                     title: l10n.teachings,
                     onTap: () {
                    Navigator.pushNamed(
                       context,
                     '/teachings',
                    );
                      },
                    ),
                        _FeatureTile(
                          icon: Icons.groups,
                          title: l10n.rhicCommunity,
                          onTap: () {
                            _showComingSoon(
                              context,
                              l10n.rhicCommunity,
                              l10n.comingSoon(
                                l10n.rhicCommunity,
                              ),
                            );
                          },
                        ),
                        _FeatureTile(
                          icon: Icons.family_restroom,
                          title: l10n.family,
                          onTap: () {
                            _showComingSoon(
                              context,
                              l10n.family,
                              l10n.comingSoon(
                                l10n.family,
                              ),
                            );
                          },
                        ),
                        _FeatureTile(
                          icon: Icons.calendar_month,
                          title: l10n.events,
                          onTap: () {
                            _showComingSoon(
                              context,
                              l10n.events,
                              l10n.comingSoon(
                                l10n.events,
                              ),
                            );
                          },
                        ),
                        _FeatureTile(
                          icon: Icons.photo_library,
                          title: l10n.gallery,
                          onTap: () {
                            _showComingSoon(
                              context,
                              l10n.gallery,
                              l10n.comingSoon(
                                l10n.gallery,
                              ),
                            );
                          },
                        ),
                        _FeatureTile(
                          icon: Icons.live_tv,
                          title: l10n.live,
                          onTap: () {
                            _showComingSoon(
                              context,
                              l10n.live,
                              l10n.comingSoon(
                                l10n.live,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.9,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),
              ],
            ),
          ),
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: _buildBottomNavigation(l10n),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        25,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hello,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B1FA2),
                  ),
                ),
                const SizedBox(height: 2),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (
                    context,
                    snapshot,
                  ) {
                    final user = snapshot.data;

                    String name = l10n.friend;

                    if (user != null &&
                        user.displayName != null &&
                        user.displayName!.trim().isNotEmpty) {
                      name = user.displayName!
                          .trim()
                          .split(' ')
                          .first;
                    }

                    return Text(
                      name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ========================================================
          // NOTIFICATION
          // ========================================================

          _CircleIconButton(
            icon: Icons.notifications_none,
            hasNotification: true,
            onTap: () {
              _showComingSoon(
                context,
                l10n.notifications,
                l10n.comingSoon(
                  l10n.notifications,
                ),
              );
            },
          ),

          const SizedBox(width: 10),

          // ========================================================
          // PROFILE
          // ========================================================

          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/account',
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B1FA2),
                    Color(0xFF9B59C5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B1FA2).withValues(
                      alpha: .20,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation(
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .06,
            ),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: l10n.home,
                selected: _currentIndex == 0,
                onTap: () {
                  _onNavigationTapped(0);
                },
              ),
              _BottomNavItem(
                icon: Icons.library_books_outlined,
                label: l10n.myLibrary,
                selected: _currentIndex == 1,
                onTap: () {
                  _onNavigationTapped(1);
                },
              ),
              _BottomNavItem(
                icon: Icons.podcasts_outlined,
                label: l10n.resources,
                selected: _currentIndex == 2,
                onTap: () {
                  _onNavigationTapped(2);
                },
              ),
              _BottomNavItem(
                icon: Icons.person_outline,
                label: l10n.account,
                selected: _currentIndex == 3,
                onTap: () {
                  _onNavigationTapped(3);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(
    BuildContext context,
    String title,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ==================================================================
// FEATURED EVENT CARD
// ==================================================================

class _FeaturedEventCard extends StatelessWidget {
  final String closeText;

  const _FeaturedEventCard({
    required this.closeText,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeaturedEvent?>(
      stream: ContentRepository.instance.featuredEventStream(),
      builder: (
        context,
        snapshot,
      ) {
        // ==========================================================
        // LOADING
        // ==========================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        // ==========================================================
        // ERROR
        // ==========================================================

        if (snapshot.hasError) {
          return _buildFallbackCard();
        }

        // ==========================================================
        // NO ACTIVE EVENT
        // ==========================================================

        final event = snapshot.data;

        if (event == null) {
          return _buildFallbackCard();
        }

        // ==========================================================
        // EVENT DATA
        // ==========================================================

        return _AnimatedHoverContainer(
          borderRadius: 28,
          onTap: () {
            _showEventDetails(
              context,
              event: event,
              closeText: closeText,
            );
          },
          child: Container(
            height: 235,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF58156F),
                  Color(0xFF9B2F87),
                  Color(0xFFF36C21),
                ],
              ),
              image: event.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        event.imageUrl,
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(
                          alpha: .35,
                        ),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // ==================================================
                // DECORATIVE CIRCLE
                // ==================================================

                Positioned(
                  right: -35,
                  top: -35,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: .12,
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // ARROW
                // ==================================================

                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: .95,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_outward,
                      color: Color(0xFF6B1FA2),
                      size: 27,
                    ),
                  ),
                ),

                // ==================================================
                // EVENT CONTENT
                // ==================================================

                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              event.date,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(width: 15),

                          const Icon(
                            Icons.access_time_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),

                          Text(
                            event.time,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // LOADING CARD
  // ================================================================

  Widget _buildLoadingCard() {
    return Container(
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF58156F),
            Color(0xFF9B2F87),
            Color(0xFFF36C21),
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  // ================================================================
  // FALLBACK CARD
  // ================================================================

  Widget _buildFallbackCard() {
    return Container(
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF58156F),
            Color(0xFF9B2F87),
            Color(0xFFF36C21),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: .12,
                ),
              ),
            ),
          ),

          Positioned(
            left: 22,
            right: 22,
            bottom: 20,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'RHIC SERVICE',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sunday',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.access_time_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '9:00 AM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EVENT DETAILS
  // ================================================================

  static void _showEventDetails(
    BuildContext context, {
    required FeaturedEvent event,
    required String closeText,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              26,
              28,
              26,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D004D),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 19,
                      color: Color(0xFF6B1FA2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.date,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 19,
                      color: Color(0xFF6B1FA2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF3D004D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      closeText,
                    ),
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

// ==================================================================
// ACTION CARD
// ==================================================================

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() =>
      _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _pressed
        ? 0.95
        : _hovered
            ? 1.03
            : 1.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          child: Container(
            height: 105,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: widget.colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.first.withValues(
                    alpha: _hovered ? 0.30 : 0.18,
                  ),
                  blurRadius: _hovered ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: .8,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// FEATURE TILE
// ==================================================================

class _FeatureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<_FeatureTile> createState() =>
      _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _pressed
        ? 0.92
        : _hovered
            ? 1.05
            : 1.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(
            milliseconds: 180,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFFF1D9F7)
                  : const Color(0xFFF9EAFB),
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: _hovered
                    ? const Color(0xFF8E3FC1)
                    : const Color(0xFFE8C9ED),
              ),
              boxShadow: [
                if (_hovered)
                  BoxShadow(
                    color:
                        const Color(0xFF6B1FA2)
                            .withValues(alpha: .15),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.12 : 1.0,
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: const Color(0xFF7B21A3),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B1745),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// CIRCLE ICON BUTTON
// ==================================================================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool hasNotification;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.hasNotification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F2F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4A2454),
              size: 24,
            ),
          ),
          if (hasNotification)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==================================================================
// BOTTOM NAV ITEM
// ==================================================================

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1.0,
              duration: const Duration(
                milliseconds: 200,
              ),
              child: Icon(
                icon,
                size: 25,
                color: selected
                    ? const Color(0xFF6B1FA2)
                    : const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? const Color(0xFF6B1FA2)
                    : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// HOVER CONTAINER
// ==================================================================

class _AnimatedHoverContainer
    extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final VoidCallback onTap;

  const _AnimatedHoverContainer({
    required this.child,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  State<_AnimatedHoverContainer> createState() =>
      _AnimatedHoverContainerState();
}

class _AnimatedHoverContainerState
    extends State<_AnimatedHoverContainer> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;

    if (_pressed) {
      scale = 0.97;
    } else if (_hovered) {
      scale = 1.015;
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _pressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            _pressed = false;
          });
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(
            milliseconds: 200,
          ),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

