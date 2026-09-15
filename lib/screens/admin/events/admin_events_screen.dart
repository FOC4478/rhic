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
  State<AdminEventsScreen> createState() =>
      _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final ContentRepository _repository =
      ContentRepository.instance;

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

    if (confirmed != true) {
      return;
    }

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

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
              ),
            );
          }

          final event = snapshot.data;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(
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
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    30,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _CurrentEventCard(
                      event: event,
                      onReplace: () =>
                          _openEventForm(event),
                      onDelete: _deleteEvent,
                    ),
                  ),
                ),
            ],
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
    required bool hasEvent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Events',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D004D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasEvent
                          ? 'Current event flyer'
                          : 'No event flyer published',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openEventForm(),
                icon: const Icon(
                  Icons.upload_file_outlined,
                ),
                label: Text(
                  hasEvent
                      ? 'Replace Flyer'
                      : 'Upload Flyer',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6B1FA2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E7F5),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF6B1FA2),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Only one event flyer is displayed in the member app. '
                    'Uploading a new flyer replaces the previous event. '
                    'The flyer should contain the event date, time, '
                    'description and location.',
                    style: TextStyle(
                      color: Color(0xFF55505A),
                      height: 1.45,
                      fontSize: 13,
                    ),
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
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              12,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Current Event Flyer',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3D004D),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Published',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 400,
              maxHeight: 700,
            ),
            margin: const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0F7),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: _EventImage(
              objectKey: event.imageObjectKey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              18,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReplace,
                    icon: const Icon(
                      Icons.swap_horiz_outlined,
                    ),
                    label: const Text(
                      'Replace Flyer',
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
  }
}

class _EventImage extends StatefulWidget {
  final String objectKey;

  const _EventImage({
    required this.objectKey,
  });

  @override
  State<_EventImage> createState() =>
      _EventImageState();
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

    _urlFuture =
        B2UploadService.instance.getEventDownloadUrl(
      objectKey: widget.objectKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
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
          errorBuilder:
              (_, __, ___) => Container(
            color: const Color(0xFFF1EAF4),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 56,
                color: Color(0xFF6B1FA2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EventFormDialog extends StatefulWidget {
  final EventModel? event;
  final ContentRepository repository;

  const _EventFormDialog({
    required this.event,
    required this.repository,
  });

  @override
  State<_EventFormDialog> createState() =>
      _EventFormDialogState();
}

class _EventFormDialogState
    extends State<_EventFormDialog> {
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
    if (_isUploadingFlyer ||
        _isSaving) {
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

      // ========================================================
      // EVENT FLYER UPLOAD
      // ========================================================
      //
      // IMPORTANT:
      // resourceType MUST be "event".
      //
      // The backend will therefore store the flyer under:
      //
      // events/flyers/...
      //
      // instead of:
      //
      // sermons/image/...
      // ========================================================

      final uploadResult =
          await B2UploadService.instance.uploadFile(
        bytes: bytes,
        fileName: fileName,
        contentType:
            _imageContentType(fileName),
        mediaType: 'image',
        resourceType: 'event',
      );

      if (!mounted) return;

      setState(() {
        _imageObjectKey =
            uploadResult.objectKey;
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
        imageObjectKey:
            _imageObjectKey.trim(),
        createdBy: user.uid,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
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
    return AlertDialog(
      title: Text(
        _isEditing
            ? 'Replace Event Flyer'
            : 'Upload Event Flyer',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF3D004D),
        ),
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
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
                'Upload the event notice. The flyer should contain '
                'the event information such as date, time, '
                'description and location.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0F7),
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                clipBehavior:
                    Clip.antiAlias,
                child: _flyerPreviewBytes != null
                    ? Image.memory(
                        _flyerPreviewBytes!,
                        fit: BoxFit.contain,
                      )
                    : _ExistingFlyer(
                        objectKey:
                            _imageObjectKey,
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
      actions: [
        TextButton(
          onPressed: _isSaving ||
                  _isUploadingFlyer
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        FilledButton(
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
                ),
        ),
      ],
    );
  }
}

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

    if (oldWidget.objectKey !=
        widget.objectKey) {
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

    // ==========================================================
    // EVENT FLYERS USE THE EVENT ENDPOINT
    // ==========================================================

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
          errorBuilder:
              (_, __, ___) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 48,
              color: Color(0xFF6B1FA2),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
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

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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

