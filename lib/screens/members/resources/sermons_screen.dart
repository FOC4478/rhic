import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../models/sermon_model.dart';
import '../../../repositories/sermon_repository.dart';
import '../../../services/b2_upload_service.dart';

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

  int _selectedMediaTab = 0;

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
              child: CircularProgressIndicator(
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
    final filtered =
        _filterSermons(sermons);

    final videos = filtered
        .where(
          (sermon) => sermon.hasVideo,
        )
        .toList();

    final audio = filtered
        .where(
          (sermon) => sermon.hasAudio,
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
          const Duration(
            milliseconds: 400,
          ),
        );

        if (mounted) {
          setState(() {});
        }
      },

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.only(
          bottom: 40,
        ),

        children: [
          const SizedBox(height: 12),

          _buildMediaTabs(),

          const SizedBox(height: 28),

          if (displayed.isEmpty)
            _buildNoMediaState()
          else if (_selectedMediaTab == 0)
            _buildVideoContent(displayed)
          else
            _buildAudioContent(displayed),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH FILTER
  // ============================================================

  List<SermonModel> _filterSermons(
    List<SermonModel> sermons,
  ) {
    if (_searchQuery.trim().isEmpty) {
      return sermons;
    }

    final query =
        _searchQuery
            .trim()
            .toLowerCase();

    return sermons.where(
      (sermon) {
        return sermon.title
                .toLowerCase()
                .contains(query) ||
            sermon.speaker
                .toLowerCase()
                .contains(query) ||
            sermon.description
                .toLowerCase()
                .contains(query);
      },
    ).toList();
  }

  // ============================================================
  // MEDIA TABS
  // ============================================================

  Widget _buildMediaTabs() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
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
  // VIDEO CONTENT
  // ============================================================

  Widget _buildVideoContent(
    List<SermonModel> sermons,
  ) {
    final featured =
        sermons.take(5).toList();

    final others = sermons.length > 5
        ? sermons.sublist(5)
        : <SermonModel>[];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Text(
            'Videos',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: darkPurple,
            ),
          ),
        ),

        const SizedBox(height: 15),

        // ======================================================
        // FEATURED VIDEOS
        // ======================================================

        SizedBox(
          height: 300,

          child: ListView.separated(
            scrollDirection:
                Axis.horizontal,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 25,
            ),

            itemCount:
                featured.length,

            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              width: 20,
            ),

            itemBuilder:
                (context, index) {
              final sermon =
                  featured[index];

              return _FeaturedVideoCard(
                sermon: sermon,
                loading:
                    _isLoadingSermon(
                  sermon.id,
                ),
                onTap: () {
                  _openVideo(sermon);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 25),

        const Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Text(
            'Other Messages',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: darkPurple,
            ),
          ),
        ),

        const SizedBox(height: 15),

        if (others.isEmpty)
          _buildMoreMessagesPlaceholder()
        else
          ...others.map(
            (sermon) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 18,
                  left: 25,
                  right: 25,
                ),
                child: _OtherVideoCard(
                  sermon: sermon,
                  loading:
                      _isLoadingSermon(
                    sermon.id,
                  ),
                  onTap: () {
                    _openVideo(sermon);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // ============================================================
  // AUDIO CONTENT
  // ============================================================

  Widget _buildAudioContent(
    List<SermonModel> sermons,
  ) {
    final featured =
        sermons.isNotEmpty
            ? sermons.first
            : null;

    final others = sermons.length > 1
        ? sermons.sublist(1)
        : <SermonModel>[];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Text(
            'Audio',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: darkPurple,
            ),
          ),
        ),

        const SizedBox(height: 15),

        // ======================================================
        // FEATURED AUDIO
        // ======================================================

        if (featured != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 25,
            ),
            child: _FeaturedAudioCard(
              sermon: featured,
              loading:
                  _isLoadingSermon(
                featured.id,
              ),
              onTap: () {
                _openAudio(featured);
              },
            ),
          ),

        const SizedBox(height: 28),

        // ======================================================
        // OTHER AUDIO
        // ======================================================

        if (others.isNotEmpty) ...[
          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 25,
            ),
            child: Text(
              'Other Messages',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: darkPurple,
              ),
            ),
          ),

          const SizedBox(height: 15),

          ...others.map(
            (sermon) {
              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 18,
                  left: 25,
                  right: 25,
                ),
                child: _OtherAudioCard(
                  sermon: sermon,
                  loading:
                      _isLoadingSermon(
                    sermon.id,
                  ),
                  onTap: () {
                    _openAudio(sermon);
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // ============================================================
  // LOADING TRACKING
  // ============================================================

  String? _loadingSermonId;

  bool _isLoadingSermon(
    String sermonId,
  ) {
    return _loadingSermonId == sermonId;
  }

  // ============================================================
  // OPEN VIDEO DIRECTLY
  // ============================================================

  Future<void> _openVideo(
    SermonModel sermon,
  ) async {
    final objectKey =
        sermon.videoStoragePath.trim();

    final legacyUrl =
        sermon.videoUrl.trim();

    if (objectKey.isEmpty &&
        legacyUrl.isEmpty) {
      _showMessage(
        'No video is available for this sermon.',
      );
      return;
    }

    setState(() {
      _loadingSermonId = sermon.id;
    });

    try {
      String url;

      if (objectKey.isNotEmpty) {
        url = await B2UploadService
            .instance
            .getDownloadUrl(
          objectKey: objectKey,
        );
      } else {
        url = legacyUrl;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingSermonId = null;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SermonVideoPlayerScreen(
            url: url,
            title: sermon.title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingSermonId = null;
      });

      _showMessage(
        'Unable to open video.',
      );
    }
  }

  // ============================================================
  // OPEN AUDIO DIRECTLY
  // ============================================================

  Future<void> _openAudio(
    SermonModel sermon,
  ) async {
    final objectKey =
        sermon.audioStoragePath.trim();

    final legacyUrl =
        sermon.audioUrl.trim();

    if (objectKey.isEmpty &&
        legacyUrl.isEmpty) {
      _showMessage(
        'No audio is available for this sermon.',
      );
      return;
    }

    setState(() {
      _loadingSermonId = sermon.id;
    });

    try {
      String url;

      if (objectKey.isNotEmpty) {
        url = await B2UploadService
            .instance
            .getDownloadUrl(
          objectKey: objectKey,
        );
      } else {
        url = legacyUrl;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingSermonId = null;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SermonAudioPlayerScreen(
            url: url,
            title: sermon.title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingSermonId = null;
      });

      _showMessage(
        'Unable to open audio.',
      );
    }
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
            bottom:
                MediaQuery.of(
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
                icon: const Icon(
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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
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
            style:
                const TextStyle(
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

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _buildMoreMessagesPlaceholder() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
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
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 48,

        alignment:
            Alignment.center,

        decoration:
            BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? const Color(
                      0xFFF7931E,
                    )
                  : const Color(
                      0xFFE8E8E8,
                    ),
              width:
                  selected ? 3 : 1,
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
// FEATURED VIDEO CARD
// ================================================================

class _FeaturedVideoCard
    extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;
  final bool loading;

  const _FeaturedVideoCard({
    required this.sermon,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 420,

      child: GestureDetector(
        onTap: loading ? null : onTap,

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
                    width:
                        double.infinity,
                    height: 220,

                    child: _SermonImage(
                      sermon: sermon,
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : _PlayButton(
                            size: 58,
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
}

// ================================================================
// OTHER VIDEO CARD
// ================================================================

class _OtherVideoCard
    extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;
  final bool loading;

  const _OtherVideoCard({
    required this.sermon,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: loading ? null : onTap,

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                child: SizedBox(
                  width: 195,
                  height: 125,

                  child: _SermonImage(
                    sermon: sermon,
                  ),
                ),
              ),

              Positioned.fill(
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : _PlayButton(
                          size: 36,
                        ),
                ),
              ),
            ],
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

                Text(
                  sermon.date,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFFAAAAAA),
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
// FEATURED AUDIO CARD
// ================================================================

class _FeaturedAudioCard
    extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;
  final bool loading;

  const _FeaturedAudioCard({
    required this.sermon,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: loading ? null : onTap,

      child: Column(
        children: [
          Stack(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: _SermonImage(
                    sermon: sermon,
                  ),
                ),
              ),

              Positioned.fill(
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : _PlayButton(
                          size: 58,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            sermon.title,
            textAlign:
                TextAlign.center,
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
            textAlign:
                TextAlign.center,
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
    );
  }
}

// ================================================================
// OTHER AUDIO CARD
// ================================================================

class _OtherAudioCard
    extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;
  final bool loading;

  const _OtherAudioCard({
    required this.sermon,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: loading ? null : onTap,

      child: Row(
        children: [
          Stack(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: _SermonImage(
                    sermon: sermon,
                  ),
                ),
              ),

              Positioned.fill(
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : _PlayButton(
                          size: 32,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  sermon.title,
                  maxLines: 2,
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

                const SizedBox(height: 5),

                Text(
                  sermon.speaker,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFFF7931E),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  sermon.date,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Color(0xFFAAAAAA),
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
// SERMON IMAGE
// ================================================================

class _SermonImage
    extends StatelessWidget {
  final SermonModel sermon;

  const _SermonImage({
    required this.sermon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final imageUrl =
        sermon.imageUrl.trim();

    if (imageUrl.isEmpty) {
      return _placeholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,

      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _placeholder();
      },
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
          size: 45,
          color:
              Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ================================================================
// PLAY BUTTON
// ================================================================

class _PlayButton
    extends StatelessWidget {
  final double size;

  const _PlayButton({
    required this.size,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: size,
      height: size,

      decoration:
          const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),

      child: Icon(
        Icons.play_arrow_rounded,
        color:
            const Color(0xFF6B1FA2),
        size: size * .55,
      ),
    );
  }
}

// ================================================================
// AUDIO PLAYER SCREEN
// ================================================================

class SermonAudioPlayerScreen
    extends StatefulWidget {
  final String url;
  final String title;

  const SermonAudioPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SermonAudioPlayerScreen>
      createState() =>
          _SermonAudioPlayerScreenState();
}

class _SermonAudioPlayerScreenState
    extends State<
        SermonAudioPlayerScreen> {
  final AudioPlayer _player =
      AudioPlayer();

  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setUrl(
        widget.url,
      );

      if (mounted) {
        await _player.play();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to play this audio.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _seek(
    Duration amount,
  ) async {
    final position =
        _player.position;

    final duration =
        _player.duration ??
            Duration.zero;

    var target =
        position + amount;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (duration != Duration.zero &&
        target > duration) {
      target = duration;
    }

    await _player.seek(target);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Audio',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF3D004D),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(25),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons
                    .headphones_rounded,
                size: 110,
                color:
                    Color(0xFF6B1FA2),
              ),

              const SizedBox(
                height: 30,
              ),

              Text(
                widget.title,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      Color(0xFF3D004D),
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              StreamBuilder<
                  Duration>(
                stream:
                    _player
                        .positionStream,

                builder: (
                  context,
                  positionSnapshot,
                ) {
                  final position =
                      positionSnapshot
                              .data ??
                          Duration.zero;

                  return StreamBuilder<
                      Duration?>(
                    stream:
                        _player
                            .durationStream,

                    builder: (
                      context,
                      durationSnapshot,
                    ) {
                      final duration =
                          durationSnapshot
                                  .data ??
                              Duration.zero;

                      final max =
                          duration
                                      .inMilliseconds >
                                  0
                              ? duration
                                  .inMilliseconds
                                  .toDouble()
                              : 1.0;

                      final value =
                          position
                              .inMilliseconds
                              .toDouble()
                              .clamp(
                                0.0,
                                max,
                              );

                      return Column(
                        children: [
                          Slider(
                            min: 0,
                            max: max,
                            value: value,
                            activeColor:
                                const Color(
                              0xFF6B1FA2,
                            ),
                            inactiveColor:
                                const Color(
                              0xFFE5D9E8,
                            ),
                            onChanged:
                                duration ==
                                        Duration
                                            .zero
                                    ? null
                                    : (
                                        value,
                                      ) {
                                        _player
                                            .seek(
                                          Duration(
                                            milliseconds:
                                                value
                                                    .round(),
                                          ),
                                        );
                                      },
                          ),

                          Row(
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
                                  fontSize:
                                      11,
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
                                  fontSize:
                                      11,
                                  color:
                                      Color(
                                    0xFF888888,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              StreamBuilder<
                  PlayerState>(
                stream:
                    _player
                        .playerStateStream,

                builder: (
                  context,
                  snapshot,
                ) {
                  final state =
                      snapshot.data;

                  final playing =
                      state?.playing ??
                          false;

                  final processing =
                      state?.processingState ==
                              ProcessingState
                                  .loading ||
                          state?.processingState ==
                              ProcessingState
                                  .buffering;

                  return Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      IconButton(
                        iconSize: 32,
                        onPressed:
                            processing
                                ? null
                                : () {
                                    _seek(
                                      const Duration(
                                        seconds:
                                            -10,
                                      ),
                                    );
                                  },
                        icon:
                            const Icon(
                          Icons
                              .replay_10_rounded,
                        ),
                      ),

                      const SizedBox(
                        width: 15,
                      ),

                      GestureDetector(
                        onTap:
                            processing
                                ? null
                                : () async {
                                    if (playing) {
                                      await _player
                                          .pause();
                                    } else {
                                      await _player
                                          .play();
                                    }
                                  },

                        child:
                            Container(
                          width: 72,
                          height: 72,
                          decoration:
                              const BoxDecoration(
                            color:
                                Color(
                              0xFF6B1FA2,
                            ),
                            shape:
                                BoxShape
                                    .circle,
                          ),
                          child: processing
                              ? const Padding(
                                  padding:
                                      EdgeInsets.all(
                                    22,
                                  ),
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors
                                            .white,
                                  ),
                                )
                              : Icon(
                                  playing
                                      ? Icons
                                          .pause_rounded
                                      : Icons
                                          .play_arrow_rounded,
                                  color:
                                      Colors
                                          .white,
                                  size: 40,
                                ),
                        ),
                      ),

                      const SizedBox(
                        width: 15,
                      ),

                      IconButton(
                        iconSize: 32,
                        onPressed:
                            processing
                                ? null
                                : () {
                                    _seek(
                                      const Duration(
                                        seconds:
                                            10,
                                      ),
                                    );
                                  },
                        icon:
                            const Icon(
                          Icons
                              .forward_10_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              DropdownButton<double>(
                value: _speed,

                items: const [
                  0.5,
                  0.75,
                  1.0,
                  1.25,
                  1.5,
                  2.0,
                ].map(
                  (speed) {
                    return DropdownMenuItem<
                        double>(
                      value: speed,
                      child: Text(
                        '${speed}x',
                      ),
                    );
                  },
                ).toList(),

                onChanged: (
                  value,
                ) {
                  if (value ==
                      null) {
                    return;
                  }

                  setState(() {
                    _speed = value;
                  });

                  _player.setSpeed(
                    value,
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

// ================================================================
// VIDEO PLAYER SCREEN
// ================================================================

class SermonVideoPlayerScreen
    extends StatefulWidget {
  final String url;
  final String title;

  const SermonVideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SermonVideoPlayerScreen>
      createState() =>
          _SermonVideoPlayerScreenState();
}

class _SermonVideoPlayerScreenState
    extends State<
        SermonVideoPlayerScreen> {
  late VideoPlayerController
      _controller;

  bool _loading = true;
  bool _hasError = false;

  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller =
          VideoPlayerController
              .networkUrl(
        Uri.parse(widget.url),
      );

      await _controller
          .initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      // Immediately start playback.
      await _controller.play();

      _controller.addListener(
        _videoListener,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  void _videoListener() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    if (!_loading &&
        !_hasError) {
      _controller
          .removeListener(
        _videoListener,
      );

      _controller.dispose();
    }

    super.dispose();
  }

  Future<void> _seek(
    Duration amount,
  ) async {
    final current =
        _controller.value.position;

    final duration =
        _controller.value.duration;

    var target =
        current + amount;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (target > duration) {
      target = duration;
    }

    await _controller.seekTo(
      target,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      appBar: AppBar(
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
        elevation: 0,

        title: Text(
          widget.title,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _hasError
              ? _buildError()
              : _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    final controller =
        _controller;

    final value =
        controller.value;

    return SafeArea(
      child: Column(
        children: [
          const Spacer(),

          AspectRatio(
            aspectRatio:
                value.aspectRatio,
            child:
                VideoPlayer(
              controller,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 20,
            ),
            colors:
                const VideoProgressColors(
              playedColor:
                  Color(0xFFF7931E),
              bufferedColor:
                  Color(0xFF777777),
              backgroundColor:
                  Color(0xFF444444),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              IconButton(
                color: Colors.white,
                iconSize: 32,
                onPressed: () {
                  _seek(
                    const Duration(
                      seconds: -10,
                    ),
                  );
                },
                icon: const Icon(
                  Icons
                      .replay_10_rounded,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              IconButton(
                color: Colors.white,
                iconSize: 65,
                onPressed: () {
                  if (controller
                      .value
                      .isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }

                  setState(() {});
                },
                icon: Icon(
                  controller
                          .value
                          .isPlaying
                      ? Icons
                          .pause_circle
                      : Icons
                          .play_circle,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              IconButton(
                color: Colors.white,
                iconSize: 32,
                onPressed: () {
                  _seek(
                    const Duration(
                      seconds: 10,
                    ),
                  );
                },
                icon: const Icon(
                  Icons
                      .forward_10_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          DropdownButton<double>(
            value: _speed,

            dropdownColor:
                Colors.grey.shade900,

            style:
                const TextStyle(
              color: Colors.white,
            ),

            items: const [
              0.5,
              0.75,
              1.0,
              1.25,
              1.5,
              2.0,
            ].map(
              (speed) {
                return DropdownMenuItem<
                    double>(
                  value: speed,
                  child: Text(
                    '${speed}x',
                  ),
                );
              },
            ).toList(),

            onChanged: (
              value,
            ) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                _speed = value;
              });

              _controller
                  .setPlaybackSpeed(
                value,
              );
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }

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
              Icons
                  .error_outline_rounded,
              color: Colors.white,
              size: 60,
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Unable to play this video.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            OutlinedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.white,
                side:
                    const BorderSide(
                  color: Colors.white,
                ),
              ),
              child:
                  const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FORMAT DURATION
// ================================================================

String _formatDuration(
  Duration duration,
) {
  if (duration == Duration.zero) {
    return '0:00';
  }

  final hours =
      duration.inHours;

  final minutes =
      duration.inMinutes
          .remainder(60);

  final seconds =
      duration.inSeconds
          .remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}