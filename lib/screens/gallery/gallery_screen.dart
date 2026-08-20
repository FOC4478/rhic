import 'package:flutter/material.dart';

import '../../models/gallery_model.dart';
import '../../repositories/content_repository.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF3B1745),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Gallery',
          style: TextStyle(
            color: Color(0xFF3B1745),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GalleryItem>>(
        stream: ContentRepository.instance.galleryStream(),
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _GalleryLoading();
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return _GalleryError(
              onRetry: () {
                setState(() {});
              },
            );
          }

          // ======================================================
          // DATA
          // ======================================================

          final galleryItems = snapshot.data ?? [];

          if (galleryItems.isEmpty) {
            return const _EmptyGallery();
          }

          final filteredItems = galleryItems.where((item) {
            if (_searchQuery.trim().isEmpty) {
              return true;
            }

            final query = _searchQuery.toLowerCase();

            return item.title.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            color: const Color(0xFF6B1FA2),
            onRefresh: () async {
              setState(() {});
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ==================================================
                // HEADER
                // ==================================================

                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                // ==================================================
                // SEARCH
                // ==================================================

                SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 22),
                ),

                // ==================================================
                // RESULTS
                // ==================================================

                if (filteredItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoSearchResults(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      0,
                      18,
                      30,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredItems[index];

                          return _GalleryCard(
                            item: item,
                            animation: CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                (index * 0.08).clamp(0.0, 0.7),
                                1.0,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            onTap: () {
                              _openImageViewer(
                                context,
                                item,
                                filteredItems,
                                index,
                              );
                            },
                          );
                        },
                        childCount: filteredItems.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.82,
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
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Moments',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B1FA2),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Explore moments from RHIC.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
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
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search gallery...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF6B1FA2),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8F3FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF8E3FC1),
              width: 1.2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE VIEWER
  // ============================================================

  void _openImageViewer(
    BuildContext context,
    GalleryItem item,
    List<GalleryItem> items,
    int index,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(
          milliseconds: 300,
        ),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return _GalleryViewer(
            items: items,
            initialIndex: index,
          );
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}

// ==================================================================
// GALLERY CARD
// ==================================================================

class _GalleryCard extends StatelessWidget {
  final GalleryItem item;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _GalleryCard({
    required this.item,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.07,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _GalleryImage(
                        imageUrl: item.imageUrl,
                      ),

                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.38,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.open_in_full,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // DETAILS
                // ==================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    11,
                    13,
                    13,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (item.title.isNotEmpty)
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B1745),
                          ),
                        ),
                      if (item.title.isNotEmpty &&
                          item.description.isNotEmpty)
                        const SizedBox(height: 4),
                      if (item.description.isNotEmpty)
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
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
// GALLERY IMAGE
// ==================================================================

class _GalleryImage extends StatelessWidget {
  final String imageUrl;

  const _GalleryImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF3EAF6),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF8E3FC1),
            size: 42,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (
        context,
        child,
        loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: const Color(0xFFF3EAF6),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6B1FA2),
            ),
          ),
        );
      },
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: const Color(0xFFF3EAF6),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Color(0xFF8E3FC1),
              size: 42,
            ),
          ),
        );
      },
    );
  }
}

// ==================================================================
// FULL SCREEN VIEWER
// ==================================================================

class _GalleryViewer extends StatefulWidget {
  final List<GalleryItem> items;
  final int initialIndex;

  const _GalleryViewer({
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.items.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // ========================================================
          // IMAGE
          // ========================================================

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final galleryItem = widget.items[index];

                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      galleryItem.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // ========================================================
          // INFORMATION
          // ========================================================

          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                22,
                16,
                22,
                20,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.85,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (item.title.isNotEmpty &&
                      item.description.isNotEmpty)
                    const SizedBox(height: 6),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
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

// ==================================================================
// LOADING
// ==================================================================

class _GalleryLoading extends StatelessWidget {
  const _GalleryLoading();

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
// EMPTY
// ==================================================================

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EAF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF6B1FA2),
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Gallery Images Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Published photos from RHIC will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// SEARCH EMPTY
// ==================================================================

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 55,
              color: Color(0xFF8E3FC1),
            ),
            const SizedBox(height: 15),
            const Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different word.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// ERROR
// ==================================================================

class _GalleryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _GalleryError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Color(0xFF6B1FA2),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to Load Gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong while loading the gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B1FA2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}