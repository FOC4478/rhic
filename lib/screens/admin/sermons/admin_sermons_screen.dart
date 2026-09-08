import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/sermon_model.dart';
import '../../../repositories/sermon_repository.dart';
import '../../../services/b2_upload_service.dart';

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

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _contentTypeForFile(
    String fileName,
  ) {
    final extension =
        fileName.split('.').last.toLowerCase();

    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      // Video
      case 'mp4':
        return 'video/mp4';

      case 'webm':
        return 'video/webm';

      case 'mov':
        return 'video/quicktime';

      // Audio
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

      default:
        return 'application/octet-stream';
    }
  }

  String _mediaLabel(
    String mediaType,
  ) {
    switch (mediaType) {
      case 'image':
        return 'cover image';

      case 'video':
        return 'video';

      case 'audio':
        return 'audio';

      case 'ebook':
        return 'eBook';

      default:
        return 'file';
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
        ];

      case 'video':
        return [
          'mp4',
          'webm',
          'mov',
        ];

      case 'audio':
        return [
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
        ];

      case 'ebook':
        return [
          'pdf',
        ];

      default:
        return [];
    }
  }

  String _formatDate(
    SermonModel sermon,
  ) {
    if (sermon.date.trim().isNotEmpty) {
      return sermon.date.trim();
    }

    if (sermon.createdAt != null) {
      final date =
          sermon.createdAt!.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return 'No date';
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

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

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? Colors.red.shade700 : null,
      ),
    );
  }

  // ==========================================================
  // CREATE / EDIT SERMON
  // ==========================================================

  Future<void> _showSermonForm({
    SermonModel? sermon,
  }) async {
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

    final categoryController =
        TextEditingController(
      text: sermon?.category ?? '',
    );

    final dateController =
        TextEditingController(
      text: sermon?.date ?? '',
    );

    final durationController =
        TextEditingController(
      text: sermon?.duration ?? '',
    );

    // --------------------------------------------------------
    // B2 STORAGE PATHS
    // --------------------------------------------------------

    String imageStoragePath =
        sermon?.imageStoragePath ?? '';

    String videoStoragePath =
        sermon?.videoStoragePath ?? '';

    String audioStoragePath =
        sermon?.audioStoragePath ?? '';

    String ebookStoragePath =
        sermon?.ebookStoragePath ?? '';

    // --------------------------------------------------------
    // LEGACY URLS
    // --------------------------------------------------------

    String imageUrl =
        sermon?.imageUrl ?? '';

    String videoUrl =
        sermon?.videoUrl ?? '';

    String audioUrl =
        sermon?.audioUrl ?? '';

    String ebookUrl =
        sermon?.ebookUrl ?? '';

    // --------------------------------------------------------
    // FILE NAMES
    // --------------------------------------------------------

    String imageFileName = '';

    String videoFileName = '';

    String audioFileName = '';

    String ebookFileName = '';

    bool isPublished =
        sermon?.isPublished ?? true;

    bool isUploading = false;

    String uploadingLabel = '';

    final formKey =
        GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            // ==================================================
            // UPLOAD FUNCTION
            // ==================================================

            Future<void> pickAndUpload(
              String mediaType,
            ) async {
              try {
                final extensions =
                    _allowedExtensions(
                  mediaType,
                );

                final file =
                    await FilePicker.pickFile(
                  type: FileType.custom,
                  allowedExtensions:
                      extensions,
                );

                if (file == null) {
                  return;
                }

                final bytes =
                    await file.readAsBytes();

                if (bytes.isEmpty) {
                  throw Exception(
                    'The selected file is empty.',
                  );
                }

                final fileName =
                    file.name;

                String contentType;

                if (mediaType == 'ebook') {
                  contentType =
                      'application/pdf';
                } else {
                  contentType =
                      _contentTypeForFile(
                    fileName,
                  );
                }

                setDialogState(() {
                  isUploading = true;
                  uploadingLabel =
                      'Uploading ${_mediaLabel(mediaType)}...';
                });

                final result =
                    await _b2UploadService
                        .uploadFile(
                  bytes: bytes,
                  fileName: fileName,
                  contentType:
                      contentType,
                  mediaType:
                      mediaType,
                );

                if (mediaType == 'image') {
                  imageStoragePath =
                      result.objectKey;

                  // New B2 media does not use
                  // a permanent URL.
                  imageUrl = '';

                  imageFileName =
                      fileName;
                }

                if (mediaType == 'video') {
                  videoStoragePath =
                      result.objectKey;

                  videoUrl = '';

                  videoFileName =
                      fileName;
                }

                if (mediaType == 'audio') {
                  audioStoragePath =
                      result.objectKey;

                  audioUrl = '';

                  audioFileName =
                      fileName;
                }

                if (mediaType == 'ebook') {
                  ebookStoragePath =
                      result.objectKey;

                  ebookUrl = '';

                  ebookFileName =
                      fileName;
                }

                setDialogState(() {
                  isUploading = false;
                  uploadingLabel = '';
                });

                _showMessage(
                  '${_mediaLabel(mediaType)} uploaded successfully.',
                );
              } catch (error) {
                setDialogState(() {
                  isUploading = false;
                  uploadingLabel = '';
                });

                _showMessage(
                  'Upload failed: $error',
                  error: true,
                );
              }
            }

            // ==================================================
            // MEDIA CARD
            // ==================================================

            Widget mediaUploadCard({
              required String title,
              required String mediaType,
              required String storagePath,
              required String legacyUrl,
              required String fileName,
              required IconData icon,
              required VoidCallback onUpload,
              required VoidCallback onRemove,
            }) {
              final hasStorage =
                  storagePath
                      .trim()
                      .isNotEmpty;

              final hasLegacyUrl =
                  legacyUrl
                      .trim()
                      .isNotEmpty;

              final hasFile =
                  hasStorage ||
                  hasLegacyUrl;

              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: Colors.grey
                        .withValues(alpha: .25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration:
                              BoxDecoration(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .primary
                                .withValues(alpha: 
                                  0.10,
                                ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color:
                                Theme.of(
                              context,
                            )
                                    .colorScheme
                                    .primary,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                title,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                hasFile
                                    ? (fileName
                                            .trim()
                                            .isNotEmpty
                                        ? fileName
                                        : 'Existing media')
                                    : 'No file selected',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasFile)
                          IconButton(
                            tooltip:
                                'Remove',
                            onPressed:
                                isUploading
                                    ? null
                                    : onRemove,
                            icon:
                                const Icon(
                              Icons
                                  .delete_outline,
                              color:
                                  Colors.red,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            isUploading
                                ? null
                                : onUpload,
                        icon:
                            const Icon(
                          Icons
                              .cloud_upload_outlined,
                        ),
                        label: Text(
                          hasFile
                              ? 'Replace'
                              : 'Upload',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ==================================================
            // IMAGE PREVIEW
            // ==================================================

            Widget imageCard() {
              final hasB2Image =
                  imageStoragePath
                      .trim()
                      .isNotEmpty;

              final hasLegacyImage =
                  imageUrl
                      .trim()
                      .isNotEmpty;

              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color: Colors.grey
                        .withValues(alpha: .25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cover Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    if (hasLegacyImage)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child:
                              Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                color: Colors
                                    .grey
                                    .shade200,
                                alignment:
                                    Alignment
                                        .center,
                                child:
                                    const Icon(
                                  Icons
                                      .broken_image_outlined,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else if (hasB2Image)
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .green
                              .withValues(alpha: 
                            0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .cloud_done_outlined,
                              color:
                                  Colors.green,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                imageFileName
                                        .trim()
                                        .isNotEmpty
                                    ? imageFileName
                                    : 'Cover image uploaded to B2',
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width:
                            double.infinity,
                        height: 160,
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .grey
                              .shade100,
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
                                .image_outlined,
                            size: 48,
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 12,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            isUploading
                                ? null
                                : () =>
                                    pickAndUpload(
                                      'image',
                                    ),
                        icon:
                            const Icon(
                          Icons
                              .cloud_upload_outlined,
                        ),
                        label: Text(
                          hasB2Image ||
                                  hasLegacyImage
                              ? 'Replace Cover Image'
                              : 'Upload Cover Image',
                        ),
                      ),
                    ),
                    if (hasB2Image)
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 8,
                        ),
                        child: Text(
                          imageStoragePath,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: Text(
                sermon == null
                    ? 'Add Sermon'
                    : 'Edit Sermon',
              ),
              content: SizedBox(
                width: 650,
                child:
                    SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        // ========================================
                        // TITLE
                        // ========================================

                        TextFormField(
                          controller:
                              titleController,
                          enabled:
                              !isUploading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Sermon title',
                            hintText:
                                'Enter sermon title',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Enter a sermon title.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ========================================
                        // SPEAKER
                        // ========================================

                        TextFormField(
                          controller:
                              speakerController,
                          enabled:
                              !isUploading,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Speaker',
                            hintText:
                                'Enter speaker name',
                            border:
                                OutlineInputBorder(),
                          ),
                          validator:
                              (value) {
                            if (value ==
                                    null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Enter the speaker.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ========================================
                        // CATEGORY
                        // ========================================

                        StreamBuilder<
                            List<String>>(
                          stream:
                              _sermonRepository
                                  .categoriesStream(),
                          builder: (
                            context,
                            snapshot,
                          ) {
                            final categories =
                                snapshot.data ??
                                    [];

                            final categoryNames =
                                categories
                                    .where(
                                      (category) =>
                                          category
                                              .trim()
                                              .isNotEmpty,
                                    )
                                    .toList();

                            return DropdownButtonFormField<String>(
                                 initialValue: 
                                  categoryController
                                          .text
                                          .trim()
                                          .isNotEmpty &&
                                      categoryNames
                                          .contains(
                                        categoryController
                                            .text
                                            .trim(),
                                      )
                                      ? categoryController
                                          .text
                                          .trim()
                                      : null,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Category',
                                border:
                                    OutlineInputBorder(),
                              ),
                              items:
                                  categoryNames
                                      .map(
                                        (
                                          category,
                                        ) {
                                          return DropdownMenuItem<
                                              String>(
                                            value:
                                                category,
                                            child:
                                                Text(
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

                                          setDialogState(
                                            () {
                                              categoryController
                                                      .text =
                                                  value;
                                            },
                                          );
                                        },
                              validator:
                                  (value) {
                                if (value ==
                                        null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'Select a category.';
                                }

                                return null;
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ========================================
                        // DESCRIPTION
                        // ========================================

                        TextFormField(
                          controller:
                              descriptionController,
                          enabled:
                              !isUploading,
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

                        const SizedBox(
                          height: 14,
                        ),

                        // ========================================
                        // DATE + DURATION
                        // ========================================

                        Row(
                          children: [
                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    dateController,
                                enabled:
                                    !isUploading,
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
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    durationController,
                                enabled:
                                    !isUploading,
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
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ========================================
                        // COVER IMAGE
                        // ========================================

                        imageCard(),

                        // ========================================
                        // VIDEO
                        // ========================================

                        mediaUploadCard(
                          title: 'Sermon Video',
                          mediaType:
                              'video',
                          storagePath:
                              videoStoragePath,
                          legacyUrl:
                              videoUrl,
                          fileName:
                              videoFileName,
                          icon: Icons
                              .video_library_outlined,
                          onUpload:
                              () =>
                                  pickAndUpload(
                                'video',
                              ),
                          onRemove:
                              () {
                            setDialogState(
                              () {
                                videoStoragePath =
                                    '';
                                videoUrl =
                                    '';
                                videoFileName =
                                    '';
                              },
                            );
                          },
                        ),

                        // ========================================
                        // AUDIO
                        // ========================================

                        mediaUploadCard(
                          title: 'Sermon Audio',
                          mediaType:
                              'audio',
                          storagePath:
                              audioStoragePath,
                          legacyUrl:
                              audioUrl,
                          fileName:
                              audioFileName,
                          icon: Icons
                              .audio_file_outlined,
                          onUpload:
                              () =>
                                  pickAndUpload(
                                'audio',
                              ),
                          onRemove:
                              () {
                            setDialogState(
                              () {
                                audioStoragePath =
                                    '';
                                audioUrl =
                                    '';
                                audioFileName =
                                    '';
                              },
                            );
                          },
                        ),

                        // ========================================
                        // EBOOK
                        // ========================================

                        mediaUploadCard(
                          title:
                              'Sermon eBook',
                          mediaType:
                              'ebook',
                          storagePath:
                              ebookStoragePath,
                          legacyUrl:
                              ebookUrl,
                          fileName:
                              ebookFileName,
                          icon: Icons
                              .picture_as_pdf_outlined,
                          onUpload:
                              () =>
                                  pickAndUpload(
                                'ebook',
                              ),
                          onRemove:
                              () {
                            setDialogState(
                              () {
                                ebookStoragePath =
                                    '';
                                ebookUrl =
                                    '';
                                ebookFileName =
                                    '';
                              },
                            );
                          },
                        ),

                        // ========================================
                        // PUBLISH
                        // ========================================

                        Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            top: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .grey
                                .withValues(alpha: 
                              0.08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child:
                              SwitchListTile(
                            value:
                                isPublished,
                            onChanged:
                                isUploading
                                    ? null
                                    : (
                                        value,
                                      ) {
                                        setDialogState(
                                          () {
                                            isPublished =
                                                value;
                                          },
                                        );
                                      },
                            title:
                                const Text(
                              'Published',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                            subtitle:
                                Text(
                              isPublished
                                  ? 'This sermon is visible to users.'
                                  : 'This sermon is hidden from users.',
                            ),
                          ),
                        ),

                        // ========================================
                        // UPLOADING STATUS
                        // ========================================

                        if (isUploading)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 18,
                            ),
                            child: Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .all(
                                14,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 
                                      0.08,
                                    ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child:
                                        Text(
                                      uploadingLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isUploading
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                  child:
                      const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed:
                      isUploading
                          ? null
                          : () async {
                              if (!formKey
                                  .currentState!
                                  .validate()) {
                                return;
                              }

                              // ------------------------------------------------
                              // REQUIRE COVER IMAGE
                              // ------------------------------------------------

                              if (imageStoragePath
                                      .trim()
                                      .isEmpty &&
                                  imageUrl
                                      .trim()
                                      .isEmpty) {
                                _showMessage(
                                  'Please upload a cover image.',
                                  error:
                                      true,
                                );

                                return;
                              }

                              try {
                                setDialogState(
                                  () {
                                    isUploading =
                                        true;
                                    uploadingLabel =
                                        'Saving sermon...';
                                  },
                                );

                                // ============================================
                                // CREATE
                                // ============================================

                                if (sermon ==
                                    null) {
                                  final newSermon =
                                      SermonModel(
                                    id: '',
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
                                        categoryController
                                            .text
                                            .trim(),

                                    // B2
                                    imageStoragePath:
                                        imageStoragePath
                                            .trim(),
                                    videoStoragePath:
                                        videoStoragePath
                                            .trim(),
                                    audioStoragePath:
                                        audioStoragePath
                                            .trim(),
                                    ebookStoragePath:
                                        ebookStoragePath
                                            .trim(),

                                    // Legacy
                                    imageUrl:
                                        imageUrl
                                            .trim(),
                                    videoUrl:
                                        videoUrl
                                            .trim(),
                                    audioUrl:
                                        audioUrl
                                            .trim(),
                                    ebookUrl:
                                        ebookUrl
                                            .trim(),

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
                                        null,
                                  );

                                  await _sermonRepository
                                      .createSermon(
                                    newSermon,
                                  );

                                  if (!mounted || !dialogContext.mounted) {
                                    return;
                                    }

                                  Navigator.of(
                                    dialogContext,
                                  ).pop();

                                  _showMessage(
                                    'Sermon created successfully.',
                                  );

                                  return;
                                }

                                // ============================================
                                // UPDATE
                                // ============================================

                                final updatedSermon =
                                    SermonModel(
                                  id: sermon.id,
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
                                      categoryController
                                          .text
                                          .trim(),

                                  // B2
                                  imageStoragePath:
                                      imageStoragePath
                                          .trim(),
                                  videoStoragePath:
                                      videoStoragePath
                                          .trim(),
                                  audioStoragePath:
                                      audioStoragePath
                                          .trim(),
                                  ebookStoragePath:
                                      ebookStoragePath
                                          .trim(),

                                  // Legacy
                                  imageUrl:
                                      imageUrl
                                          .trim(),
                                  videoUrl:
                                      videoUrl
                                          .trim(),
                                  audioUrl:
                                      audioUrl
                                          .trim(),
                                  ebookUrl:
                                      ebookUrl
                                          .trim(),

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
                                      sermon
                                          .createdAt,
                                );

                                await _sermonRepository
                                    .updateSermon(
                                  updatedSermon,
                                );

                                if (!mounted || !dialogContext.mounted) {
                              return;
                              }

                                Navigator.of(
                                  context,
                                ).pop();

                                _showMessage(
                                  'Sermon updated successfully.',
                                );
                              } catch (error) {
                                setDialogState(
                                  () {
                                    isUploading =
                                        false;
                                    uploadingLabel =
                                        '';
                                  },
                                );

                                _showMessage(
                                  'Unable to save sermon: $error',
                                  error:
                                      true,
                                );
                              }
                            },
                  child: Text(
                    sermon == null
                        ? 'Create Sermon'
                        : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    speakerController.dispose();
    categoryController.dispose();
    dateController.dispose();
    durationController.dispose();
  }

  // ==========================================================
  // DELETE SERMON
  // ==========================================================

  Future<void> _deleteSermon(
    SermonModel sermon,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Sermon?',
          ),
          content: Text(
            'Are you sure you want to delete "${sermon.title}"? '
            'This will remove the sermon record from Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
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

  // ==========================================================
  // TOGGLE PUBLISHED
  // ==========================================================

  Future<void> _togglePublished(
    SermonModel sermon,
    bool value,
  ) async {
    try {
      final updatedSermon =
          SermonModel(
        id: sermon.id,
        title: sermon.title,
        description:
            sermon.description,
        speaker: sermon.speaker,
        category: sermon.category,

        imageStoragePath:
            sermon.imageStoragePath,

        videoStoragePath:
            sermon.videoStoragePath,

        audioStoragePath:
            sermon.audioStoragePath,

        ebookStoragePath:
            sermon.ebookStoragePath,

        imageUrl:
            sermon.imageUrl,

        videoUrl:
            sermon.videoUrl,

        audioUrl:
            sermon.audioUrl,

        ebookUrl:
            sermon.ebookUrl,

        date: sermon.date,
        duration:
            sermon.duration,
        isPublished: value,
        createdAt:
            sermon.createdAt,
      );

      await _sermonRepository
          .updateSermon(
        updatedSermon,
      );

      _showMessage(
        value
            ? 'Sermon published.'
            : 'Sermon unpublished.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update publication status: $error',
        error: true,
      );
    }
  }

  // ==========================================================
  // SERMON CARD
  // ==========================================================

  Widget _buildSermonCard(
    SermonModel sermon,
  ) {
    final hasImage =
        sermon.imageUrl
                .trim()
                .isNotEmpty ||
            sermon.imageStoragePath
                .trim()
                .isNotEmpty;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        side: BorderSide(
          color: Colors.grey
              .withValues(alpha: 
            0.20,
          ),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: SizedBox(
                width: 120,
                height: 90,
                child: hasImage &&
                        sermon.imageUrl
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
                          return Container(
                            color: Colors
                                .grey
                                .shade200,
                            child:
                                const Icon(
                              Icons
                                  .image_not_supported_outlined,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors
                            .grey
                            .shade100,
                        child:
                            const Icon(
                          Icons
                              .ondemand_video_outlined,
                          size: 32,
                        ),
                      ),
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          sermon.title,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: sermon
                                  .isPublished
                              ? Colors.green
                                  .withValues(alpha: 
                                  0.10,
                                )
                              : Colors.orange
                                  .withValues(alpha: 
                                  0.10,
                                ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          sermon.isPublished
                              ? 'Published'
                              : 'Draft',
                          style:
                              TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color: sermon
                                    .isPublished
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    sermon.speaker,
                    style:
                        TextStyle(
                      color: Colors
                          .grey
                          .shade700,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      _infoChip(
                        Icons
                            .category_outlined,
                        sermon.category,
                      ),
                      _infoChip(
                        Icons
                            .calendar_today_outlined,
                        _formatDate(
                          sermon,
                        ),
                      ),
                      if (sermon
                          .hasVideo)
                        _infoChip(
                          Icons
                              .video_library_outlined,
                          'Video',
                        ),
                      if (sermon
                          .hasAudio)
                        _infoChip(
                          Icons
                              .headphones_outlined,
                          'Audio',
                        ),
                      if (sermon
                          .hasEbook)
                        _infoChip(
                          Icons
                              .picture_as_pdf_outlined,
                          'eBook',
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (sermon.description
                      .trim()
                      .isNotEmpty)
                    Text(
                      sermon.description,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // ==================================================
            // ACTIONS
            // ==================================================

            PopupMenuButton<String>(
              onSelected:
                  (value) async {
                if (value ==
                    'edit') {
                  await _showSermonForm(
                    sermon: sermon,
                  );
                }

                if (value ==
                    'delete') {
                  await _deleteSermon(
                    sermon,
                  );
                }

                if (value ==
                    'toggle') {
                  await _togglePublished(
                    sermon,
                    !sermon.isPublished,
                  );
                }
              },
              itemBuilder:
                  (context) {
                return [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          'Edit',
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          sermon.isPublished
                              ? Icons
                                  .visibility_off_outlined
                              : Icons
                                  .visibility_outlined,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          sermon.isPublished
                              ? 'Unpublish'
                              : 'Publish',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .delete_outline,
                          color:
                              Colors.red,
                          size: 20,
                        ),
                        SizedBox(
                          width: 10,
                        ),
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
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(
    IconData icon,
    String label,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.withValues(alpha: 
          0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color:
                Colors.grey.shade700,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            label,
            style:
                TextStyle(
              fontSize: 11,
              color:
                  Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Sermons',
        ),
        actions: [
          IconButton(
            tooltip:
                'Refresh',
            onPressed:
                () {
                  setState(() {});
                },
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // ========================================================
      // ADD SERMON
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            () =>
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

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(
            20,
          ),
          child: Column(
            children: [
              // ==================================================
              // SEARCH
              // ==================================================

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
                      _searchQuery
                              .isNotEmpty
                          ? IconButton(
                              onPressed:
                                  () {
                                _searchController
                                    .clear();
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .clear,
                              ),
                            )
                          : null,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // SERMON LIST
              // ==================================================

              Expanded(
                child:
                    StreamBuilder<
                        List<SermonModel>>(
                  stream:
                      _sermonRepository
                          .allSermonsStream(),
                  builder: (
                    context,
                    snapshot,
                  ) {
                    if (snapshot
                        .hasError) {
                      return Center(
                        child:
                            Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            24,
                          ),
                          child:
                              Column(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              const Icon(
                                Icons
                                    .error_outline,
                                size: 50,
                                color:
                                    Colors.red,
                              ),
                              const SizedBox(
                                height:
                                    12,
                              ),
                              const Text(
                                'Unable to load sermons.',
                                textAlign:
                                    TextAlign
                                        .center,
                              ),
                              const SizedBox(
                                height:
                                    12,
                              ),
                              OutlinedButton(
                                onPressed:
                                    () {
                                  setState(
                                    () {},
                                  );
                                },
                                child:
                                    const Text(
                                  'Retry',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (snapshot
                        .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    final sermons =
                        snapshot.data ??
                            [];

                    final filtered =
                        sermons
                            .where(
                              _matchesSearch,
                            )
                            .toList();

                    if (filtered
                        .isEmpty) {
                      return Center(
                        child:
                            Column(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            Icon(
                              _searchQuery
                                      .isNotEmpty
                                  ? Icons
                                      .search_off
                                  : Icons
                                      .library_music_outlined,
                              size: 60,
                              color: Colors
                                  .grey
                                  .shade400,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            Text(
                              _searchQuery
                                      .isNotEmpty
                                  ? 'No sermons found.'
                                  : 'No sermons yet.',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            if (_searchQuery
                                .isEmpty)
                              const Text(
                                'Create your first sermon using the button below.',
                                textAlign:
                                    TextAlign
                                        .center,
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView
                        .separated(
                      padding:
                          const EdgeInsets
                              .only(
                        bottom: 100,
                      ),
                      itemCount:
                          filtered.length,
                      separatorBuilder:
                          (
                        context,
                        index,
                      ) =>
                              const SizedBox(
                        height: 0,
                      ),
                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        return _buildSermonCard(
                          filtered[
                              index],
                        );
                      },
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