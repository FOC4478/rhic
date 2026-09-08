import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../models/sermon_model.dart';
import '../../../services/b2_upload_service.dart';

class SermonDetailsScreen extends StatefulWidget {
  final SermonModel sermon;
  final bool autoPlay;
  final String initialMediaType;

  const SermonDetailsScreen({
    super.key,
    required this.sermon,
    this.autoPlay = false,
    this.initialMediaType = 'video',
  });

  @override
  State<SermonDetailsScreen> createState() =>
      _SermonDetailsScreenState();
}

class _SermonDetailsScreenState
    extends State<SermonDetailsScreen> {
  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  VideoPlayerController? _videoController;

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _videoLoading = false;
  bool _audioLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          if (widget.initialMediaType == 'video') {
            _playVideo();
          } else if (widget.initialMediaType == 'audio') {
            _playAudio();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ============================================================
  // VIDEO
  // ============================================================

  Future<void> _playVideo() async {
    final objectKey =
        widget.sermon.videoStoragePath.trim();

    final legacyUrl =
        widget.sermon.videoUrl.trim();

    if (objectKey.isEmpty && legacyUrl.isEmpty) {
      _showMessage(
        'No video is available for this sermon.',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _videoLoading = true;
      });
    }

    try {
      String url;

      if (objectKey.isNotEmpty) {
        // Get temporary signed URL from B2 backend.
        url = await B2UploadService.instance
            .getDownloadUrl(
          objectKey: objectKey,
        );
      } else {
        // Legacy support.
        url = legacyUrl;
      }

      await _videoController?.dispose();

      final controller =
          VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      _videoController = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoLoading = false;
      });

      // Start playing immediately.
      await controller.play();

      await _openVideoPlayer();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _videoLoading = false;
      });

      _showMessage(
        'Unable to open video: $e',
      );
    }
  }

  Future<void> _openVideoPlayer() async {
    final controller = _videoController;

    if (controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VideoPlayerScreen(
          controller: controller,
          title: widget.sermon.title,
        ),
      ),
    );

    if (controller.value.isPlaying) {
      await controller.pause();
    }
  }

  // ============================================================
  // AUDIO
  // ============================================================

  Future<void> _playAudio() async {
    final objectKey =
        widget.sermon.audioStoragePath.trim();

    final legacyUrl =
        widget.sermon.audioUrl.trim();

    if (objectKey.isEmpty && legacyUrl.isEmpty) {
      _showMessage(
        'No audio is available for this sermon.',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _audioLoading = true;
      });
    }

    try {
      String url;

      if (objectKey.isNotEmpty) {
        // Get temporary signed URL from B2 backend.
        url = await B2UploadService.instance
            .getDownloadUrl(
          objectKey: objectKey,
        );
      } else {
        // Legacy support.
        url = legacyUrl;
      }

      await _audioPlayer.stop();

      await _audioPlayer.setUrl(url);

      if (!mounted) {
        return;
      }

      setState(() {
        _audioLoading = false;
      });

      // Start playing immediately.
      await _audioPlayer.play();

      await _openAudioPlayer();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioLoading = false;
      });

      _showMessage(
        'Unable to open audio: $e',
      );
    }
  }

  Future<void> _openAudioPlayer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AudioPlayerScreen(
          player: _audioPlayer,
          sermon: widget.sermon,
        ),
      ),
    );

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    }
  }

  // ============================================================
  // EBOOK
  // ============================================================

  Future<void> _openEbook() async {
    final objectKey =
        widget.sermon.ebookStoragePath.trim();

    final legacyUrl =
        widget.sermon.ebookUrl.trim();

    if (objectKey.isEmpty && legacyUrl.isEmpty) {
      _showMessage(
        'No ebook is available for this sermon.',
      );
      return;
    }

    try {
      String url;

      if (objectKey.isNotEmpty) {
        // Get temporary signed URL from B2 backend.
        url = await B2UploadService.instance
            .getDownloadUrl(
          objectKey: objectKey,
        );
      } else {
        // Legacy support.
        url = legacyUrl;
      }

      final uri = Uri.parse(url);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(
          'Could not open ebook.',
        );
      }
    } catch (e) {
      _showMessage(
        'Unable to open ebook: $e',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final sermon = widget.sermon;

    return Scaffold(
      backgroundColor: Colors.white,
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
          'Sermon',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkPurple,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ====================================================
            // COVER IMAGE
            // ====================================================

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: sermon.imageUrl
                        .trim()
                        .isNotEmpty
                    ? Image.network(
                        sermon.imageUrl,
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
            ),

            const SizedBox(height: 20),

            // ====================================================
            // SERMON
            // ====================================================

            const Text(
              'SERMON',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: orangeColor,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 7),

            // ====================================================
            // TITLE
            // ====================================================

            Text(
              sermon.title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: darkPurple,
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // SPEAKER
            // ====================================================

            Text(
              sermon.speaker,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: orangeColor,
              ),
            ),

            // ====================================================
            // DATE
            // ====================================================

            if (sermon.date.trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                sermon.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],

            // ====================================================
            // DESCRIPTION
            // ====================================================

            if (sermon.description
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                sermon.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ====================================================
            // RESOURCES
            // ====================================================

            const Text(
              'Available Resources',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: darkPurple,
              ),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // VIDEO
            // ====================================================

            if (sermon.hasVideo)
              _ResourceOption(
                icon: Icons.play_circle_outline_rounded,
                title: 'Video',
                subtitle: _videoLoading
                    ? 'Opening video...'
                    : 'Watch this sermon',
                color: primaryColor,
                loading: _videoLoading,
                onTap: _playVideo,
              ),

            // ====================================================
            // AUDIO
            // ====================================================

            if (sermon.hasAudio) ...[
              const SizedBox(height: 12),
              _ResourceOption(
                icon: Icons.headphones_outlined,
                title: 'Audio',
                subtitle: _audioLoading
                    ? 'Opening audio...'
                    : 'Listen to this sermon',
                color: orangeColor,
                loading: _audioLoading,
                onTap: _playAudio,
              ),
            ],

            // ====================================================
            // EBOOK
            // ====================================================

            if (sermon.hasEbook) ...[
              const SizedBox(height: 12),
              _ResourceOption(
                icon: Icons.menu_book_outlined,
                title: 'Ebook',
                subtitle: 'Read the sermon material',
                color: primaryColor,
                onTap: _openEbook,
              ),
            ],

            // ====================================================
            // NO RESOURCE
            // ====================================================

            if (!sermon.hasVideo &&
                !sermon.hasAudio &&
                !sermon.hasEbook)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3F8),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Text(
                  'No resources are currently available for this sermon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF777777),
                  ),
                ),
              ),
          ],
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
          size: 55,
          color: Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ================================================================
// RESOURCE OPTION
// ================================================================

class _ResourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _ResourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFEDE3F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: loading
                    ? Padding(
                        padding:
                            const EdgeInsets.all(14),
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 27,
                      ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3D004D),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// VIDEO PLAYER SCREEN
// ================================================================

class _VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;

  const _VideoPlayerScreen({
    required this.controller,
    required this.title,
  });

  @override
  State<_VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<_VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();

    if (!widget.controller.value.isPlaying) {
      widget.controller.play();
    }
  }

  @override
  void dispose() {
    widget.controller.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: controller.value.isInitialized
            ? AspectRatio(
                aspectRatio:
                    controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(controller),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (controller
                              .value
                              .isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        });
                      },
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration:
                            const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child:
                            ValueListenableBuilder<
                                VideoPlayerValue>(
                          valueListenable:
                              controller,
                          builder: (
                            context,
                            value,
                            child,
                          ) {
                            return Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: const Color(
                                0xFF6B1FA2,
                              ),
                              size: 38,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(
                color: Colors.white,
              ),
      ),
    );
  }
}

// ================================================================
// AUDIO PLAYER SCREEN
// ================================================================

class _AudioPlayerScreen extends StatelessWidget {
  final AudioPlayer player;
  final SermonModel sermon;

  const _AudioPlayerScreen({
    required this.player,
    required this.sermon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Audio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3D004D),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              // ==================================================
              // ARTWORK
              // ==================================================

              ClipOval(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: sermon.imageUrl
                          .trim()
                          .isNotEmpty
                      ? Image.network(
                          sermon.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _placeholder();
                          },
                        )
                      : _placeholder(),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // TITLE
              // ==================================================

              Text(
                sermon.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3D004D),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                sermon.speaker,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF7931E),
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // PROGRESS
              // ==================================================

              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (
                  context,
                  positionSnapshot,
                ) {
                  final position =
                      positionSnapshot.data ??
                          Duration.zero;

                  return StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (
                      context,
                      durationSnapshot,
                    ) {
                      final duration =
                          durationSnapshot.data ??
                              Duration.zero;

                      final max =
                          duration.inMilliseconds > 0
                              ? duration
                                  .inMilliseconds
                                  .toDouble()
                              : 1.0;

                      final current = position
                          .inMilliseconds
                          .toDouble()
                          .clamp(
                            0.0,
                            max,
                          )
                          .toDouble();

                      return Column(
                        children: [
                          Slider(
                            min: 0,
                            max: max,
                            value: current,
                            activeColor:
                                const Color(0xFF6B1FA2),
                            inactiveColor:
                                const Color(0xFFE5D9E8),
                            onChanged:
                                duration ==
                                        Duration.zero
                                    ? null
                                    : (value) {
                                        player.seek(
                                          Duration(
                                            milliseconds:
                                                value.round(),
                                          ),
                                        );
                                      },
                          ),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  position,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Color(0xFF888888),
                                ),
                              ),
                              Text(
                                _formatDuration(
                                  duration,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PLAY / PAUSE
              // ==================================================

              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (
                  context,
                  snapshot,
                ) {
                  final state = snapshot.data;

                  final playing =
                      state?.playing ?? false;

                  final processing =
                      state?.processingState ==
                              ProcessingState.loading ||
                          state?.processingState ==
                              ProcessingState.buffering;

                  return GestureDetector(
                    onTap: processing
                        ? null
                        : () async {
                            if (playing) {
                              await player.pause();
                            } else {
                              await player.play();
                            }
                          },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration:
                          const BoxDecoration(
                        color: Color(0xFF6B1FA2),
                        shape: BoxShape.circle,
                      ),
                      child: processing
                          ? const Padding(
                              padding:
                                  EdgeInsets.all(22),
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF3EAF5),
      child: const Center(
        child: Icon(
          Icons.headphones_rounded,
          size: 65,
          color: Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ================================================================
// FORMAT DURATION
// ================================================================

String _formatDuration(Duration duration) {
  if (duration == Duration.zero) {
    return '0:00';
  }

  final hours = duration.inHours;

  final minutes =
      duration.inMinutes.remainder(60);

  final seconds =
      duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

