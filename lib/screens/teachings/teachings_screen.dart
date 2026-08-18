import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../models/teaching_model.dart';
import '../../repositories/content_repository.dart';

class TeachingsScreen extends StatefulWidget {
  const TeachingsScreen({super.key});

  @override
  State<TeachingsScreen> createState() => _TeachingsScreenState();
}

class _TeachingsScreenState extends State<TeachingsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER TEACHINGS
  // ============================================================

  List<TeachingModel> _filterTeachings(
    List<TeachingModel> teachings,
  ) {
    return teachings.where((teaching) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          teaching.title.toLowerCase().contains(_searchQuery) ||
          teaching.speaker.toLowerCase().contains(_searchQuery) ||
          teaching.category.toLowerCase().contains(_searchQuery) ||
          teaching.description.toLowerCase().contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == 'All' ||
          teaching.category.toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> _getCategories(
    List<TeachingModel> teachings,
  ) {
    final categories = <String>{};

    for (final teaching in teachings) {
      if (teaching.category.trim().isNotEmpty) {
        categories.add(teaching.category.trim());
      }
    }

    final result = categories.toList();

    result.sort();

    return [
      'All',
      ...result,
    ];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<TeachingModel>>(
        stream: ContentRepository.instance.teachingsStream(),
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _TeachingLoadingView();
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return _TeachingErrorView(
              message: snapshot.error.toString(),
            );
          }

          // ======================================================
          // DATA
          // ======================================================

          final teachings = snapshot.data ?? [];

          final categories = _getCategories(teachings);

          // Make sure selected category still exists.
          if (!categories.contains(_selectedCategory)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedCategory = 'All';
                });
              }
            });
          }

          final filteredTeachings =
              _filterTeachings(teachings);

          return RefreshIndicator(
            color: const Color(0xFF6B1FA2),
            onRefresh: () async {
              // Firestore streams update automatically.
              // This small delay gives RefreshIndicator
              // enough time to complete naturally.
              await Future.delayed(
                const Duration(milliseconds: 400),
              );
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ==================================================
                // HEADER
                // ==================================================

                SliverToBoxAdapter(
                  child: _buildHeader(
                    teachings.length,
                  ),
                ),

                // ==================================================
                // SEARCH
                // ==================================================

                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),

                // ==================================================
                // CATEGORIES
                // ==================================================

                SliverToBoxAdapter(
                  child: _buildCategories(
                    categories,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                // ==================================================
                // EMPTY STATE
                // ==================================================

                if (filteredTeachings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      hasTeachings: teachings.isNotEmpty,
                    ),
                  ),

                // ==================================================
                // TEACHINGS
                // ==================================================

                if (filteredTeachings.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final teaching =
                              filteredTeachings[index];

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 16,
                            ),
                            child: _TeachingCard(
                              teaching: teaching,
                              onTap: () {
                                _openTeaching(
                                  teaching,
                                );
                              },
                            ),
                          );
                        },
                        childCount:
                            filteredTeachings.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF3B1745),
          size: 20,
        ),
      ),
      title: const Text(
        'Teachings',
        style: TextStyle(
          color: Color(0xFF3B1745),
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: false,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(int totalTeachings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow in the Word',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202020),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Listen and watch teachings from RHIC.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalTeachings ${totalTeachings == 1 ? 'teaching' : 'teachings'}',
              style: const TextStyle(
                color: Color(0xFF6B1FA2),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFEDE7F0),
          ),
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search teachings...',
            hintStyle: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF6B1FA2),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF777777),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 4,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategories(
    List<String> categories,
  ) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          6,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected =
              category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF6B1FA2)
                    : const Color(0xFFF7F0F9),
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF6B1FA2),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required bool hasTeachings,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F0F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over_outlined,
                size: 38,
                color: Color(0xFF6B1FA2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasTeachings
                  ? 'No teachings found'
                  : 'No teachings available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasTeachings
                  ? 'Try a different search or category.'
                  : 'Published teachings will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPEN TEACHING
  // ============================================================

  void _openTeaching(
    TeachingModel teaching,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeachingDetailsScreen(
          teaching: teaching,
        ),
      ),
    );
  }
}

// ==================================================================
// TEACHING CARD
// ==================================================================

class _TeachingCard extends StatefulWidget {
  final TeachingModel teaching;
  final VoidCallback onTap;

  const _TeachingCard({
    required this.teaching,
    required this.onTap,
  });

  @override
  State<_TeachingCard> createState() =>
      _TeachingCardState();
}

class _TeachingCardState
    extends State<_TeachingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final teaching = widget.teaching;

    return GestureDetector(
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
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(
          milliseconds: 120,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFEDE7F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: .05,
                ),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ====================================================
              // IMAGE
              // ====================================================

              _TeachingImage(
                imageUrl: teaching.imageUrl,
              ),

              // ====================================================
              // CONTENT
              // ====================================================

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    14,
                    14,
                    13,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // CATEGORY

                      if (teaching.category
                          .trim()
                          .isNotEmpty)
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF7F0F9,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Text(
                            teaching.category
                                .toUpperCase(),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  Color(0xFF6B1FA2),
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // TITLE

                      Text(
                        teaching.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF2E1835),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // SPEAKER

                      if (teaching.speaker
                          .trim()
                          .isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 15,
                              color:
                                  Color(0xFF777777),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                teaching.speaker,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 12,
                                  color:
                                      Color(0xFF777777),
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      // DATE / DURATION

                      Row(
                        children: [
                          if (teaching.date
                              .trim()
                              .isNotEmpty) ...[
                            const Icon(
                              Icons
                                  .calendar_today_outlined,
                              size: 13,
                              color:
                                  Color(0xFF999999),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                teaching.date,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  fontSize: 10,
                                  color:
                                      Color(0xFF888888),
                                ),
                              ),
                            ),
                          ],
                          if (teaching.duration
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(width: 9),
                            const Icon(
                              Icons
                                  .access_time_outlined,
                              size: 13,
                              color:
                                  Color(0xFF999999),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              teaching.duration,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                color:
                                    Color(0xFF888888),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // MEDIA INDICATORS

                      Row(
                        children: [
                          if (teaching.audioUrl
                              .trim()
                              .isNotEmpty)
                            _MediaBadge(
                              icon:
                                  Icons.headphones,
                              label: 'Audio',
                            ),
                          if (teaching.audioUrl
                                  .trim()
                                  .isNotEmpty &&
                              teaching.videoUrl
                                  .trim()
                                  .isNotEmpty)
                            const SizedBox(width: 6),
                          if (teaching.videoUrl
                              .trim()
                              .isNotEmpty)
                            _MediaBadge(
                              icon: Icons.play_arrow,
                              label: 'Video',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  right: 10,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFFB7AABB),
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
// TEACHING IMAGE
// ==================================================================

class _TeachingImage extends StatelessWidget {
  final String imageUrl;

  const _TeachingImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 160,
      margin: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        color: const Color(0xFFF7F0F9),
      ),
      child: imageUrl.trim().isEmpty
          ? const Icon(
              Icons.record_voice_over,
              size: 36,
              color: Color(0xFF6B1FA2),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder:
                  (
                context,
                child,
                loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6B1FA2),
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported_outlined,
                  size: 34,
                  color: Color(0xFF9E7FA5),
                );
              },
            ),
    );
  }
}

// ==================================================================
// MEDIA BADGE
// ==================================================================

class _MediaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MediaBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FA),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF6B1FA2),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF6B1FA2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// TEACHING DETAILS SCREEN
// ==================================================================

class TeachingDetailsScreen extends StatelessWidget {
  final TeachingModel teaching;

  const TeachingDetailsScreen({
    super.key,
    required this.teaching,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ========================================================
          // HERO IMAGE
          // ========================================================

          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor:
                const Color(0xFF6B1FA2),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace:
                FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (teaching.imageUrl
                      .trim()
                      .isNotEmpty)
                    Image.network(
                      teaching.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color:
                              const Color(
                            0xFF6B1FA2,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration:
                          const BoxDecoration(
                        gradient:
                            LinearGradient(
                          begin:
                              Alignment.topLeft,
                          end: Alignment
                              .bottomRight,
                          colors: [
                            Color(0xFF58156F),
                            Color(0xFF9B2F87),
                            Color(0xFFF36C21),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end:
                            Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: .05,
                          ),
                          Colors.black.withValues(
                            alpha: .65,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================================
          // CONTENT
          // ========================================================

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                35,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // CATEGORY

                  if (teaching.category
                      .trim()
                      .isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: const Color(
                          0xFFF7F0F9,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: Text(
                        teaching.category
                            .toUpperCase(),
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF6B1FA2),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // TITLE

                  Text(
                    teaching.title,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.2,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color(0xFF2E1835),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // SPEAKER

                  if (teaching.speaker
                      .trim()
                      .isNotEmpty)
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFFF7F0F9),
                            shape:
                                BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color:
                                Color(0xFF6B1FA2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Speaker',
                                style:
                                    TextStyle(
                                  fontSize: 10,
                                  color:
                                      Color(0xFF999999),
                                ),
                              ),
                              Text(
                                teaching.speaker,
                                style:
                                    const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(0xFF3B1745),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // META

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (teaching.date
                          .trim()
                          .isNotEmpty)
                        _DetailMeta(
                          icon: Icons
                              .calendar_today_outlined,
                          text: teaching.date,
                        ),
                      if (teaching.duration
                          .trim()
                          .isNotEmpty)
                        _DetailMeta(
                          icon: Icons
                              .access_time_outlined,
                          text:
                              teaching.duration,
                        ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // MEDIA BUTTONS
                  // ==================================================

                  if (teaching.audioUrl
                      .trim()
                      .isNotEmpty)
                    _LargeMediaButton(
                      icon: Icons.headphones,
                      title: 'Listen to Audio',
                      subtitle:
                          'Play this teaching',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AudioPlayerScreen(
                              teaching: teaching,
                            ),
                          ),
                        );
                      },
                    ),

                  if (teaching.audioUrl
                          .trim()
                          .isNotEmpty &&
                      teaching.videoUrl
                          .trim()
                          .isNotEmpty)
                    const SizedBox(height: 12),

                  if (teaching.videoUrl
                      .trim()
                      .isNotEmpty)
                    _LargeMediaButton(
                      icon: Icons.play_circle_fill,
                      title: 'Watch Video',
                      subtitle:
                          'Watch this teaching',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeachingVideoScreen(
                              teaching: teaching,
                            ),
                          ),
                        );
                      },
                    ),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  if (teaching.description
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      'About this teaching',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF3B1745),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      teaching.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.65,
                        color:
                            Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// DETAIL META
// ==================================================================

class _DetailMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailMeta({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F9),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF6B1FA2),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// LARGE MEDIA BUTTON
// ==================================================================

class _LargeMediaButton
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LargeMediaButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFF6B1FA2),
                Color(0xFF8E3FC1),
              ],
            ),
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: .15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style:
                          TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: .75,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// AUDIO PLAYER
// ==================================================================

class AudioPlayerScreen extends StatefulWidget {
  final TeachingModel teaching;

  const AudioPlayerScreen({
    super.key,
    required this.teaching,
  });

  @override
  State<AudioPlayerScreen> createState() =>
      _AudioPlayerScreenState();
}

class _AudioPlayerScreenState
    extends State<AudioPlayerScreen> {
  late final AudioPlayer _player;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      await _player.setUrl(
        widget.teaching.audioUrl,
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Unable to play this audio.';
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF3B1745),
            size: 20,
          ),
        ),
        title: const Text(
          'Audio Player',
          style: TextStyle(
            color: Color(0xFF3B1745),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                    ),
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 25,
                        ),

                        // COVER

                        _PlayerArtwork(
                          teaching:
                              widget.teaching,
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        Text(
                          widget.teaching.title,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 23,
                            fontWeight:
                                FontWeight.w800,
                            color:
                                Color(0xFF3B1745),
                          ),
                        ),

                        if (widget
                            .teaching
                            .speaker
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            widget
                                .teaching
                                .speaker,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              color:
                                  Color(0xFF777777),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 30,
                        ),

                        // PROGRESS

                        StreamBuilder<Duration>(
                          stream:
                              _player.positionStream,
                          builder:
                              (
                            context,
                            snapshot,
                          ) {
                            final position =
                                snapshot.data ??
                                    Duration.zero;

                            final duration =
                                _player.duration ??
                                    Duration.zero;

                            final max = duration
                                .inMilliseconds
                                .toDouble();

                            final value =
                                max > 0
                                    ? position
                                        .inMilliseconds
                                        .clamp(
                                          0,
                                          duration
                                              .inMilliseconds,
                                        )
                                        .toDouble()
                                    : 0.0;

                            return Column(
                              children: [
                                Slider(
                                  value: value,
                                  max: max > 0
                                      ? max
                                      : 1,
                                  activeColor:
                                      const Color(
                                    0xFF6B1FA2,
                                  ),
                                  inactiveColor:
                                      const Color(
                                    0xFFE8DDEF,
                                  ),
                                  onChanged:
                                      max > 0
                                          ? (value) {
                                              _player
                                                  .seek(
                                                Duration(
                                                  milliseconds:
                                                      value.toInt(),
                                                ),
                                              );
                                            }
                                          : null,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(
                                          position,
                                        ),
                                        style:
                                            const TextStyle(
                                          fontSize: 11,
                                          color:
                                              Color(
                                            0xFF888888,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(
                                          duration,
                                        ),
                                        style:
                                            const TextStyle(
                                          fontSize: 11,
                                          color:
                                              Color(
                                            0xFF888888,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // PLAY BUTTON

                        StreamBuilder<PlayerState>(
                          stream:
                              _player.playerStateStream,
                          builder:
                              (
                            context,
                            snapshot,
                          ) {
                            final playing =
                                snapshot.data
                                        ?.playing ??
                                    false;

                            return GestureDetector(
                              onTap: () async {
                                if (playing) {
                                  await _player.pause();
                                } else {
                                  await _player.play();
                                }
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration:
                                    const BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    colors: [
                                      Color(
                                        0xFF6B1FA2,
                                      ),
                                      Color(
                                        0xFF8E3FC1,
                                      ),
                                    ],
                                  ),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child: Icon(
                                  playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color:
                                      Colors.white,
                                  size: 35,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatDuration(
    Duration duration,
  ) {
    final minutes =
        duration.inMinutes.remainder(60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        duration.inSeconds.remainder(60)
            .toString()
            .padLeft(2, '0');

    final hours = duration.inHours;

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}

// ==================================================================
// PLAYER ARTWORK
// ==================================================================

class _PlayerArtwork extends StatelessWidget {
  final TeachingModel teaching;

  const _PlayerArtwork({
    required this.teaching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6B1FA2,
            ).withValues(
              alpha: .18,
            ),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: teaching.imageUrl
              .trim()
              .isNotEmpty
          ? Image.network(
              teaching.imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (
                context,
                error,
                stackTrace,
              ) {
                return _fallback();
              },
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
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
        child: Icon(
          Icons.headphones,
          color: Colors.white,
          size: 65,
        ),
      ),
    );
  }
}

// ==================================================================
// VIDEO PLAYER
// ==================================================================

class TeachingVideoScreen
    extends StatefulWidget {
  final TeachingModel teaching;

  const TeachingVideoScreen({
    super.key,
    required this.teaching,
  });

  @override
  State<TeachingVideoScreen> createState() =>
      _TeachingVideoScreenState();
}

class _TeachingVideoScreenState
    extends State<TeachingVideoScreen> {
  late VideoPlayerController _controller;

  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(
        Uri.parse(
          widget.teaching.videoUrl,
        ),
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Unable to load this video.';
        });
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.teaching.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            )
          : !_initialized
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio:
                        _controller
                            .value
                            .aspectRatio,
                    child: Stack(
                      alignment:
                          Alignment.center,
                      children: [
                        VideoPlayer(
                          _controller,
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_controller
                                  .value
                                  .isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            });
                          },
                          child:
                              ValueListenableBuilder<
                                  VideoPlayerValue>(
                            valueListenable:
                                _controller,
                            builder:
                                (
                              context,
                              value,
                              child,
                            ) {
                              return AnimatedOpacity(
                                opacity:
                                    value.isPlaying
                                        ? 0.0
                                        : 1.0,
                                duration:
                                    const Duration(
                                  milliseconds:
                                      200,
                                ),
                                child:
                                    Container(
                                  width: 65,
                                  height: 65,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .black
                                        .withValues(
                                      alpha: .6,
                                    ),
                                    shape:
                                        BoxShape
                                            .circle,
                                  ),
                                  child:
                                      const Icon(
                                    Icons
                                        .play_arrow,
                                    color:
                                        Colors
                                            .white,
                                    size: 38,
                                  ),
                                ),
                              );
                            },
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
// LOADING VIEW
// ==================================================================

class _TeachingLoadingView
    extends StatelessWidget {
  const _TeachingLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF6B1FA2),
      ),
    );
  }
}

// ==================================================================
// ERROR VIEW
// ==================================================================

class _TeachingErrorView
    extends StatelessWidget {
  final String message;

  const _TeachingErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Color(0xFF6B1FA2),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load teachings',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}