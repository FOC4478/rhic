import 'package:flutter/material.dart';

import '../../../models/sermon_model.dart';
import '../../../repositories/sermon_repository.dart';
import 'admin_sermon_categories_screen.dart';

class AdminSermonsScreen extends StatefulWidget {
  const AdminSermonsScreen({
    super.key,
  });

  @override
  State<AdminSermonsScreen> createState() =>
      _AdminSermonsScreenState();
}

class _AdminSermonsScreenState
    extends State<AdminSermonsScreen> {
  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: darkPurple,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(
              Icons.category_outlined,
              color: primaryColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminSermonCategoriesScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Sermon',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          _showSermonForm();
        },
      ),

      body: StreamBuilder<List<SermonModel>>(
        stream: _adminSermonsStream(),
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
            return _buildError(
              snapshot.error.toString(),
            );
          }

          final sermons =
              snapshot.data ?? [];

          final filtered =
              _filterSermons(sermons);

          return Column(
            children: [
              _buildTopBar(
                total: sermons.length,
              ),

              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty(
                        sermons.isEmpty,
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            10,
                            16,
                            100,
                          ),
                          itemCount:
                              filtered.length,
                          separatorBuilder:
                              (
                                context,
                            index,
                          ) =>
                                  const SizedBox(
                                height: 12,
                              ),
                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            return _buildSermonCard(
                              filtered[index],
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // STREAM
  // ============================================================

  Stream<List<SermonModel>>
      _adminSermonsStream() {
    return SermonRepository
        .instance
        .allSermonsStream();
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar({
    required int total,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        14,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText:
                  'Search sermons...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: primaryColor,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                          ),
                          onPressed: () {
                            _searchController
                                .clear();

                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
              filled: true,
              fillColor:
                  const Color(0xFFF7F3F8),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                '$total sermon${total == 1 ? '' : 's'}',
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const Spacer(),

              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminSermonCategoriesScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  size: 18,
                ),
                label: const Text(
                  'Manage Categories',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<SermonModel> _filterSermons(
    List<SermonModel> sermons,
  ) {
    final query =
        _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return sermons;
    }

    return sermons.where(
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
    ).toList();
  }

  // ============================================================
  // SERMON CARD
  // ============================================================

  Widget _buildSermonCard(
    SermonModel sermon,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFEDE3F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: SizedBox(
                    width: 105,
                    height: 82,
                    child: sermon.imageUrl
                            .trim()
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
                              return _imagePlaceholder();
                            },
                          )
                        : _imagePlaceholder(),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
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
                                    darkPurple,
                              ),
                            ),
                          ),

                          PopupMenuButton<String>(
                            onSelected:
                                (value) {
                              if (value ==
                                  'edit') {
                                _showSermonForm(
                                  sermon: sermon,
                                );
                              }

                              if (value ==
                                  'delete') {
                                _confirmDelete(
                                  sermon,
                                );
                              }
                            },
                            itemBuilder:
                                (context) {
                              return const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons
                                            .delete_outline,
                                        color:
                                            Colors.red,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        sermon.speaker,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: orangeColor,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      if (sermon.category
                          .trim()
                          .isNotEmpty)
                        Text(
                          sermon.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _resourceBadge(
                  Icons.play_circle_outline,
                  'Video',
                  sermon.hasVideo,
                ),

                const SizedBox(width: 7),

                _resourceBadge(
                  Icons.headphones_outlined,
                  'Audio',
                  sermon.hasAudio,
                ),

                const SizedBox(width: 7),

                _resourceBadge(
                  Icons.menu_book_outlined,
                  'Ebook',
                  sermon.hasEbook,
                ),

                const Spacer(),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sermon.isPublished
                        ? Colors.green
                            .withValues(
                            alpha: .10,
                          )
                        : Colors.orange
                            .withValues(
                            alpha: .10,
                          ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    sermon.isPublished
                        ? 'Published'
                        : 'Draft',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                      color: sermon.isPublished
                      ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Text(
                  'Published',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF777777),
                  ),
                ),

                const Spacer(),

                Switch.adaptive(
                  value: sermon.isPublished,
                  activeThumbColor: primaryColor,
                  onChanged: (value) {
                    _togglePublished(
                      sermon,
                      value,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESOURCE BADGE
  // ============================================================

  Widget _resourceBadge(
    IconData icon,
    String label,
    bool available,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFFF3EAF5)
            : const Color(0xFFF5F5F5),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: available
                ? primaryColor
                : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: available
                  ? primaryColor
                  : Colors.grey,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD / EDIT FORM
  // ============================================================

  void _showSermonForm({
    SermonModel? sermon,
  }) {
    final isEditing =
        sermon != null;

    final titleController =
        TextEditingController(
      text: sermon?.title ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: sermon?.description ?? '',
    );

    final speakerController =
        TextEditingController(
      text: sermon?.speaker ?? '',
    );

    final imageController =
        TextEditingController(
      text: sermon?.imageUrl ?? '',
    );

    final videoController =
        TextEditingController(
      text: sermon?.videoUrl ?? '',
    );

    final audioController =
        TextEditingController(
      text: sermon?.audioUrl ?? '',
    );

    final ebookController =
        TextEditingController(
      text: sermon?.ebookUrl ?? '',
    );

    final dateController =
        TextEditingController(
      text: sermon?.date ?? '',
    );

    final durationController =
        TextEditingController(
      text: sermon?.duration ?? '',
    );

    String selectedCategory =
        sermon?.category ?? 'General';

    bool isPublished =
        sermon?.isPublished ?? true;

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
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom:
                      MediaQuery.of(
                        context,
                          ).viewInsets.bottom +
                          20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEditing
                                  ? 'Edit Sermon'
                                  : 'Add Sermon',
                              style:
                                  const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    darkPurple,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                              );
                            },
                            icon:
                                const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _field(
                        controller:
                            titleController,
                        label: 'Title',
                        hint:
                            'Enter sermon title',
                      ),

                      _field(
                        controller:
                            speakerController,
                        label: 'Speaker',
                        hint:
                            'Enter speaker name',
                      ),

                      _field(
                        controller:
                            descriptionController,
                        label:
                            'Description',
                        hint:
                            'Enter sermon description',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 5),

                      StreamBuilder<
                          List<String>>(
                        stream:
                            SermonRepository
                                .instance
                                .categoriesStream(),
                        builder: (
                          context,
                          snapshot,
                        ) {
                          final categories =
                              snapshot.data ??
                                  ['All'];

                          final usable =
                              categories
                                  .where(
                                    (category) =>
                                        category !=
                                        'All',
                                  )
                                  .toList();

                          if (usable.isEmpty &&
                              !usable.contains(
                                selectedCategory,
                              )) {
                            usable.add(
                              selectedCategory
                                  .trim()
                                  .isEmpty
                                  ? 'General'
                                  : selectedCategory,
                            );
                          }

                          if (!usable.contains(
                            selectedCategory,
                          )) {
                            selectedCategory =
                                usable.isNotEmpty
                                ? usable.first
                                    : 'General';
                          }

                          return DropdownButtonFormField<
                              String>(
                            initialValue:
                                selectedCategory,
                            decoration:
                                _inputDecoration(
                              'Category',
                            ),
                            items: usable
                                .map(
                                  (
                                    category,
                                  ) {
                                    return DropdownMenuItem(
                                      value:
                                          category,
                                      child: Text(
                                        category,
                                      ),
                                    );
                                  },
                                )
                                .toList(),
                            onChanged: (
                              value,
                            ) {
                              if (value !=
                                  null) {
                                setSheetState(
                                  () {
                                    selectedCategory =
                                        value;
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),

                      _field(
                        controller:
                            imageController,
                        label:
                            'Image URL',
                        hint:
                            'https://...',
                      ),

                      _field(
                        controller:
                            videoController,
                        label:
                            'Video URL',
                        hint:
                            'YouTube or video URL',
                      ),

                      _field(
                        controller:
                            audioController,
                        label:
                            'Audio URL',
                        hint:
                            'Audio URL',
                      ),

                      _field(
                        controller:
                            ebookController,
                        label:
                            'Ebook URL',
                        hint:
                            'Ebook/PDF URL',
                      ),

                      _field(
                        controller:
                            dateController,
                        label: 'Date',
                        hint:
                            'e.g. August 28, 2026',
                      ),

                      _field(
                        controller:
                            durationController,
                        label:
                            'Duration',
                        hint:
                            'e.g. 45:30',
                      ),

                      const SizedBox(height: 8),

                      Container(
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF7F3F8,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: SwitchListTile(
                          value: isPublished,
                          activeThumbColor:
                              primaryColor,
                              title: const Text(
                            'Publish Sermon',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              color:
                                  darkPurple,
                            ),
                          ),
                          subtitle: Text(
                            isPublished
                                ? 'Users can see this sermon.'
                                : 'Save as a draft.',
                          ),
                          onChanged: (
                            value,
                          ) {
                            setSheetState(
                              () {
                                isPublished =
                                    value;
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton(
                          onPressed: () async {
                            await _saveSermon(
                              sheetContext:
                                  sheetContext,
                              existingSermon:
                                  sermon,
                              title:
                                  titleController
                                      .text,
                              description:
                                  descriptionController
                                      .text,
                              speaker:
                                  speakerController
                                      .text,
                              category:
                                  selectedCategory,
                              imageUrl:
                                  imageController
                                      .text,
                              videoUrl:
                                  videoController
                                      .text,
                              audioUrl:
                                  audioController
                                      .text,
                              ebookUrl:
                                  ebookController
                                      .text,
                              date:
                                  dateController
                                      .text,
                              duration:
                                  durationController
                                      .text,
                              isPublished:
                                  isPublished,
                            );
                          },
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primaryColor,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                          child: Text(
                            isEditing
                                ? 'Save Changes'
                                : 'Create Sermon',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w700,
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
      },
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
      speakerController.dispose();
      imageController.dispose();
      videoController.dispose();
      audioController.dispose();
      ebookController.dispose();
      dateController.dispose();
      durationController.dispose();
    });
  }

  // ============================================================
  // SAVE SERMON
  // ============================================================

  Future<void> _saveSermon({
    required BuildContext sheetContext,
    required SermonModel? existingSermon,
    required String title,
    required String description,
    required String speaker,
    required String category,
    required String imageUrl,
    required String videoUrl,
    required String audioUrl,
    required String ebookUrl,
    required String date,
    required String duration,
    required bool isPublished,
  }) async {
    if (title.trim().isEmpty) {
      _showFormError(
        sheetContext,
        'Please enter a sermon title.',
      );
      return;
    }

    if (speaker.trim().isEmpty) {
      _showFormError(
        sheetContext,
        'Please enter the speaker name.',
      );
      return;
    }

    if (category.trim().isEmpty) {
      _showFormError(
        sheetContext,
        'Please select a category.',
      );
      return;
    }

    try {
      final repository =
          SermonRepository.instance;

      if (existingSermon == null) {
        final sermon = SermonModel(
          id: '',
          title: title.trim(),
          description:
              description.trim(),
          speaker: speaker.trim(),
          category: category.trim(),
          imageUrl: imageUrl.trim(),
          videoUrl: videoUrl.trim(),
          audioUrl: audioUrl.trim(),
          ebookUrl: ebookUrl.trim(),
          date: date.trim(),
          duration: duration.trim(),
          isPublished: isPublished,
          createdAt: null,
        );

        await repository.createSermon(
          sermon,
        );
      } else {
        final updatedSermon =
            SermonModel(
          id: existingSermon.id,
          title: title.trim(),
          description:
              description.trim(),
          speaker: speaker.trim(),
          category: category.trim(),
          imageUrl: imageUrl.trim(),
          videoUrl: videoUrl.trim(),
          audioUrl: audioUrl.trim(),
          ebookUrl: ebookUrl.trim(),
          date: date.trim(),
          duration: duration.trim(),
          isPublished: isPublished,
          createdAt:
              existingSermon.createdAt,
        );

        await repository.updateSermon(
          updatedSermon,
        );
      }

      if (!sheetContext.mounted) {
        return;
      }

      Navigator.pop(sheetContext);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            existingSermon == null
                ? 'Sermon created successfully.'
                : 'Sermon updated successfully.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!sheetContext.mounted) {
        return;
      }

      _showFormError(
        sheetContext,
        'Unable to save sermon: $e',
      );
    }
  }

  // ============================================================
  // TOGGLE PUBLISHED
  // ============================================================

  Future<void> _togglePublished(
    SermonModel sermon,
    bool value,
  ) async {
    try {
      final updated =
          SermonModel(
        id: sermon.id,
        title: sermon.title,
        description:
            sermon.description,
        speaker: sermon.speaker,
        category: sermon.category,
        imageUrl: sermon.
        imageUrl,
        videoUrl: sermon.videoUrl,
        audioUrl: sermon.audioUrl,
        ebookUrl: sermon.ebookUrl,
        date: sermon.date,
        duration: sermon.duration,
        isPublished: value,
        createdAt: sermon.createdAt,
      );

      await SermonRepository
          .instance
          .updateSermon(updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Sermon published.'
                : 'Sermon moved to draft.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update sermon: $e',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete(
    SermonModel sermon,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Sermon?',
          ),
          content: Text(
            'Are you sure you want to delete "${sermon.title}"? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                try {
                  await SermonRepository
                      .instance
                      .deleteSermon(
                    sermon.id,
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sermon deleted.',
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to delete sermon: $e',
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration:
            _inputDecoration(label).copyWith(
          hintText: hint,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor:
      const Color(0xFFF7F3F8),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF3EAF5),
      child: const Center(
        child: Icon(
          Icons.video_library_outlined,
          color: primaryColor,
          size: 32,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty(
    bool noSermons,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 65,
              color: Color(0xFFD5D5D5),
            ),

            const SizedBox(height: 18),

            Text(
              noSermons
                  ? 'No sermons yet'
                  : 'No sermons found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
                color: Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              noSermons
                  ? 'Create your first sermon to make it available in the RHIC app.'
                  : 'Try a different search.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade500,
              ),
            ),

            if (noSermons) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _showSermonForm();
                },
                icon:
                    const Icon(Icons.add),
                label: const Text(
                  'Add Sermon',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryColor,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color: Color(0xFFD0D0D0),
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load sermons.',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
                color: Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 12,
                ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
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

  void _showFormError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}