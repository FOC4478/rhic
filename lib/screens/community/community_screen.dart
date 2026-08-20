import 'package:flutter/material.dart';

import '../../models/community_group_model.dart';
import '../../repositories/content_repository.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER GROUPS
  // ============================================================

  List<CommunityGroupModel> _filterGroups(
    List<CommunityGroupModel> groups,
  ) {
    if (_searchQuery.isEmpty) {
      return groups;
    }

    return groups.where((group) {
      final name = group.name.toLowerCase();
      final department = group.department.toLowerCase();
      final description = group.description.toLowerCase();

      return name.contains(_searchQuery) ||
          department.contains(_searchQuery) ||
          description.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ==================================================
            // HEADER
            // ==================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF7F2F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF4A2454),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'RHIC Community',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3D004D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // INTRO
            // ==================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connect. Grow. Belong.',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B1FA2),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Join a department or community group and connect with other members of RHIC.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // SEARCH
            // ==================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search community groups',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B1FA2),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                    filled: true,
                    fillColor: const Color(0xFFF8F4FA),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF8E3FC1),
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // ==================================================
            // GROUPS
            // ==================================================

            StreamBuilder<List<CommunityGroupModel>>(
              stream: ContentRepository.instance
                  .communityGroupsStream(),
              builder: (
                context,
                snapshot,
              ) {
                // ------------------------------------------------
                // LOADING
                // ------------------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B1FA2),
                      ),
                    ),
                  );
                }

                // ------------------------------------------------
                // ERROR
                // ------------------------------------------------

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(
                      snapshot.error.toString(),
                    ),
                    );
                }

                final groups =
                    _filterGroups(snapshot.data ?? []);

                // ------------------------------------------------
                // NO GROUPS
                // ------------------------------------------------

                if (groups.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }

                // ------------------------------------------------
                // GROUP LIST
                // ------------------------------------------------

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    30,
                  ),
                  sliver: SliverList(
                    delegate:
                        SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: _CommunityGroupCard(
                            group: group,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/community-group',
                                arguments: group.id,
                              );
                            },
                          ),
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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
              width: 85,
              height: 85,
              decoration: const BoxDecoration(
                color: Color(0xFFF7EAF9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 42,
                color: Color(0xFF6B1FA2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty
                  ? 'No community groups yet'
                  : 'No groups found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D004D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Community groups will appear here when they are published.'
                  : 'Try searching for another group or department.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.redAccent,
              ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
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
// COMMUNITY GROUP CARD
// ==================================================================

class _CommunityGroupCard extends StatefulWidget {
  final CommunityGroupModel group;
  final VoidCallback onTap;

  const _CommunityGroupCard({
    required this.group,
    required this.onTap,
  });

  @override
  State<_CommunityGroupCard> createState() =>
      _CommunityGroupCardState();
}

class _CommunityGroupCardState
    extends State<_CommunityGroupCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

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
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(
          milliseconds: 120,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8C9ED),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: .05,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ==================================================
              // GROUP IMAGE
              // ==================================================

              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: group.coverImageUrl.isNotEmpty
                      ? Image.network(
                          group.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return _buildImageFallback();
                          },
                        )
                      : _buildImageFallback(),
                ),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // GROUP INFORMATION
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D004D),
                      ),
                    ),

                    const SizedBox(height: 5),

                    if (group.department.isNotEmpty)
                    Text(
                        group.department,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E3FC1),
                        ),
                      ),

                    const SizedBox(height: 7),

                    Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Color(0xFF6B1FA2),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ARROW
              // ==================================================

              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7EAF9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: Color(0xFF6B1FA2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF7EAF9),
      child: const Icon(
        Icons.groups,
        size: 38,
        color: Color(0xFF6B1FA2),
      ),
    );
  }
}