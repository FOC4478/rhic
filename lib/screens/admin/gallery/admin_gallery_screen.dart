import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../repositories/content_repository.dart';
import '../../../services/b2_upload_service.dart';
import '../../../services/media_url_service.dart';
import '../../../models/gallery_model.dart';

class AdminGalleryScreen extends StatefulWidget {
  const AdminGalleryScreen({
    super.key,
  });

  @override
  State<AdminGalleryScreen> createState() =>
      _AdminGalleryScreenState();
}

class _AdminGalleryScreenState
    extends State<AdminGalleryScreen> {
  final ContentRepository _repository =
      ContentRepository.instance;

  String _searchQuery = '';

  Future<void> _openGalleryForm({
    GalleryItem? item,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => _GalleryFormDialog(
        item: item,
      ),
    );
  }

  Future<void> _deleteGalleryItem(
    GalleryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Gallery Item',
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteGalleryItem(
        item.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gallery item deleted successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _togglePublished(
    GalleryItem item,
  ) async {
    try {
      await _repository.setGalleryPublished(
        galleryId: item.id,
        isPublished: !item.isPublished,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.isPublished
                ? 'Gallery item unpublished.'
                : 'Gallery item published.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F5F8),
      child: SafeArea(
        child: Column(
          children: [
            // ============================================================
            // MENU ICON
            // ============================================================

            Container(
              width: double.infinity,
              height: 56,
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (menuContext) {
                  return IconButton(
                    tooltip: 'Menu',
                    onPressed: () {
                      Scaffold.maybeOf(
                        menuContext,
                      )?.openDrawer();
                    },
                    icon: const Icon(
                      Icons.menu,
                      color: Color(0xFF3D004D),
                    ),
                  );
                },
              ),
            ),

            // ============================================================
            // GALLERY CONTENT
            // ============================================================

            Expanded(
              child: StreamBuilder<List<GalleryItem>>(
                stream:
                    _repository.adminGalleryStream(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load gallery.\n\n${snapshot.error}',
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final items =
                      snapshot.data ?? [];

                  final filtered =
                      items.where((item) {
                    final query =
                        _searchQuery
                            .trim()
                            .toLowerCase();

                    if (query.isEmpty) {
                      return true;
                    }

                    return item.title
                            .toLowerCase()
                            .contains(query) ||
                        item.description
                            .toLowerCase()
                            .contains(query);
                  }).toList();

                  return Column(
                    children: [
                      // ====================================================
                      // HEADER
                      // ====================================================

                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          18,
                          20,
                          12,
                        ),
                        child: LayoutBuilder(
                          builder: (
                            context,
                            constraints,
                          ) {
                            final isMobile =
                                constraints.maxWidth <
                                    650;

                            if (isMobile) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text(
                                    'Gallery',
                                    style:
                                        TextStyle(
                                      fontSize: 26,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      color:
                                          Color(
                                        0xFF3D004D,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  const Text(
                                    'Manage gallery images visible to members.',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 14,
                                  ),
                                  SizedBox(
                                    width:
                                        double.infinity,
                                    child:
                                        FilledButton
                                            .icon(
                                      onPressed: () =>
                                          _openGalleryForm(),
                                      icon:
                                          const Icon(
                                        Icons
                                            .add_photo_alternate_outlined,
                                      ),
                                      label:
                                          const Text(
                                        'Add Image',
                                      ),
                                      style:
                                          FilledButton
                                              .styleFrom(
                                        backgroundColor:
                                            const Color(
                                          0xFF6B1FA2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .center,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        'Gallery',
                                        style:
                                            TextStyle(
                                          fontSize: 28,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                          color:
                                              Color(
                                            0xFF3D004D,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        'Manage gallery images visible to members.',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openGalleryForm(),
                                  icon:
                                      const Icon(
                                    Icons
                                        .add_photo_alternate_outlined,
                                  ),
                                  label:
                                      const Text(
                                    'Add Image',
                                  ),
                                  style:
                                      FilledButton
                                          .styleFrom(
                                    backgroundColor:
                                        const Color(
                                      0xFF6B1FA2,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // ====================================================
                      // SEARCH
                      // ====================================================

                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          20,
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration:
                              InputDecoration(
                            hintText:
                                'Search gallery...',
                            prefixIcon:
                                const Icon(
                              Icons.search,
                            ),
                            filled: true,
                            fillColor:
                                Colors.white,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      // ====================================================
                      // GALLERY GRID
                      // ====================================================

                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No gallery images found.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (
                                  context,
                                  constraints,
                                ) {
                                  int columns = 1;

                                  if (constraints
                                          .maxWidth >=
                                      1200) {
                                    columns = 4;
                                  } else if (constraints
                                          .maxWidth >=
                                      850) {
                                    columns = 3;
                                  } else if (constraints
                                          .maxWidth >=
                                      550) {
                                    columns = 2;
                                  }

                                  return GridView.builder(
                                    padding:
                                        const EdgeInsets
                                            .fromLTRB(
                                      20,
                                      0,
                                      20,
                                      20,
                                    ),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          columns,
                                      crossAxisSpacing:
                                          16,
                                      mainAxisSpacing:
                                          16,
                                      mainAxisExtent:
                                          columns == 1
                                              ? 430
                                              : columns == 2
                                                  ? 390
                                                  : 400,
                                    ),
                                    itemCount:
                                        filtered.length,
                                    itemBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      final item =
                                          filtered[
                                              index];

                                      return _AdminGalleryCard(
                                        item: item,
                                        onEdit: () =>
                                            _openGalleryForm(
                                          item: item,
                                        ),
                                        onDelete: () =>
                                            _deleteGalleryItem(
                                          item,
                                        ),
                                        onTogglePublished:
                                            () =>
                                                _togglePublished(
                                          item,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN GALLERY CARD
// ============================================================

class _AdminGalleryCard
    extends StatelessWidget {
  final GalleryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublished;

  const _AdminGalleryCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _GalleryImage(
              objectKey:
                  item.imageObjectKey,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title.isEmpty
                      ? 'Untitled'
                      : item.title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF3D004D),
                  ),
                ),
                if (item.description
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: item.isPublished
                            ? Colors
                                .green
                                .withValues(
                                alpha: 0.1,
                              )
                            : Colors
                                .orange
                                .withValues(
                                alpha: 0.1,
                              ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        item.isPublished
                            ? 'Published'
                            : 'Unpublished',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w700,
                          color: item
                                  .isPublished
                              ? Colors
                                  .green
                              : Colors
                                  .orange,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected:
                          (value) {
                        if (value ==
                            'edit') {
                          onEdit();
                        } else if (value ==
                            'publish') {
                          onTogglePublished();
                        } else if (value ==
                            'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder:
                          (context) {
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading:
                                  Icon(
                                Icons
                                    .edit_outlined,
                              ),
                              title:
                                  Text(
                                'Edit',
                              ),
                              contentPadding:
                                  EdgeInsets
                                      .zero,
                            ),
                          ),
                          PopupMenuItem(
                            value:
                                'publish',
                            child: ListTile(
                              leading:
                                  Icon(
                                item.isPublished
                                    ? Icons
                                        .visibility_off_outlined
                                    : Icons
                                        .visibility_outlined,
                              ),
                              title:
                                  Text(
                                item.isPublished
                                    ? 'Unpublish'
                                    : 'Publish',
                              ),
                              contentPadding:
                                  EdgeInsets
                                      .zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading:
                                  Icon(
                                Icons
                                    .delete_outline,
                                color:
                                    Colors.red,
                              ),
                              title:
                                  Text(
                                'Delete',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.red,
                                ),
                              ),
                              contentPadding:
                                  EdgeInsets
                                      .zero,
                            ),
                          ),
                        ];
                      },
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
}

// ============================================================
// GALLERY IMAGE
// ============================================================

class _GalleryImage
    extends StatefulWidget {
  final String objectKey;

  const _GalleryImage({
    required this.objectKey,
  });

  @override
  State<_GalleryImage> createState() =>
      _GalleryImageState();
}

class _GalleryImageState
    extends State<_GalleryImage> {
  String? _imageUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(
    covariant _GalleryImage oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.objectKey !=
        widget.objectKey) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.objectKey
        .trim()
        .isEmpty) {
      if (!mounted) return;

      setState(() {
        _error =
            'Image not configured.';
      });

      return;
    }

    try {
      final url =
          await MediaUrlService
              .instance
              .getGalleryDownloadUrl(
        storagePath:
            widget.objectKey,
      );

      if (!mounted) return;

      setState(() {
        _imageUrl = url;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl == null &&
        _error == null) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Container(
        color:
            const Color(0xFFF0EDF2),
        child: const Center(
          child: Icon(
            Icons
                .broken_image_outlined,
            color: Colors.grey,
            size: 40,
          ),
        ),
      );
    }

    return Image.network(
      _imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color:
              const Color(0xFFF0EDF2),
          child: const Center(
            child: Icon(
              Icons
                  .broken_image_outlined,
              color: Colors.grey,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// GALLERY FORM DIALOG
// ============================================================

class _GalleryFormDialog
    extends StatefulWidget {
  final GalleryItem? item;

  const _GalleryFormDialog({
    this.item,
  });

  @override
  State<_GalleryFormDialog> createState() =>
      _GalleryFormDialogState();
}

class _GalleryFormDialogState
    extends State<_GalleryFormDialog> {
  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _titleController;

  late final TextEditingController
      _descriptionController;

  Uint8List? _imageBytes;
  String? _fileName;
  String? _imageObjectKey;

  bool _isPublished = true;
  bool _isSaving = false;

  bool get _isEditing =>
      widget.item != null;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
      text: widget.item?.title ?? '',
    );

    _descriptionController =
        TextEditingController(
      text:
          widget.item?.description ?? '',
    );

    _imageObjectKey =
        widget.item?.imageObjectKey;

    _isPublished =
        widget.item?.isPublished ??
            true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result =
          await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );

      if (result.isEmpty) {
        return;
      }

      final file = result.first;

      final bytes =
          await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read the selected image.',
        );
      }

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _fileName = file.name;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(error.toString()),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  String _imageContentType(
    String fileName,
  ) {
    final extension =
        fileName
            .split('.')
            .last
            .toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      default:
        throw Exception(
          'Unsupported image format.',
        );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_imageBytes == null &&
        (_imageObjectKey == null ||
            _imageObjectKey!
                .trim()
                .isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a gallery image.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String objectKey =
          _imageObjectKey ?? '';

      // ------------------------------------------------------
      // UPLOAD NEW IMAGE
      // ------------------------------------------------------

      if (_imageBytes != null) {
        final uploadResult =
            await B2UploadService
                .instance
                .uploadFile(
          bytes: _imageBytes!,
          fileName:
              _fileName ?? 'gallery.jpg',
          contentType:
              _imageContentType(
            _fileName ?? 'gallery.jpg',
          ),
          mediaType: 'image',
          resourceType: 'gallery',
        );

        objectKey =
            uploadResult.objectKey;
      }

      final user =
          FirebaseAuth
              .instance
              .currentUser;

      if (user == null) {
        throw Exception(
          'You must be signed in as an administrator.',
        );
      }

      if (_isEditing) {
        await ContentRepository
            .instance
            .updateGalleryItem(
          galleryId:
              widget.item!.id,
          title:
              _titleController.text,
          description:
              _descriptionController.text,
          imageObjectKey:
              objectKey,
          createdBy:
              user.uid,
          isPublished:
              _isPublished,
        );
      } else {
        await ContentRepository
            .instance
            .createGalleryItem(
          title:
              _titleController.text,
          description:
              _descriptionController
                  .text,
          imageObjectKey:
              objectKey,
          createdBy:
              user.uid,
          isPublished:
              _isPublished,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Gallery item updated successfully.'
                : 'Gallery image uploaded successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(error.toString()),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize =
        MediaQuery.sizeOf(context);

    final dialogWidth =
        screenSize.width < 700
            ? screenSize.width - 32
            : 560.0;

    final imageHeight =
        screenSize.height < 800
            ? 180.0
            : 220.0;

    return AlertDialog(
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      title: Text(
        _isEditing
            ? 'Edit Gallery Image'
            : 'Add Gallery Image',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF3D004D),
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight:
              screenSize.height * 0.68,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller:
                      _titleController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Title',
                    border:
                        OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Enter a title.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Description',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                    child: Image.memory(
                      _imageBytes!,
                      height: imageHeight,
                      width:
                          double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (_imageObjectKey !=
                        null &&
                    _imageObjectKey!
                        .trim()
                        .isNotEmpty)
                  SizedBox(
                    height: imageHeight,
                    width:
                        double.infinity,
                    child:
                        _GalleryImage(
                      objectKey:
                          _imageObjectKey!,
                    ),
                  )
                else
                  Container(
                    height:
                        imageHeight,
                    width:
                        double.infinity,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFF0EDF2,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child:
                        const Center(
                      child: Icon(
                        Icons
                            .add_photo_alternate_outlined,
                        size: 50,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  child: OutlinedButton
                      .icon(
                    onPressed:
                        _isSaving
                            ? null
                            : _pickImage,
                    icon: const Icon(
                      Icons
                          .photo_library_outlined,
                    ),
                    label: Text(
                      _imageBytes !=
                              null
                          ? 'Change Image'
                          : _isEditing
                              ? 'Replace Image'
                              : 'Select Image',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                SwitchListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  title: const Text(
                    'Published',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle:
                      const Text(
                    'Published images are visible to members.',
                  ),
                  value:
                      _isPublished,
                  activeThumbColor:
                      const Color(
                    0xFF6B1FA2,
                  ),
                  onChanged:
                      _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _isPublished =
                                    value;
                              });
                            },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () =>
                  Navigator.pop(
                context,
              ),
          child:
              const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _isSaving ? null : _save,
          style:
              FilledButton.styleFrom(
            backgroundColor:
                const Color(
              0xFF6B1FA2,
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditing
                      ? 'Save Changes'
                      : 'Upload Image',
                ),
        ),
      ],
    );
  }
}