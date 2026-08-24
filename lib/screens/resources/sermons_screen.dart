import 'package:flutter/material.dart';

import '../../models/sermon_model.dart';
import '../../repositories/sermon_repository.dart';
import 'sermon_details_screen.dart';

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({
    super.key,
  });

  @override
  State<SermonsScreen> createState() =>
      _SermonsScreenState();
}

class _SermonsScreenState
    extends State<SermonsScreen> {
  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  int _selectedMediaTab = 0;

  String _selectedCategory = 'All';

  final TextEditingController
      _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Sermons',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: darkPurple,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              size: 29,
              color: Colors.black,
            ),
            onPressed: _showSearch,
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<List<SermonModel>>(
        stream:
            SermonRepository.instance
                .sermonsStream(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildError();
          }

          final sermons =
              snapshot.data ?? [];

          if (sermons.isEmpty) {
            return _buildEmpty();
          }

          return _buildContent(sermons);
        },
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildContent(
    List<SermonModel> sermons,
  ) {
    final categories =
        _buildCategories(sermons);

    final filtered =
        _filterSermons(sermons);

    final videos = filtered
        .where(
          (sermon) =>
              sermon.videoUrl.trim().isNotEmpty,
        )
        .toList();

    final audio = filtered
        .where(
          (sermon) =>
              sermon.audioUrl.trim().isNotEmpty,
        )
        .toList();

    final displayed =
        _selectedMediaTab == 0
            ? videos
            : audio;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        await Future.delayed(
          const Duration(milliseconds: 400),
        );

        if (mounted) {
          setState(() {});
        }
      },
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          bottom: 35,
        ),
        children: [
          // ======================================================
          // CATEGORY FILTERS
          // ======================================================

          _buildCategoryFilters(
            categories,
          ),

          const SizedBox(height: 25),

          // ======================================================
          // VIDEO / AUDIO
          // ======================================================

          _buildMediaTabs(),

          const SizedBox(height: 28),

          if (displayed.isEmpty)
            _buildNoMediaState()
          else ...[
            // ====================================================
            // FEATURED
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                _selectedMediaTab == 0
                    ? 'Videos'
                    : 'Audio',
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                  color: darkPurple,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _buildFeaturedList(
              displayed,
            ),

            const SizedBox(height: 28),

            // ====================================================
            // OTHER MESSAGES
            // ====================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                'Other Messages',
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w800,
                  color: darkPurple,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _buildOtherMessages(
              displayed,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  List<String> _buildCategories(
    List<SermonModel> sermons,
  ) {
    final Set<String> categorySet =
        <String>{};

    for (final sermon in sermons) {
      final category =
          sermon.category.trim();

      if (category.isNotEmpty) {
        categorySet.add(category);
      }
    }

    final categories =
        categorySet.toList();

    categories.sort(
      (a, b) => a.toLowerCase().compareTo(
        b.toLowerCase(),
      ),
    );

    return [
      'All',
      ...categories,
    ];
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<SermonModel> _filterSermons(
    List<SermonModel> sermons,
  ) {
    var result = sermons;

    // Category
    if (_selectedCategory != 'All') {
      result = result
          .where(
            (sermon) =>
                sermon.category
                    .trim()
                    .toLowerCase() ==
                _selectedCategory
                    .trim()
                    .toLowerCase(),
          )
          .toList();
    }

    // Search
    if (_searchQuery.trim().isNotEmpty) {
      final query =
          _searchQuery
              .trim()
              .toLowerCase();

      result = result
          .where(
            (sermon) {
              return sermon.title
                      .toLowerCase()
                      .contains(query) ||
                  sermon.speaker
                      .toLowerCase()
                      .contains(query) ||
                  sermon.category
                      .toLowerCase()
                      .contains(query);
            },
          )
          .toList();
    }

    return result;
  }

  // ============================================================
  // HORIZONTAL CATEGORY FILTER
  // ============================================================

  Widget _buildCategoryFilters(
    List<String> categories,
  ) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        itemCount: categories.length,
        separatorBuilder: (
          context,
          index,
        ) =>
            const SizedBox(width: 9),
        itemBuilder: (
          context,
          index,
        ) {
          final category =
              categories[index];

          final selected =
              _selectedCategory ==
                  category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory =
                    category;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              alignment:
                  Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? orangeColor
                    : Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  28,
                ),
                border: Border.all(
                  color: selected
                      ? orangeColor
                      : const Color(
                          0xFF9E9E9E,
                        ),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : const Color(
                          0xFF777777,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // VIDEO / AUDIO TABS
  // ============================================================

  Widget _buildMediaTabs() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MediaTab(
              title: 'Videos',
              selected:
                  _selectedMediaTab == 0,
              onTap: () {
                setState(() {
                  _selectedMediaTab = 0;
                });
              },
            ),
          ),

          Expanded(
            child: _MediaTab(
              title: 'Audio',
              selected:
                  _selectedMediaTab == 1,
              onTap: () {
                setState(() {
                  _selectedMediaTab = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURED
  // ============================================================

  Widget _buildFeaturedList(
    List<SermonModel> sermons,
  ) {
    final featured =
        sermons.take(5).toList();

    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        itemCount: featured.length,
        separatorBuilder: (
          context,
          index,
        ) =>
            const SizedBox(width: 18),
        itemBuilder: (
          context,
          index,
        ) {
          return _FeaturedSermonCard(
            sermon: featured[index],
            mediaType:
                _selectedMediaTab == 0
                    ? 'video'
                    : 'audio',
            onTap: () {
              _openSermon(
                featured[index],
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // OTHER MESSAGES
  // ============================================================

  Widget _buildOtherMessages(
    List<SermonModel> sermons,
  ) {
    final others = sermons.length > 5
        ? sermons.sublist(5)
        : <SermonModel>[];

    if (others.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Text(
          'More messages will appear here.',
          style: TextStyle(
            color:
                Colors.grey.shade500,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      itemCount: others.length,
      separatorBuilder: (
        context,
        index,
      ) =>
          const SizedBox(height: 18),
      itemBuilder: (
        context,
        index,
      ) {
        return _OtherSermonCard(
          sermon: others[index],
          mediaType:
              _selectedMediaTab == 0
                  ? 'video'
                  : 'audio',
          onTap: () {
            _openSermon(
              others[index],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // OPEN SERMON
  // ============================================================

  void _openSermon(
    SermonModel sermon,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SermonDetailsScreen(
          sermon: sermon,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _showSearch() {
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
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 25,
            bottom: MediaQuery.of(
                  sheetContext,
                ).viewInsets.bottom +
                25,
          ),
          child: TextField(
            autofocus: true,
            controller:
                _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration:
                InputDecoration(
              hintText:
                  'Search sermons...',
              prefixIcon:
                  const Icon(
                Icons.search_rounded,
                color: primaryColor,
              ),
              suffixIcon:
                  IconButton(
                icon:
                    const Icon(
                  Icons.close,
                ),
                onPressed: () {
                  _searchController
                      .clear();

                  setState(() {
                    _searchQuery = '';
                  });

                  Navigator.pop(
                    sheetContext,
                  );
                },
              ),
              filled: true,
              fillColor:
                  const Color(
                0xFFF7F3F8,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
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
                  .video_library_outlined,
              size: 60,
              color:
                  Color(0xFFD6D6D6),
            ),

            const SizedBox(height: 18),

            const Text(
              'No sermons available yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Published sermons will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color:
                  Color(0xFFD0D0D0),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load sermons.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton(
              onPressed: () {
                setState(() {});
              },
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO MEDIA
  // ============================================================

  Widget _buildNoMediaState() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 80,
      ),
      child: Column(
        children: [
          Icon(
            _selectedMediaTab == 0
                ? Icons
                    .video_library_outlined
                : Icons
                    .headphones_outlined,
            size: 55,
            color:
                const Color(0xFFD6D6D6),
          ),

          const SizedBox(height: 16),

          Text(
            _selectedMediaTab == 0
                ? 'No videos found'
                : 'No audio found',
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MEDIA TAB
// ================================================================

class _MediaTab
    extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _MediaTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment:
            Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? const Color(
                      0xFFF7931E,
                    )
                  : const Color(
                      0xFFE8E8E8,
                    ),
              width: selected ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w400,
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
  }
}

// ================================================================
// FEATURED CARD
// ================================================================

class _FeaturedSermonCard
    extends StatelessWidget {
  final SermonModel sermon;
  final String mediaType;
  final VoidCallback onTap;

  const _FeaturedSermonCard({
    required this.sermon,
    required this.mediaType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child:
                        sermon.imageUrl
                                .isNotEmpty
                            ? Image.network(
                                sermon.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return _placeholder();
                                },
                              )
                            : _placeholder(),
                  ),
                ),

                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration:
                          const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mediaType ==
                                'video'
                            ? Icons
                                .play_arrow_rounded
                            : Icons
                                .headphones_rounded,
                        color:
                            const Color(
                          0xFF6B1FA2,
                        ),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              sermon.title,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF3D004D),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              sermon.speaker,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 14,
                color:
                    Color(0xFFF7931E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color:
          const Color(0xFFF3EAF5),
      child: const Center(
        child: Icon(
          Icons
              .video_library_outlined,
          size: 55,
          color:
              Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ================================================================
// OTHER MESSAGE CARD
// ================================================================

class _OtherSermonCard
    extends StatelessWidget {
  final SermonModel sermon;
  final String mediaType;
  final VoidCallback onTap;

  const _OtherSermonCard({
    required this.sermon,
    required this.mediaType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: SizedBox(
              width: 195,
              height: 125,
              child:
                  sermon.imageUrl
                          .isNotEmpty
                      ? Image.network(
                          sermon.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _placeholder();
                          },
                        )
                      : _placeholder(),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  sermon.title,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF3D004D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  sermon.speaker,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFFF7931E),
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .access_time_outlined,
                      size: 13,
                      color:
                          Color(0xFFAAAAAA),
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        sermon.duration
                                .isNotEmpty
                            ? sermon.duration
                            : sermon.date,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Color(
                            0xFFAAAAAA,
                          ),
                        ),
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

  Widget _placeholder() {
    return Container(
      color:
          const Color(0xFFF3EAF5),
      child: const Center(
        child: Icon(
          Icons
              .video_library_outlined,
          size: 35,
          color:
              Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}