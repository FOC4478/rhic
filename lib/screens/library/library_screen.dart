import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/teaching_model.dart';
import '../../repositories/library_repository.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() =>
      _LibraryScreenState();
}

class _LibraryScreenState
    extends State<LibraryScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  // ============================================================
  // STATE
  // ============================================================

  int _selectedTab = 0;

  final List<String> _tabs = const [
    'Downloads',
    'Videos',
    'Audio',
  ];

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get _currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  // ============================================================
  // TAB
  // ============================================================

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onNavigationTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          '/',
        );
        break;

      case 1:
        Navigator.pushReplacementNamed(
          context,
          '/library',
        );
        break;

      case 2:
        break;

      case 3:
        Navigator.pushReplacementNamed(
          context,
          '/account',
        );
        break;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),

            Expanded(
              child: _buildSelectedContent(),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          _buildBottomNavigation(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        28,
        20,
        20,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'My Resources',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: darkPurple,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SizedBox(
      height: 62,
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Row(
          children:
              List.generate(
            _tabs.length,
            (index) {
              final selected =
                  _selectedTab == index;

              return GestureDetector(
                behavior:
                    HitTestBehavior.opaque,
                onTap: () {
                  _onTabChanged(index);
                },
                child: Container(
                  margin:
                      EdgeInsets.only(
                    right:
                        index ==
                                _tabs.length -
                                    1
                            ? 0
                            : 30,
                  ),
                  padding:
                      const EdgeInsets.only(
                    bottom: 13,
                  ),
                  decoration:
                      BoxDecoration(
                    border:
                        Border(
                      bottom:
                          BorderSide(
                        color: selected
                            ? orangeColor
                            : Colors
                                .transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabs[index],
                    style:
                        TextStyle(
                      fontSize: 16,
                      fontWeight:
                          selected
                              ? FontWeight
                                  .w700
                              : FontWeight
                                  .w400,
                      color: selected
                          ? const Color(
                              0xFF3D174A,
                            )
                          : const Color(
                              0xFF9E9E9E,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED CONTENT
  // ============================================================

  Widget _buildSelectedContent() {
    final user = _currentUser;

    if (user == null) {
      return const _EmptyResourceState(
        icon: Icons.lock_outline,
        title:
            'Sign in to view your resources',
        subtitle:
            'Your downloaded teachings will appear here',
      );
    }

    switch (_selectedTab) {
      case 0:
        return _buildDownloads(user.uid);

      case 1:
        return _buildVideos(user.uid);

      case 2:
        return _buildAudio(user.uid);

      default:
        return _buildDownloads(user.uid);
    }
  }

  // ============================================================
  // ALL DOWNLOADS
  // ============================================================

  Widget _buildDownloads(String userId) {
    return StreamBuilder<List<TeachingModel>>(
      stream:
          LibraryRepository.instance
              .downloadsStream(userId),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _ResourceLoading();
        }

        if (snapshot.hasError) {
          return _ResourceError(
            message:
                'Unable to load your downloads.',
            onRetry: () {
              setState(() {});
            },
          );
        }

        final teachings =
            snapshot.data ?? [];

        if (teachings.isEmpty) {
          return const _EmptyResourceState(
            icon:
                Icons.download_done_rounded,
            title:
                'No downloaded resources yet',
            subtitle:
                'Downloaded videos and audio will appear here',
          );
        }

        return _buildTeachingList(
          teachings,
        );
      },
    );
  }

  // ============================================================
  // VIDEO DOWNLOADS
  // ============================================================

  Widget _buildVideos(String userId) {
    return StreamBuilder<List<TeachingModel>>(
      stream:
          LibraryRepository.instance
              .videoDownloadsStream(userId),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _ResourceLoading();
        }

        if (snapshot.hasError) {
          return _ResourceError(
            message:
                'Unable to load your videos.',
            onRetry: () {
              setState(() {});
            },
          );
        }

        final teachings =
            snapshot.data ?? [];

        if (teachings.isEmpty) {
          return const _EmptyResourceState(
            icon:
                Icons.video_library_outlined,
            title:
                'No downloaded videos',
            subtitle:
                'Videos you download will appear here',
          );
        }

        return _buildTeachingList(
          teachings,
        );
      },
    );
  }

  // ============================================================
  // AUDIO DOWNLOADS
  // ============================================================

  Widget _buildAudio(String userId) {
    return StreamBuilder<List<TeachingModel>>(
      stream:
          LibraryRepository.instance
              .audioDownloadsStream(userId),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _ResourceLoading();
        }

        if (snapshot.hasError) {
          return _ResourceError(
            message:
                'Unable to load your audio.',
            onRetry: () {
              setState(() {});
            },
          );
        }

        final teachings =
            snapshot.data ?? [];

        if (teachings.isEmpty) {
          return const _EmptyResourceState(
            icon:
                Icons.headphones_outlined,
            title:
                'No downloaded audio',
            subtitle:
                'Audio you download will appear here',
          );
        }

        return _buildTeachingList(
          teachings,
        );
      },
    );
  }

  // ============================================================
  // TEACHING LIST
  // ============================================================

  Widget _buildTeachingList(
    List<TeachingModel> teachings,
  ) {
    return RefreshIndicator(
      color: primaryColor,

      onRefresh: () async {
        await Future.delayed(
          const Duration(
            milliseconds: 400,
          ),
        );

        if (mounted) {
          setState(() {});
        }
      },

      child: ListView.separated(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),

        itemCount:
            teachings.length,

        separatorBuilder:
            (context, index) {
          return const SizedBox(
            height: 14,
          );
        },

        itemBuilder:
            (context, index) {
          final teaching =
              teachings[index];

          return _TeachingCard(
            teaching: teaching,
            onTap: () {
              _showTeachingDetails(
                teaching,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // TEACHING DETAILS
  // ============================================================

  void _showTeachingDetails(
    TeachingModel teaching,
  ) {
    final user = _currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              22,
              24,
              22,
              24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // HANDLE

                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey
                                .shade300,
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // IMAGE

                  _buildDetailsImage(
                    teaching,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // CATEGORY

                  Text(
                    teaching.category
                        .toUpperCase(),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          primaryColor,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  // TITLE

                  Text(
                    teaching.title,
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          darkPurple,
                    ),
                  ),

                  // SPEAKER

                  if (teaching.speaker
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      teaching.speaker,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],

                  // DURATION

                  if (teaching.duration
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .access_time_outlined,
                          size: 17,
                          color:
                              primaryColor,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          teaching.duration,
                          style:
                              TextStyle(
                            fontSize: 13,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // DESCRIPTION

                  if (teaching.description
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 18,
                    ),
                    Text(
                      teaching.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors
                            .grey
                            .shade700,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 25,
                  ),

                  // REMOVE DOWNLOAD

                  if (user != null)
                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          ElevatedButton
                              .icon(
                        onPressed:
                            () async {
                          try {
                            await LibraryRepository
                                .instance
                                .removeDownload(
                              userId:
                                  user.uid,
                              teachingId:
                                  teaching
                                      .id,
                            );

                            if (!sheetContext
                                .mounted) {
                              return;
                            }

                            Navigator.pop(
                              sheetContext,
                            );

                            ScaffoldMessenger
                                .of(
                              sheetContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Removed from your resources.',
                                ),
                                behavior:
                                    SnackBarBehavior
                                        .floating,
                              ),
                            );
                          } catch (e) {
                            if (!sheetContext
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger
                                .of(
                              sheetContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to remove resource.',
                                ),
                                behavior:
                                    SnackBarBehavior
                                        .floating,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons
                              .delete_outline,
                        ),
                        label:
                            const Text(
                          'Remove from Downloads',
                          style:
                              TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFFF1D9F7,
                          ),
                          foregroundColor:
                              primaryColor,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              26,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  // CLOSE

                  SizedBox(
                    width:
                        double.infinity,
                    height: 52,
                    child:
                        OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          sheetContext,
                        );
                      },
                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            darkPurple,
                        side:
                            const BorderSide(
                          color:
                              Color(
                            0xFFE3D7E8,
                          ),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            26,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Close',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAILS IMAGE
  // ============================================================

  Widget _buildDetailsImage(
    TeachingModel teaching,
  ) {
    if (teaching.imageUrl.isEmpty) {
      return _imagePlaceholder(
        teaching,
        height: 180,
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          teaching.imageUrl,
          fit: BoxFit.cover,
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return _imagePlaceholder(
              teaching,
              height: 180,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder(
    TeachingModel teaching, {
    double height = 120,
  }) {
    final isAudio =
        teaching.audioUrl.isNotEmpty &&
        teaching.videoUrl.isEmpty;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            const Color(0xFFF5EDF7),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Icon(
        isAudio
            ? Icons
                .headphones_outlined
            : Icons
                .video_library_outlined,
        size: 45,
        color: primaryColor,
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration:
          BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
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
                MainAxisAlignment
                    .spaceAround,
            children: [
              _BottomNavItem(
                icon:
                    Icons.home_rounded,
                label: 'Home',
                selected: false,
                onTap: () {
                  _onNavigationTapped(
                    0,
                  );
                },
              ),

              _BottomNavItem(
                icon: Icons
                    .library_books_outlined,
                label: 'My Library',
                selected: false,
                onTap: () {
                  _onNavigationTapped(
                    1,
                  );
                },
              ),

              _BottomNavItem(
                icon:
                    Icons.podcasts_outlined,
                label: 'Resources',
                selected: true,
                onTap: () {
                  _onNavigationTapped(
                    2,
                  );
                },
              ),

              _BottomNavItem(
                icon:
                    Icons.person_outline,
                label: 'Account',
                selected: false,
                onTap: () {
                  _onNavigationTapped(
                    3,
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
// TEACHING CARD
// ==================================================================

class _TeachingCard
    extends StatelessWidget {
  final TeachingModel teaching;
  final VoidCallback onTap;

  const _TeachingCard({
    required this.teaching,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAudio =
        teaching.audioUrl.isNotEmpty &&
        teaching.videoUrl.isEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color:
                const Color(
              0xFFEDE3F0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: .035,
              ),
              blurRadius: 10,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // THUMBNAIL

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: SizedBox(
                width: 95,
                height: 85,
                child:
                    teaching.imageUrl
                            .isNotEmpty
                        ? Image.network(
                            teaching
                                .imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return _placeholder(
                                isAudio,
                              );
                            },
                          )
                        : _placeholder(
                            isAudio,
                          ),
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            // CONTENT

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    isAudio
                        ? 'AUDIO'
                        : 'VIDEO',
                    style:
                        const TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight
                              .w800,
                      color:
                          Color(
                        0xFF6B1FA2,
                      ),
                      letterSpacing:
                          .7,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    teaching.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight
                              .w800,
                      color:
                          Color(
                        0xFF3D004D,
                      ),
                    ),
                  ),

                  if (teaching
                      .speaker
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      teaching.speaker,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        fontSize: 11,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],

                  if (teaching
                      .duration
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .access_time_outlined,
                          size: 13,
                          color:
                              Color(
                            0xFF9E9E9E,
                          ),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          teaching
                              .duration,
                          style:
                              TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons
                  .chevron_right_rounded,
              color:
                  Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(
    bool isAudio,
  ) {
    return Container(
      color:
          const Color(0xFFF5EDF7),
      child: Icon(
        isAudio
            ? Icons
                .headphones_outlined
            : Icons
                .video_library_outlined,
        color:
            const Color(0xFF6B1FA2),
        size: 32,
      ),
    );
  }
}

// ==================================================================
// EMPTY STATE
// ==================================================================

class _EmptyResourceState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyResourceState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 58,
              color:
                  const Color(
                0xFFD9D9D9,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w500,
                color:
                    Color(0xFF8D8D8D),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              subtitle,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Color(0xFFB5B5B5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// LOADING
// ==================================================================

class _ResourceLoading
    extends StatelessWidget {
  const _ResourceLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
          CircularProgressIndicator(
        color:
            Color(0xFF6B1FA2),
      ),
    );
  }
}

// ==================================================================
// ERROR
// ==================================================================

class _ResourceError
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ResourceError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .cloud_off_outlined,
              size: 55,
              color:
                  Color(0xFFD0D0D0),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF777777),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            OutlinedButton(
              onPressed: onRetry,
              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected
                        ? FontWeight
                            .w700
                        : FontWeight
                            .w500,
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