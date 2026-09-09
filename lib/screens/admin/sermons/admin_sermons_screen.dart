import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/sermon_model.dart';
import '../../../repositories/sermon_repository.dart';
import '../../../services/b2_upload_service.dart';

class AdminSermonsScreen extends StatefulWidget {
  const AdminSermonsScreen({super.key});

  @override
  State<AdminSermonsScreen> createState() =>
      _AdminSermonsScreenState();
}

class _AdminSermonsScreenState
    extends State<AdminSermonsScreen> {
  final SermonRepository _sermonRepository =
      SermonRepository.instance;

  final B2UploadService _b2UploadService =
      B2UploadService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

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
  // HELPERS
  // ============================================================

  String _contentTypeForFile(
    String fileName,
  ) {
    final extension =
        fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'mp4':
        return 'video/mp4';

      case 'mov':
        return 'video/quicktime';

      case 'm4v':
        return 'video/x-m4v';

      case 'webm':
        return 'video/webm';

      case 'mp3':
        return 'audio/mpeg';

      case 'wav':
        return 'audio/wav';

      case 'm4a':
        return 'audio/mp4';

      case 'aac':
        return 'audio/aac';

      case 'ogg':
        return 'audio/ogg';

      case 'oga':
        return 'audio/ogg';

      case 'flac':
        return 'audio/flac';

      case 'pdf':
        return 'application/pdf';

      default:
        return 'application/octet-stream';
    }
  }

  String _mediaLabel(
    String mediaType,
  ) {
    switch (mediaType) {
      case 'image':
        return 'Cover Image';

      case 'video':
        return 'Video Sermon';

      case 'audio':
        return 'Audio Sermon';

      case 'ebook':
        return 'Ebook';

      default:
        return 'File';
    }
  }

  List<String> _allowedExtensions(
    String mediaType,
  ) {
    switch (mediaType) {
      case 'image':
        return [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
        ];

      case 'video':
        return [
          'mp4',
          'mov',
          'm4v',
          'webm',
        ];

      case 'audio':
        return [
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
          'oga',
          'flac',
        ];

      case 'ebook':
        return [
          'pdf',
        ];

      default:
        return [];
    }
  }

  String _fileNameFromObjectKey(
    String objectKey,
  ) {
    if (objectKey.trim().isEmpty) {
      return '';
    }

    final normalized =
        objectKey.replaceAll('\\', '/');

    final parts = normalized.split('/');

    if (parts.isEmpty) {
      return '';
    }

    return parts.last;
  }

  String _formatDate(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return '';
    }

    return value.trim();
  }

  bool _matchesSearch(
    SermonModel sermon,
  ) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final values = [
      sermon.title,
      sermon.description,
      sermon.speaker,
      sermon.category,
      sermon.date,
    ];

    return values.any(
      (value) => value
          .toLowerCase()
          .contains(_searchQuery),
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              error ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // CREATE / EDIT SERMON
  // ============================================================

  Future<void> _showSermonForm({
    SermonModel? sermon,
  }) async {
    final bool isEditing = sermon != null;

    final titleController =
        TextEditingController(
      text: sermon?.title ?? '',
    );

    final speakerController =
        TextEditingController(
      text: sermon?.speaker ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: sermon?.description ?? '',
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
        sermon?.category.trim().isNotEmpty == true
            ? sermon!.category
            : 'General';

    bool isPublished =
        sermon?.isPublished ?? true;

    // ============================================================
    // EXISTING STORAGE PATHS
    // ============================================================

    String imageStoragePath =
        sermon?.imageStoragePath ?? '';

    String videoStoragePath =
        sermon?.videoStoragePath ?? '';

    String audioStoragePath =
        sermon?.audioStoragePath ?? '';

    String ebookStoragePath =
        sermon?.ebookStoragePath ?? '';

    // ============================================================
    // LEGACY URLS
    // ============================================================

    String imageUrl =
        sermon?.imageUrl ?? '';

    String videoUrl =
        sermon?.videoUrl ?? '';

    String audioUrl =
        sermon?.audioUrl ?? '';

    String ebookUrl =
        sermon?.ebookUrl ?? '';

    // ============================================================
    // FILENAMES
    // ============================================================

    String imageFileName =
        _fileNameFromObjectKey(
      imageStoragePath,
    );

    String videoFileName =
        _fileNameFromObjectKey(
      videoStoragePath,
    );

    String audioFileName =
        _fileNameFromObjectKey(
      audioStoragePath,
    );

    String ebookFileName =
        _fileNameFromObjectKey(
      ebookStoragePath,
    );

    // ============================================================
    // UI STATE
    // ============================================================

    String imagePreviewUrl = '';

    bool isUploading = false;

    String uploadingLabel = '';

    final formKey =
        GlobalKey<FormState>();

    // ============================================================
    // LOAD EXISTING B2 IMAGE
    // ============================================================

    Future<void> loadExistingB2Image() async {
      if (imageStoragePath.trim().isEmpty) {
        return;
      }

      try {
        final url =
            await _b2UploadService.getDownloadUrl(
          objectKey: imageStoragePath,
        );

        imagePreviewUrl = url;
      } catch (_) {
        imagePreviewUrl = '';
      }
    }

    if (imageStoragePath.trim().isNotEmpty) {
      await loadExistingB2Image();
    }

    if (!mounted) return;

    // ============================================================
    // UPLOAD MEDIA
    // ============================================================

    Future<void> pickAndUpload(
      String mediaType,
    ) async {
      try {
        final extensions =
            _allowedExtensions(mediaType);

        final PlatformFile? selectedFile =
            await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: extensions,
        );

        if (selectedFile == null) {
          return;
        }

        final bytes =
            await selectedFile.readAsBytes();

        if (bytes.isEmpty) {
          throw Exception(
            'Unable to read the selected file.',
          );
        }

        final fileName =
            selectedFile.name;

        if (!mounted) return;

        setState(() {
          isUploading = true;
          uploadingLabel =
              'Uploading ${_mediaLabel(mediaType)}...';
        });

        final uploadResult =
            await _b2UploadService.uploadFile(
          bytes: bytes,
          fileName: fileName,
          contentType:
              _contentTypeForFile(fileName),
          mediaType: mediaType,
        );

        if (mediaType == 'image') {
          imageStoragePath =
              uploadResult.objectKey;

          imageUrl = '';

          imageFileName = fileName;

          try {
            imagePreviewUrl =
                await _b2UploadService
                    .getDownloadUrl(
              objectKey:
                  uploadResult.objectKey,
            );
          } catch (_) {
            imagePreviewUrl = '';
          }
        } else if (mediaType == 'video') {
          videoStoragePath =
              uploadResult.objectKey;

          videoUrl = '';

          videoFileName = fileName;
        } else if (mediaType == 'audio') {
          audioStoragePath =
              uploadResult.objectKey;

          audioUrl = '';

          audioFileName = fileName;
        } else if (mediaType == 'ebook') {
          ebookStoragePath =
              uploadResult.objectKey;

          ebookUrl = '';

          ebookFileName = fileName;
        }

        if (!mounted) return;

        setState(() {
          isUploading = false;
          uploadingLabel = '';
        });

        _showMessage(
          '${_mediaLabel(mediaType)} uploaded successfully.',
        );
      } catch (error) {
        if (!mounted) return;

        setState(() {
          isUploading = false;
          uploadingLabel = '';
        });

        _showMessage(
          'Upload failed: $error',
          error: true,
        );
      }
    }

    // ============================================================
    // MEDIA CARD
    // ============================================================

    Widget mediaUploadCard({
      required String mediaType,
      required String fileName,
      required String storagePath,
      required String legacyUrl,
    }) {
      final hasMedia =
          storagePath.trim().isNotEmpty ||
          legacyUrl.trim().isNotEmpty;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    mediaType == 'video'
                        ? Icons.video_library
                        : mediaType == 'audio'
                            ? Icons.audiotrack
                            : Icons.picture_as_pdf,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _mediaLabel(mediaType),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (hasMedia)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName.trim().isNotEmpty
                            ? fileName
                            : 'File uploaded',
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'No ${_mediaLabel(mediaType).toLowerCase()} uploaded.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUploading
                    ? null
                    : () => pickAndUpload(
                          mediaType,
                        ),
                icon: Icon(
                  hasMedia
                      ? Icons.refresh
                      : Icons.upload_file,
                ),
                label: Text(
                  hasMedia
                      ? 'Replace ${_mediaLabel(mediaType)}'
                      : 'Upload ${_mediaLabel(mediaType)}',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // COVER IMAGE CARD
    // ============================================================

    Widget imageCard() {
      final hasB2Image =
          imageStoragePath.trim().isNotEmpty;

      final hasLegacyImage =
          imageUrl.trim().isNotEmpty;

      final hasImage =
          hasB2Image || hasLegacyImage;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cover Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (hasImage)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  height: 190,
                  color: Colors.grey.shade200,
                  child: imagePreviewUrl
                          .trim()
                          .isNotEmpty
                      ? Image.network(
                          imagePreviewUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                              ),
                            );
                          },
                        )
                      : imageUrl
                              .trim()
                              .isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 55,
                    color: Colors.grey,
                  ),
                ),
              ),

            if (hasB2Image)
              Padding(
                padding:
                    const EdgeInsets.only(top: 8),
                child: Text(
                  imageFileName
                          .trim()
                          .isNotEmpty
                      ? imageFileName
                      : 'Cover image uploaded',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isUploading
                    ? null
                    : () => pickAndUpload(
                          'image',
                        ),
                icon: Icon(
                  hasImage
                      ? Icons.refresh
                      : Icons.upload_file,
                ),
                label: Text(
                  hasImage
                      ? 'Replace Cover Image'
                      : 'Upload Cover Image',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // SHOW DIALOG
    // ============================================================

    await showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            void refreshDialog() {
              if (context.mounted) {
                setDialogState(() {});
              }
            }

            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Sermon'
                    : 'Add Sermon',
              ),
              content: SizedBox(
                width: 700,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (isUploading)
                          Container(
                            width: double.infinity,
                            margin:
                                const EdgeInsets.only(
                              bottom: 16,
                            ),
                            padding:
                                const EdgeInsets.all(
                              12,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.blue
                                  .withValues(
                                alpha: 0.08,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(
                                    width: 12),
                                Expanded(
                                  child: Text(
                                    uploadingLabel,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ==================================================
                        // TITLE
                        // ==================================================

                        TextFormField(
                          controller:
                              titleController,
                          enabled: !isUploading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Sermon Title',
                            hintText:
                                'Enter sermon title',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter a sermon title.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // SPEAKER
                        // ==================================================

                        TextFormField(
                          controller:
                              speakerController,
                          enabled: !isUploading,
                          decoration:
                              const InputDecoration(
                            labelText: 'Speaker',
                            hintText:
                                'Enter speaker name',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter the speaker.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // CATEGORY
                        // ==================================================

                        StreamBuilder<
                            List<String>>(
                          stream: _sermonRepository
                              .categoriesStream(),
                          builder:
                              (
                            context,
                            snapshot,
                          ) {
                            final categories =
                                <String>{
                              'General',
                              ...?snapshot.data,
                            }.toList();

                            if (!categories
                                .contains(
                              selectedCategory,
                            )) {
                              categories.insert(
                                0,
                                selectedCategory,
                              );
                            }

                            return DropdownButtonFormField<
                                String>(
                              initialValue:
                                  selectedCategory,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Category',
                                border:
                                    OutlineInputBorder(),
                              ),
                              items: categories
                                  .map(
                                    (
                                      category,
                                    ) {
                                      return DropdownMenuItem<
                                          String>(
                                        value:
                                            category,
                                        child: Text(
                                          category,
                                        ),
                                      );
                                    },
                                  )
                                  .toList(),
                              onChanged:
                                  isUploading
                                      ? null
                                      : (
                                          value,
                                        ) {
                                          if (value ==
                                              null) {
                                            return;
                                          }

                                          selectedCategory =
                                              value;

                                          refreshDialog();
                                        },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DESCRIPTION
                        // ==================================================

                        TextFormField(
                          controller:
                              descriptionController,
                          enabled: !isUploading,
                          maxLines: 5,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Description',
                            hintText:
                                'Enter sermon description',
                            border:
                                OutlineInputBorder(),
                            alignLabelWithHint:
                                true,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DATE
                        // ==================================================

                        TextFormField(
                          controller:
                              dateController,
                          enabled: !isUploading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Date',
                            hintText:
                                'e.g. 7 September 2026',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // DURATION
                        // ==================================================

                        TextFormField(
                          controller:
                              durationController,
                          enabled: !isUploading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Duration',
                            hintText:
                                'e.g. 45:30',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Sermon Media',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Upload any of the available sermon resources independently.',
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // COVER
                        // ==================================================

                        imageCard(),

                        // ==================================================
                        // VIDEO
                        // ==================================================

                        mediaUploadCard(
                          mediaType: 'video',
                          fileName:
                              videoFileName,
                          storagePath:
                              videoStoragePath,
                          legacyUrl:
                              videoUrl,
                        ),

                        // ==================================================
                        // AUDIO
                        // ==================================================

                        mediaUploadCard(
                          mediaType: 'audio',
                          fileName:
                              audioFileName,
                          storagePath:
                              audioStoragePath,
                          legacyUrl:
                              audioUrl,
                        ),

                        // ==================================================
                        // EBOOK
                        // ==================================================

                        mediaUploadCard(
                          mediaType: 'ebook',
                          fileName:
                              ebookFileName,
                          storagePath:
                              ebookStoragePath,
                          legacyUrl:
                              ebookUrl,
                        ),

                        // ==================================================
                        // PUBLISH
                        // ==================================================

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.grey
                                .shade50,
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            border: Border.all(
                              color: Colors
                                  .grey.shade300,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Published',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              isPublished
                                  ? 'This sermon is visible to members.'
                                  : 'This sermon is hidden from members.',
                            ),
                            value: isPublished,
                            onChanged:
                                isUploading
                                    ? null
                                    : (
                                        value,
                                      ) {
                                        isPublished =
                                            value;
                                        refreshDialog();
                                      },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (!formKey
                              .currentState!
                              .validate()) {
                            return;
                          }

                          // Cover image is required.
                          if (imageStoragePath
                              .trim()
                              .isEmpty &&
                              imageUrl
                                  .trim()
                                  .isEmpty) {
                            _showMessage(
                              'Please upload a cover image.',
                              error: true,
                            );
                            return;
                          }

                          try {
                            if (context
                                .mounted) {
                              setDialogState(
                                () {
                                  isUploading =
                                      true;
                                  uploadingLabel =
                                      'Saving sermon...';
                                },
                              );
                            }

                            final model =
                                SermonModel(
                              id: sermon?.id ??
                                  '',
                              title:
                                  titleController
                                      .text
                                      .trim(),
                              description:
                                  descriptionController
                                      .text
                                      .trim(),
                              speaker:
                                  speakerController
                                      .text
                                      .trim(),
                              category:
                                  selectedCategory
                                      .trim()
                                      .isEmpty
                                      ? 'General'
                                      : selectedCategory
                                          .trim(),
                              imageStoragePath:
                                  imageStoragePath,
                              videoStoragePath:
                                  videoStoragePath,
                              audioStoragePath:
                                  audioStoragePath,
                              ebookStoragePath:
                                  ebookStoragePath,
                              imageUrl:
                                  imageUrl,
                              videoUrl:
                                  videoUrl,
                              audioUrl:
                                  audioUrl,
                              ebookUrl:
                                  ebookUrl,
                              date:
                                  dateController
                                      .text
                                      .trim(),
                              duration:
                                  durationController
                                      .text
                                      .trim(),
                              isPublished:
                                  isPublished,
                              createdAt:
                                  sermon?.createdAt,
                            );

                            if (isEditing) {
                              await _sermonRepository
                                  .updateSermon(
                                model,
                              );
                            } else {
                              await _sermonRepository
                                  .createSermon(
                                model,
                              );
                            }

                            if (!context
                                .mounted) {
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            _showMessage(
                              isEditing
                                  ? 'Sermon updated successfully.'
                                  : 'Sermon created successfully.',
                            );
                          } catch (error) {
                            if (context
                                .mounted) {
                              setDialogState(
                                () {
                                  isUploading =
                                      false;
                                  uploadingLabel =
                                      '';
                                },
                              );
                            }

                            _showMessage(
                              'Unable to save sermon: $error',
                              error: true,
                            );
                          }
                        },
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: Text(
                    isEditing
                        ? 'Update Sermon'
                        : 'Save Sermon',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // ============================================================
    // DISPOSE FORM CONTROLLERS
    // ============================================================

    titleController.dispose();
    speakerController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    durationController.dispose();
  }

  // ============================================================
  // DELETE SERMON
  // ============================================================

  Future<void> _deleteSermon(
    SermonModel sermon,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Sermon'),
          content: Text(
            'Are you sure you want to delete "${sermon.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _sermonRepository
          .deleteSermon(
        sermon.id,
      );

      _showMessage(
        'Sermon deleted successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to delete sermon: $error',
        error: true,
      );
    }
  }

  // ============================================================
  // TOGGLE PUBLISHED
  // ============================================================

  Future<void> _togglePublished(
    SermonModel sermon,
  ) async {
    try {
      await _sermonRepository
          .setPublished(
        sermonId: sermon.id,
        isPublished:
            !sermon.isPublished,
      );

      _showMessage(
        sermon.isPublished
            ? 'Sermon unpublished.'
            : 'Sermon published.',
      );
    } catch (error) {
      _showMessage(
        'Unable to change publication status: $error',
        error: true,
      );
    }
  }

  // ============================================================
  // SERMON CARD
  // ============================================================

  Widget _buildSermonCard(
    SermonModel sermon,
  ) {
    return Card(
      elevation: 1,
      margin:
          const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              height: 95,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(12),
                child: sermon
                        .imageStoragePath
                        .trim()
                        .isNotEmpty
                    ? _AdminB2Image(
                        objectKey: sermon
                            .imageStoragePath,
                      )
                    : sermon.imageUrl
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
                              return _cardImagePlaceholder();
                            },
                          )
                        : _cardImagePlaceholder(),
              ),
            ),

            const SizedBox(width: 14),

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
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      PopupMenuButton<
                          String>(
                        onSelected:
                            (value) {
                          switch (value) {
                            case 'edit':
                              _showSermonForm(
                                sermon:
                                    sermon,
                              );
                              break;

                            case 'toggle':
                              _togglePublished(
                                sermon,
                              );
                              break;

                            case 'delete':
                              _deleteSermon(
                                sermon,
                              );
                              break;
                          }
                        },
                        itemBuilder:
                            (context) => [
                          const PopupMenuItem<
                              String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                ),
                                SizedBox(
                                    width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<
                              String>(
                            value:
                                'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  sermon
                                          .isPublished
                                      ? Icons
                                          .visibility_off
                                      : Icons
                                          .visibility,
                                  size: 20,
                                ),
                                const SizedBox(
                                    width: 10),
                                Text(
                                  sermon
                                          .isPublished
                                      ? 'Unpublish'
                                      : 'Publish',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<
                              String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color:
                                      Colors.red,
                                  size: 20,
                                ),
                                SizedBox(
                                    width: 10),
                                Text(
                                  'Delete',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    sermon.speaker,
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if (sermon.category
                          .trim()
                          .isNotEmpty)
                        _infoChip(
                          sermon.category,
                          Icons.category,
                        ),

                      if (sermon.date
                          .trim()
                          .isNotEmpty)
                        _infoChip(
                          _formatDate(
                            sermon.date,
                          ),
                          Icons.calendar_today,
                        ),

                      if (sermon.duration
                          .trim()
                          .isNotEmpty)
                        _infoChip(
                          sermon.duration,
                          Icons.timer,
                        ),

                      if (sermon.hasVideo)
                        _infoChip(
                          'Video',
                          Icons.video_library,
                        ),

                      if (sermon.hasAudio)
                        _infoChip(
                          'Audio',
                          Icons.audiotrack,
                        ),

                      if (sermon.hasEbook)
                        _infoChip(
                          'Ebook',
                          Icons.picture_as_pdf,
                        ),

                      _infoChip(
                        sermon.isPublished
                            ? 'Published'
                            : 'Draft',
                        sermon.isPublished
                            ? Icons.check_circle
                            : Icons
                                .visibility_off,
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

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget _cardImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 38,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _infoChip(
    String text,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color:
                  Colors.grey.shade700,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Manage Sermons'),
        actions: [
          IconButton(
            tooltip: 'Add Sermon',
            onPressed: () =>
                _showSermonForm(),
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () =>
            _showSermonForm(),
        icon: const Icon(
          Icons.add,
        ),
        label:
            const Text('Add Sermon'),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            // ======================================================
            // SEARCH
            // ======================================================

            TextField(
              controller:
                  _searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search sermons...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();
                            },
                            icon:
                                const Icon(
                              Icons.clear,
                            ),
                          )
                        : null,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ======================================================
            // SERMON LIST
            // ======================================================

            Expanded(
              child: StreamBuilder<
                  List<SermonModel>>(
                stream: _sermonRepository
                    .allSermonsStream(),
                builder:
                    (
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
                            const EdgeInsets.all(
                          24,
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.red,
                            ),
                            const SizedBox(
                                height: 12),
                            const Text(
                              'Unable to load sermons.',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            const SizedBox(
                                height: 8),
                            Text(
                              snapshot.error
                                  .toString(),
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color: Colors
                                    .grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final sermons =
                      snapshot.data ?? [];

                  final filteredSermons =
                      sermons
                          .where(
                            _matchesSearch,
                          )
                          .toList();

                  if (sermons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .library_music_outlined,
                            size: 65,
                            color: Colors
                                .grey.shade400,
                          ),
                          const SizedBox(
                              height: 14),
                          const Text(
                            'No sermons yet',
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                              height: 7),
                          Text(
                            'Create your first sermon to get started.',
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                            ),
                          ),
                          const SizedBox(
                              height: 18),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showSermonForm(),
                            icon:
                                const Icon(
                              Icons.add,
                            ),
                            label:
                                const Text(
                              'Add Sermon',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredSermons
                      .isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 55,
                          ),
                          const SizedBox(
                              height: 12),
                          const Text(
                            'No matching sermons.',
                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(
                              height: 8),
                          Text(
                            'Try a different search term.',
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount:
                        filteredSermons.length,
                    itemBuilder:
                        (context, index) {
                      final sermon =
                          filteredSermons[
                              index];

                      return _buildSermonCard(
                        sermon,
                      );
                    },
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

// ============================================================================
// ADMIN B2 IMAGE
// ============================================================================

class _AdminB2Image extends StatefulWidget {
  final String objectKey;

  const _AdminB2Image({
    required this.objectKey,
  });

  @override
  State<_AdminB2Image> createState() =>
      _AdminB2ImageState();
}

class _AdminB2ImageState
    extends State<_AdminB2Image> {
  String? _url;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final url =
          await B2UploadService.instance
              .getDownloadUrl(
        objectKey:
            widget.objectKey,
      );

      if (!mounted) return;

      setState(() {
        _url = url;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_error != null) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 35,
          ),
        ),
      );
    }

    if (_url == null ||
        _url!.trim().isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Image.network(
      _url!,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 35,
            ),
          ),
        );
      },
    );
  }
}