import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../repositories/content_repository.dart';

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
      body: StreamBuilder<List<EventModel>>(
        stream: ContentRepository.instance.eventsStream(),
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
            return _buildErrorState();
          }

          // ======================================================
          // EVENTS
          // ======================================================

          final events = snapshot.data ?? [];

          // ======================================================
          // EMPTY
          // ======================================================

          if (events.isEmpty) {
            return _buildEmptyState();
          }

          // ======================================================
          // EVENT LIST
          // ======================================================

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 18,
                ),
                child: _EventCard(
                  event: event,
                  onTap: () {
                    _showEventDetails(
                      context,
                      event,
                    );
                  },
                ),
              );
            },
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
              'No Events Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no upcoming events at the moment.',
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
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
                Icons.error_outline,
                size: 38,
                color: Color(0xFF7B21A3),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to Load Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3B1745),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Something went wrong while loading events.',
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
              24,
              24,
              24,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                if (event.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      event.imageUrl,
                      width: double.infinity,
                      height: 210,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _buildImagePlaceholder(
                          height: 210,
                        );
                      },
                    ),
                  ),

                if (event.imageUrl.isNotEmpty)
                  const SizedBox(height: 22),

                // ==================================================
                // TITLE
                // ==================================================

                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D004D),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DATE
                // ==================================================

                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  text: event.date,
                ),

                const SizedBox(height: 12),

                // ==================================================
                // TIME
                // ==================================================

                _DetailRow(
                  icon: Icons.access_time_outlined,
                  text: event.time,
                ),

                // ==================================================
                // LOCATION
                // ==================================================

                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                ],

                const SizedBox(height: 22),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),

                const SizedBox(height: 25),

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

  Widget _buildImagePlaceholder({
    required double height,
  }) {
    return Container(
      width: double.infinity,
      height: height,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // IMAGE
            // ======================================================

            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: event.imageUrl.isNotEmpty
                  ? Image.network(
                      event.imageUrl,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _imagePlaceholder();
                      },
                    )
                  : _imagePlaceholder(),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B1745),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF6B1FA2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 16,
                        color: Color(0xFF6B1FA2),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF6B1FA2),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      Text(
                        'View Details',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1FA2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 17,
                        color: Color(0xFF6B1FA2),
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
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 190,
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
// DETAIL ROW
// ==================================================================

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF6B1FA2),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444444),
            ),
          ),
        ),
      ],
    );
  }
}