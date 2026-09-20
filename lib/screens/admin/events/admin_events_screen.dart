import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../models/event_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../services/b2_upload_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final ContentRepository _repository = ContentRepository.instance;

  Future<void> _openEventForm([EventModel? event]) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventFormDialog(
        event: event,
        repository: _repository,
      ),
    );
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Event Flyer'),
          content: const Text(
            'Are you sure you want to remove the current event flyer? '
            'It will no longer appear in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteCurrentEvent();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Event flyer removed successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove event flyer: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      body: StreamBuilder<EventModel?>(
        stream: _repository.adminEventStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          final event = snapshot.data;

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      width: width,
                      hasEvent: event != null &&
                          event.imageObjectKey.trim().isNotEmpty,
                    ),
                  ),
                  if (event == null ||
                      event.imageObjectKey.trim().isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        width < 600 ? 14 : 20,
                        8,
                        width < 600 ? 14 : 20,
                        30,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _CurrentEventCard(
                          event: event,
                          onReplace: () => _openEventForm(event),
                          onDelete: _deleteEvent,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6B1FA2),
        foregroundColor: Colors.white,
        onPressed: () => _openEventForm(),
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload Flyer'),
      ),
    );
  }

  Widget _buildHeader({
    required double width,
    required bool hasEvent,
  }) {
    final isMobile = width < 650;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 20,
        isMobile ? 12 : 20,
        isMobile ? 14 : 20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Open menu',
                onPressed: () {
                  final scaffoldState = Scaffold.maybeOf(context);

                  if (scaffoldState != null &&
                      scaffoldState.hasDrawer) {
                    scaffoldState.openDrawer();
                  }
                },
                icon: const Icon(
                  Icons.menu,
                  color: Color(0xFF3D004D),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3D004D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasEvent
                          ? 'Current event flyer'
                          : 'No event flyer published',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                FilledButton.icon(
                  onPressed: () => _openEventForm(),
                  icon: const Icon(
                    Icons.upload_file_outlined,
                  ),
                  label: Text(
                    hasEvent ? 'Replace Flyer' : 'Upload Flyer',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B1FA2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openEventForm(),
                icon: const Icon(
                  Icons.upload_file_outlined,
                ),
                label: Text(
                  hasEvent ? 'Replace Flyer' : 'Upload Flyer',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B1FA2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CURRENT EVENT CARD                                                         */
/* -------------------------------------------------------------------------- */

class _CurrentEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const _CurrentEventCard({
    required this.event,
    required this.onReplace,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isMobile ? 16 : 20,
            ),
            side: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 14 : 18,
                  isMobile ? 14 : 18,
                  isMobile ? 14 : 18,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Current Event Flyer',
                        style: TextStyle(
                          fontSize: isMobile ? 17 : 19,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3D004D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 11,
                        vertical: isMobile ? 6 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Published',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 18,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: isMobile ? 260 : 400,
                    maxHeight: isMobile ? 500 : 700,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0F7),
                    borderRadius: BorderRadius.circular(
                      isMobile ? 14 : 18,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: isMobile ? 0.78 : 1.0,
                    child: _EventImage(
                      objectKey: event.imageObjectKey,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 18,
                  12,
                  isMobile ? 12 : 18,
                  isMobile ? 14 : 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReplace,
                        icon: const Icon(
                          Icons.swap_horiz_outlined,
                        ),
                        label: Text(
                          isMobile
                              ? 'Replace'
                              : 'Replace Flyer',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Remove Flyer',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EVENT IMAGE                                                                */
/* -------------------------------------------------------------------------- */

class _EventImage extends StatefulWidget {
  final String objectKey;

  const _EventImage({
    required this.objectKey,
  });

  @override
  State<_EventImage> createState() => _EventImageState();
}

class _EventImageState extends State<_EventImage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(
    covariant _EventImage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.objectKey != widget.objectKey) {
      _load();
    }
  }

  void _load() {
    if (widget.objectKey.trim().isEmpty) {
      _urlFuture = Future.error(
        'No flyer uploaded.',
      );
      return;
    }

    _urlFuture = B2UploadService.instance.getEventDownloadUrl(
      objectKey: widget.objectKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6B1FA2),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.trim().isEmpty) {
          return Container(
            color: const Color(0xFFF1EAF4),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 56,
                color: Color(0xFF6B1FA2),
              ),
            ),
          );
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFF1EAF4),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 56,
                  color: Color(0xFF6B1FA2),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EVENT FORM DIALOG                                                          */
/* -------------------------------------------------------------------------- */

class _EventFormDialog extends StatefulWidget {
  final EventModel? event;
  final ContentRepository repository;

  const _EventFormDialog({
    required this.event,
    required this.repository,
  });

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  Uint8List? _flyerPreviewBytes;

  String _imageObjectKey = '';
  String _flyerFileName = '';

  bool _isUploadingFlyer = false;
  bool _isSaving = false;

  bool get _isEditing =>
      widget.event != null &&
      widget.event!.imageObjectKey.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _imageObjectKey =
        widget.event?.imageObjectKey ?? '';
  }

  Future<void> _pickAndUploadFlyer() async {
    if (_isUploadingFlyer || _isSaving) {
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
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
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'Unable to read the selected flyer.',
        );
      }

      final fileName = file.name;

      if (!mounted) return;

      setState(() {
        _isUploadingFlyer = true;
        _flyerPreviewBytes = bytes;
        _flyerFileName = fileName;
      });

      final uploadResult =
          await B2UploadService.instance.uploadFile(
        bytes: bytes,
        fileName: fileName,
        contentType: _imageContentType(fileName),
        mediaType: 'image',
        resourceType: 'event',
      );

      if (!mounted) return;

      setState(() {
        _imageObjectKey = uploadResult.objectKey;
        _isUploadingFlyer = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Event flyer uploaded successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingFlyer = false;
        _flyerPreviewBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Flyer upload failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _imageContentType(String fileName) {
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

      default:
        throw Exception(
          'Unsupported image format.',
        );
    }
  }

  Future<void> _save() async {
    if (_imageObjectKey.trim().isEmpty) {
      _showError(
        'Please upload the event flyer.',
      );
      return;
    }

    if (_isUploadingFlyer) {
      _showError(
        'Please wait for the flyer upload to finish.',
      );
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(
        'You must be signed in as an admin.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.repository.saveEvent(
        imageObjectKey: _imageObjectKey.trim(),
        createdBy: user.uid,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Event flyer replaced successfully.'
                : 'Event flyer published successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Unable to save event flyer: $e',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final screenHeight =
        MediaQuery.sizeOf(context).height;

    final isMobile = screenWidth < 600;

    final dialogWidth = isMobile
        ? screenWidth - 32
        : screenWidth > 900
            ? 700.0
            : screenWidth - 80;

    final previewHeight = isMobile
        ? (screenHeight * 0.42).clamp(220.0, 380.0)
        : (screenHeight * 0.50).clamp(300.0, 480.0);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: screenHeight - 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 22,
                isMobile ? 14 : 18,
                isMobile ? 10 : 14,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Replace Event Flyer'
                          : 'Upload Event Flyer',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 21,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3D004D),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ||
                            _isUploadingFlyer
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isMobile ? 16 : 22,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Flyer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D004D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload the event flyer. '
                      'The flyer should contain the event '
                      'information such as date, time, '
                      'description and location.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.4,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: previewHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0F7),
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _flyerPreviewBytes != null
                          ? Image.memory(
                              _flyerPreviewBytes!,
                              fit: BoxFit.contain,
                            )
                          : _ExistingFlyer(
                              objectKey: _imageObjectKey,
                            ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isUploadingFlyer ||
                                    _isSaving
                                ? null
                                : _pickAndUploadFlyer,
                        icon: _isUploadingFlyer
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.upload_file_outlined,
                              ),
                        label: Text(
                          _isUploadingFlyer
                              ? 'Uploading Flyer...'
                              : _imageObjectKey.isEmpty
                                  ? 'Select Flyer'
                                  : 'Select Another Flyer',
                        ),
                      ),
                    ),
                    if (_flyerFileName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _flyerFileName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 18,
                10,
                isMobile ? 12 : 18,
                12,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ||
                            _isUploadingFlyer
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FilledButton(
                      onPressed:
                          _isSaving ||
                                  _isUploadingFlyer
                              ? null
                              : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6B1FA2),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? 'Publish Replacement'
                                  : 'Publish Flyer',
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EXISTING FLYER                                                             */
/* -------------------------------------------------------------------------- */

class _ExistingFlyer extends StatefulWidget {
  final String objectKey;

  const _ExistingFlyer({
    required this.objectKey,
  });

  @override
  State<_ExistingFlyer> createState() =>
      _ExistingFlyerState();
}

class _ExistingFlyerState
    extends State<_ExistingFlyer> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(
    covariant _ExistingFlyer oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.objectKey != widget.objectKey) {
      _load();
    }
  }

  void _load() {
    if (widget.objectKey.trim().isEmpty) {
      _future = Future.error(
        'No flyer uploaded.',
      );
      return;
    }

    _future =
        B2UploadService.instance.getEventDownloadUrl(
      objectKey: widget.objectKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.objectKey.trim().isEmpty) {
      return const Center(
        child: Text(
          'No flyer selected',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6B1FA2),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.trim().isEmpty) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Color(0xFF6B1FA2),
            ),
          );
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Color(0xFF6B1FA2),
              ),
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EMPTY STATE                                                                */
/* -------------------------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'No Event Flyer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3D004D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload an event flyer to publish it '
              'to members.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ERROR STATE                                                                */
/* -------------------------------------------------------------------------- */

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Unable to load event.\n\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}