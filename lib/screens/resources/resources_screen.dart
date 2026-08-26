import 'package:flutter/material.dart';
import '../shop/shop_screen.dart';
import '../resources/sermons_screen.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({
    super.key,
  });

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color purple =
      Color(0xFF6B1FA2);

  static const Color orange =
      Color(0xFFF7931E);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: Column(
          children: [

            // ======================================================
            // HEADER
            // ======================================================

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                25,
                22,
                18,
              ),
              child: Row(
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          'Resources',
                          style:
                              const TextStyle(
                            fontSize: 32,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                darkPurple,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          'Grow, learn and stay connected',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Colors.grey.shade600,
                            fontWeight:
                                FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification button

                  Container(
                    width: 46,
                    height: 46,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF7F0F9,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons
                            .notifications_none_rounded,
                        color:
                            darkPurple,
                        size: 23,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Expanded(
              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  5,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    // ==================================================
                    // FEATURED TEXT
                    // ==================================================

                    const Padding(
                      padding:
                          EdgeInsets.only(
                        left: 3,
                        bottom: 14,
                      ),
                      child: Text(
                        'Explore our resources',
                        style:
                            TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              darkPurple,
                        ),
                      ),
                    ),

                    // ==================================================
                    // SERMON CARD
                    // ==================================================

                    _ResourceCard(
                      title: 'Our Sermons',
                      subtitle:
                          'Listen, watch and\nbe inspired by the Word.',
                      icon:
                          Icons
                              .play_circle_outline_rounded,
                      backgroundColor:
                          const Color(
                        0xFFF5E8F7,
                      ),
                      iconColor:
                          purple,
                      illustration:
                          Icons
                              .menu_book_rounded,
                      tag:
                          'WATCH & LISTEN',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SermonsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // STORE CARD
                    // ==================================================

                    _ResourceCard(
                      title: 'Our Store',
                      subtitle:
                          'Discover books, materials\nand RHIC resources.',
                      icon:
                          Icons
                              .storefront_outlined,
                      backgroundColor:
                          const Color(
                        0xFFFFF0DC,
                      ),
                      iconColor:
                          orange,
                      illustration:
                          Icons
                              .shopping_bag_rounded,
                      tag:
                          'SHOP RHIC',
                     onTap: () {
                    Navigator.push(
                     context,
                   MaterialPageRoute(
                builder: (_) => const ShopScreen(),
            ),
                 );
                  },
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==================================================
                    // QUICK INFO
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            darkPurple,
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                      child: Row(
                        children: [

                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white
                                      .withValues(
                                alpha: .12,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .auto_awesome_outlined,
                              color:
                                  Colors.white,
                              size: 24,
                            ),
                          ),

                          const SizedBox(
                            width: 15,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [

                                const Text(
                                  'Keep growing',
                                  style:
                                      TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w800,
                                    color:
                                        Colors.white,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Explore our sermons and resources regularly.',
                                  style:
                                      TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: Colors
                                        .white
                                        .withValues(
                                      alpha: .75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar:
          _buildBottomNavigation(
        context,
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _buildBottomNavigation(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: .06,
            ),
            blurRadius: 15,
            offset:
                const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [

              _BottomNavItem(
                icon:
                    Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                  );
                },
              ),

              _BottomNavItem(
                icon:
                    Icons.library_books_outlined,
                label: 'My Library',
                selected: false,
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/library',
                  );
                },
              ),

              _BottomNavItem(
                icon:
                    Icons.podcasts_outlined,
                label: 'Resources',
                selected: true,
                onTap: () {},
              ),

              _BottomNavItem(
                icon:
                    Icons.person_outline_rounded,
                label: 'Account',
                selected: false,
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/account',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// RESOURCE CARD
// ==================================================================

class _ResourceCard
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final IconData illustration;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.illustration,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 245,
        decoration:
            BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(28),
          child: Stack(
            children: [

              // ====================================================
              // LARGE BACKGROUND ILLUSTRATION
              // ====================================================

              Positioned(
                right: -35,
                bottom: -35,
                child: Transform.rotate(
                  angle: -0.08,
                  child: Icon(
                    illustration,
                    size: 205,
                    color:
                        Colors.white.withValues(
                      alpha: .65,
                    ),
                  ),
                ),
              ),

              // ====================================================
              // SMALL DECORATIVE CIRCLE
              // ====================================================

              Positioned(
                right: 35,
                top: 25,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withValues(
                      alpha: .45,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                ),
              ),

              // ====================================================
              // CONTENT
              // ====================================================

              Positioned(
                left: 24,
                top: 25,
                right: 25,
                bottom: 24,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    // Tag

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white.withValues(
                          alpha: .7,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        tag,
                        style:
                            TextStyle(
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              .8,
                          color:
                              iconColor,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Icon

                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white.withValues(
                          alpha: .7,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color:
                            iconColor,
                        size: 27,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // Title

                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF3D004D,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // Subtitle

                    Text(
                      subtitle,
                      style:
                          TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color:
                            Colors.grey
                                .shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // ====================================================
              // ARROW
              // ====================================================

              Positioned(
                right: 20,
                bottom: 20,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withValues(
                      alpha: .85,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                        iconColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// BOTTOM NAV ITEM
// ==================================================================

class _BottomNavItem
    extends StatelessWidget {
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
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior:
          HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [

            AnimatedScale(
              scale:
                  selected ? 1.08 : 1.0,
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              child: Icon(
                icon,
                size: 25,
                color: selected
                    ? const Color(
                        0xFF6B1FA2,
                      )
                    : const Color(
                        0xFF9E9E9E,
                      ),
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              label,
              style:
                  TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? const Color(
                        0xFF6B1FA2,
                      )
                    : const Color(
                        0xFF9E9E9E,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}