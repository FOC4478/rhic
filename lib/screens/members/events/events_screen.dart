import 'package:flutter/material.dart';

import '../../../models/event_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../services/media_url_service.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Events',
          style: TextStyle(
            color: Color(0xFF3B1745),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF3B1745),
        ),
      ),
      body: StreamBuilder<EventModel?>(
        stream: ContentRepository.instance.eventStream(),
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Event error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ======================================================
          // EVENT
          // ======================================================

          final event = snapshot.data;

          // ======================================================
          // EMPTY
          // ======================================================

          if (event == null || event.imageObjectKey.isEmpty) {
            return _buildEmptyState();
          }

          // ======================================================
          // CURRENT EVENT FLYER
          // ======================================================

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              _EventCard(
                event: event,
                onTap: () {
                  _showEventDetails(
                    context,
                    event,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF9EAFB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 38,
                color: Color(0xFF7B21A3),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Event Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There is no event flyer available at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
  // EVENT DETAILS
  // ============================================================

  void _showEventDetails(
    BuildContext context,
    EventModel event,
  ) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            child: Column(
              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                if (event.imageObjectKey.isNotEmpty)
                  _B2EventImage(
                    storagePath: event.imageObjectKey,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    borderRadius: 22,
                  )
                else
                  _buildImagePlaceholder(),

                const SizedBox(height: 22),

                // ==================================================
                // CLOSE BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D004D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF58156F),
            Color(0xFF9B2F87),
            Color(0xFFF36C21),
          ],
        ),
      ),
      child: const Icon(
        Icons.calendar_month,
        color: Colors.white,
        size: 50,
      ),
    );
  }
}

// ==================================================================
// EVENT CARD
// ==================================================================

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE8C9ED),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B1FA2).withValues(
                alpha: .08,
              ),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: event.imageObjectKey.isNotEmpty
              ? _B2EventImage(
                  storagePath: event.imageObjectKey,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  borderRadius: 0,
                )
              : _imagePlaceholder(),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF58156F),
            Color(0xFF9B2F87),
            Color(0xFFF36C21),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.calendar_month,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

// ==================================================================
// B2 EVENT IMAGE
// ==================================================================

class _B2EventImage extends StatefulWidget {
  final String storagePath;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

  const _B2EventImage({
    required this.storagePath,
    required this.width,
    required this.fit,
    required this.borderRadius,
  });

  @override
  State<_B2EventImage> createState() => _B2EventImageState();
}

class _B2EventImageState extends State<_B2EventImage> {
  String? _downloadUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final url =
          await MediaUrlService.instance.getEventDownloadUrl(
        storagePath: widget.storagePath,
      );

      if (!mounted) return;

      setState(() {
        _downloadUrl = url;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_loading) {
      return Container(
        width: widget.width,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            widget.borderRadius,
          ),
          color: const Color(0xFFF9EAFB),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B1FA2),
          ),
        ),
      );
    }

    // ==========================================================
    // DOWNLOAD URL FAILED
    // ==========================================================

    if (_downloadUrl == null || _downloadUrl!.isEmpty) {
      return Container(
        width: widget.width,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            widget.borderRadius,
          ),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF58156F),
              Color(0xFF9B2F87),
              Color(0xFFF36C21),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    }

    // ==========================================================
    // DISPLAY B2 IMAGE
    // ==========================================================

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        widget.borderRadius,
      ),
      child: Image.network(
        _downloadUrl!,
        width: widget.width,
        fit: widget.fit,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: widget.width,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                widget.borderRadius,
              ),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF58156F),
                  Color(0xFF9B2F87),
                  Color(0xFFF36C21),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          );
        },
      ),
    );
  }
}