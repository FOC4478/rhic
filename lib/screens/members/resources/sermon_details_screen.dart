import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../../../models/sermon_model.dart';
// import '../../../repositories/library_repository.dart';

class SermonDetailsScreen
    extends StatelessWidget {
  final SermonModel sermon;

  const SermonDetailsScreen({
    super.key,
    required this.sermon,
  });

  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  // ============================================================
  // B2 BACKEND
  // ============================================================

  // Your current local backend.
  //
  // When the backend is deployed, change this to:
  //
  // https://your-deployed-backend-url
  //
  static const String b2BackendUrl =
      'http://localhost:3000';

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,

            color:
                Colors.black,
          ),

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        title: const Text(
          'Sermon',

          style:
              TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.w700,
            color:
                darkPurple,
          ),
        ),
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
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
            // IMAGE
            // ====================================================

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              child: AspectRatio(
                aspectRatio:
                    16 / 9,

                child:
                    sermon.imageUrl
                            .trim()
                            .isNotEmpty
                        ? Image.network(
                            sermon.imageUrl,

                            fit:
                                BoxFit.cover,

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

            const SizedBox(
              height: 22,
            ),

            // ====================================================
            // CATEGORY
            // ====================================================

            if (sermon.category
                .trim()
                .isNotEmpty)
              Text(
                sermon.category
                    .toUpperCase(),

                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      orangeColor,
                  letterSpacing:
                      1,
                ),
              ),

            const SizedBox(
              height: 7,
            ),

            // ====================================================
            // TITLE
            // ====================================================

            Text(
              sermon.title,

              style:
                  const TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.w800,
                color:
                    darkPurple,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            // ====================================================
            // SPEAKER
            // ====================================================

            Text(
              sermon.speaker,

              style:
                  const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    orangeColor,
              ),
            ),

            // ====================================================
            // DESCRIPTION
            // ====================================================

            if (sermon.description
                .trim()
                .isNotEmpty) ...[
              const SizedBox(
                height: 18,
              ),

              Text(
                sermon.description,

                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color:
                      Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(
              height: 28,
            ),

            // ====================================================
            // AVAILABLE RESOURCES
            // ====================================================

            const Text(
              'Available Resources',

              style:
                  TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
                color:
                    darkPurple,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ====================================================
            // VIDEO
            // ====================================================

            if (sermon.hasVideo)
              _ResourceOption(
                icon: Icons
                    .play_circle_outline_rounded,

                title: 'Video',

                subtitle:
                    sermon.duration
                            .isNotEmpty
                        ? sermon.duration
                        : 'Watch this sermon',

                color:
                    primaryColor,

                onTap: () {
                  _openMedia(
                    context,
                    type: 'video',
                  );
                },
              ),

            // ====================================================
            // AUDIO
            // ====================================================

            if (sermon.hasAudio) ...[
              const SizedBox(
                height: 12,
              ),

              _ResourceOption(
                icon: Icons
                    .headphones_outlined,

                title: 'Audio',

                subtitle:
                    'Listen to this sermon',

                color:
                    orangeColor,

                onTap: () {
                  _openMedia(
                    context,
                    type: 'audio',
                  );
                },
              ),
            ],

            // ====================================================
            // EBOOK
            // ====================================================

            if (sermon.hasEbook) ...[
              const SizedBox(
                height: 12,
              ),

              _ResourceOption(
                icon: Icons
                    .menu_book_outlined,

                title: 'Ebook',

                subtitle:
                    'Read the sermon material',

                color:
                    primaryColor,

                onTap: () {
                  _openMedia(
                    context,
                    type: 'ebook',
                  );
                },
              ),
            ],

            // ====================================================
            // NOTHING AVAILABLE
            // ====================================================

            if (!sermon.hasVideo &&
                !sermon.hasAudio &&
                !sermon.hasEbook)
              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  20,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F3F8,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child:
                    const Text(
                  'No resources are currently available for this sermon.',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF777777,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPEN MEDIA
  // ============================================================

  Future<void> _openMedia(
    BuildContext context, {
    required String type,
  }) async {
    try {
      final objectKey =
          _getObjectKey(type);

      // ========================================================
      // LEGACY URL
      //
      // This allows old sermons to continue working.
      // ========================================================

      final legacyUrl =
          _getLegacyUrl(type);

      String mediaUrl =
          legacyUrl;

      // ========================================================
      // B2 STORAGE PATH
      // ========================================================

      if (objectKey
          .trim()
          .isNotEmpty) {
        mediaUrl =
            await _getSignedDownloadUrl(
          context,
          objectKey,
        );
      }

      if (mediaUrl.trim().isEmpty) {
        throw Exception(
          'No media URL is available.',
        );
      }

      if (!context.mounted) {
        return;
      }

      // ========================================================
      // OPEN PLAYER
      // ========================================================

      if (type == 'video') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _VideoPlayerScreen(
              title:
                  sermon.title,
              url:
                  mediaUrl,
            ),
          ),
        );

        return;
      }

      if (type == 'audio') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _AudioPlayerScreen(
              title:
                  sermon.title,
              speaker:
                  sermon.speaker,
              url:
                  mediaUrl,
            ),
          ),
        );

        return;
      }

      if (type == 'ebook') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _EbookViewerScreen(
              title:
                  sermon.title,
              url:
                  mediaUrl,
            ),
          ),
        );

        return;
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open $type: $error',
          ),

          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
    }
  }

  // ============================================================
  // GET OBJECT KEY
  // ============================================================

  String _getObjectKey(
    String type,
  ) {
    switch (type) {
      case 'video':
        return sermon
            .videoStoragePath
            .trim();

      case 'audio':
        return sermon
            .audioStoragePath
            .trim();

      case 'ebook':
        return sermon
            .ebookStoragePath
            .trim();

      case 'image':
        return sermon
            .imageStoragePath
            .trim();

      default:
        return '';
    }
  }

  // ============================================================
  // GET LEGACY URL
  // ============================================================

  String _getLegacyUrl(
    String type,
  ) {
    switch (type) {
      case 'video':
        return sermon.videoUrl
            .trim();

      case 'audio':
        return sermon.audioUrl
            .trim();

      case 'ebook':
        return sermon.ebookUrl
            .trim();

      case 'image':
        return sermon.imageUrl
            .trim();

      default:
        return '';
    }
  }

  // ============================================================
  // GET SIGNED B2 URL
  // ============================================================

  Future<String>
      _getSignedDownloadUrl(
    BuildContext context,
    String objectKey,
  ) async {
    final user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      throw Exception(
        'Please sign in to access sermon media.',
      );
    }

    // ==========================================================
    // GET FIREBASE ID TOKEN
    // ==========================================================

    final idToken =
        await user.getIdToken(
      true,
    );

    if (idToken == null ||
        idToken.trim().isEmpty) {
      throw Exception(
        'Unable to authenticate with the media server.',
      );
    }

    // ==========================================================
    // CALL NODE BACKEND
    // ==========================================================

    final response =
        await http.post(
      Uri.parse(
        '$b2BackendUrl/download-url',
      ),

      headers: {
        'Content-Type':
            'application/json',

        'Authorization':
            'Bearer $idToken',
      },

      body:
          jsonEncode({
        'objectKey':
            objectKey,
      }),
    );

    // ==========================================================
    // HANDLE SERVER RESPONSE
    // ==========================================================

    if (response.statusCode !=
        200) {
      try {
        final data =
            jsonDecode(
          response.body,
        );

        throw Exception(
          data['message']
                  ?.toString() ??
              'Media server rejected the request.',
        );
      } catch (_) {
        throw Exception(
          'Media server returned status ${response.statusCode}.',
        );
      }
    }

    final data =
        jsonDecode(
      response.body,
    );

    final downloadUrl =
        data['downloadUrl']
                ?.toString() ??
            '';

    if (downloadUrl
        .trim()
        .isEmpty) {
      throw Exception(
        'The media server did not return a download URL.',
      );
    }

    return downloadUrl;
  }

  // ============================================================
  // IMAGE PLACEHOLDER
  // ============================================================

  Widget _imagePlaceholder() {
    return Container(
      color:
          const Color(0xFFF3EAF5),

      child: const Center(
        child: Icon(
          Icons
              .video_library_outlined,

          size: 55,

          color:
              Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ================================================================
// RESOURCE OPTION
// ================================================================

class _ResourceOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ResourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,

      borderRadius:
          BorderRadius.circular(
        18,
      ),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child: Container(
          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              18,
            ),

            border: Border.all(
              color:
                  const Color(
                0xFFEDE3F0,
              ),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: .10,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color:
                      color,
                  size: 27,
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF3D004D,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      subtitle,

                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors
                                .grey
                                .shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,

                size: 16,

                color:
                    Colors.grey
                        .shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// VIDEO PLAYER
// ================================================================

class _VideoPlayerScreen
    extends StatefulWidget {
  final String title;
  final String url;

  const _VideoPlayerScreen({
    required this.title,
    required this.url,
  });

  @override
  State<_VideoPlayerScreen>
      createState() =>
          _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<
        _VideoPlayerScreen> {
  late final VideoPlayerController
      _controller;

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _controller =
          VideoPlayerController
              .networkUrl(
        Uri.parse(
          widget.url,
        ),
      );

      await _controller.initialize();

      await _controller.setLooping(
        false,
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      appBar: AppBar(
        backgroundColor:
            Colors.black,

        foregroundColor:
            Colors.white,

        title: Text(
          widget.title,

          maxLines: 1,

          overflow:
              TextOverflow.ellipsis,
        ),
      ),

      body: Center(
        child: _loading
            ? const CircularProgressIndicator(
                color:
                    Color(
                  0xFFF7931E,
                ),
              )
            : _error != null
                ? Padding(
                    padding:
                        const EdgeInsets.all(
                      25,
                    ),

                    child: Text(
                      'Unable to play video.\n\n$_error',

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [
                      AspectRatio(
                        aspectRatio:
                            _controller
                                .value
                                .aspectRatio,

                        child:
                            VideoPlayer(
                          _controller,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      IconButton(
                        iconSize: 60,

                        color:
                            Colors.white,

                        icon: Icon(
                          _controller
                                  .value
                                  .isPlaying
                              ? Icons
                                  .pause_circle
                              : Icons
                                  .play_circle,
                        ),

                        onPressed: () {
                          setState(() {
                            if (_controller
                                .value
                                .isPlaying) {
                              _controller
                                  .pause();
                            } else {
                              _controller
                                  .play();
                            }
                          });
                        },
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      VideoProgressIndicator(
                        _controller,

                        allowScrubbing:
                            true,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              20,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ================================================================
// AUDIO PLAYER
// ================================================================

class _AudioPlayerScreen
    extends StatefulWidget {
  final String title;
  final String speaker;
  final String url;

  const _AudioPlayerScreen({
    required this.title,
    required this.speaker,
    required this.url,
  });

  @override
  State<_AudioPlayerScreen>
      createState() =>
          _AudioPlayerScreenState();
}

class _AudioPlayerScreenState
    extends State<
        _AudioPlayerScreen> {
  final AudioPlayer _player =
      AudioPlayer();

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _player.setUrl(
        widget.url,
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
          ),

          color:
              Colors.black,

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        title: const Text(
          'Audio',

          style:
              TextStyle(
            fontWeight:
                FontWeight.w700,

            color:
                Color(
              0xFF3D004D,
            ),
          ),
        ),
      ),

      body: Center(
        child: _loading
            ? const CircularProgressIndicator(
                color:
                    Color(
                  0xFF6B1FA2,
                ),
              )
            : _error != null
                ? Padding(
                    padding:
                        const EdgeInsets.all(
                      25,
                    ),

                    child: Text(
                      'Unable to play audio.\n\n$_error',

                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF777777,
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding:
                        const EdgeInsets.all(
                      30,
                    ),

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Container(
                          width: 140,
                          height: 140,

                          decoration:
                              const BoxDecoration(
                            color:
                                Color(
                              0xFFF3EAF5,
                            ),

                            shape:
                                BoxShape
                                    .circle,
                          ),

                          child:
                              const Icon(
                            Icons
                                .headphones_rounded,

                            size: 70,

                            color:
                                Color(
                              0xFF6B1FA2,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        Text(
                          widget.title,

                          textAlign:
                              TextAlign
                                  .center,

                          style:
                              const TextStyle(
                            fontSize: 22,

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
                          height: 8,
                        ),

                        Text(
                          widget.speaker,

                          textAlign:
                              TextAlign
                                  .center,

                          style:
                              const TextStyle(
                            fontSize: 14,

                            color:
                                Color(
                              0xFFF7931E,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        StreamBuilder<
                            Duration?>(
                          stream:
                              _player
                                  .durationStream,

                          builder: (
                            context,
                            snapshot,
                          ) {
                            final duration =
                                snapshot.data ??
                                    Duration
                                        .zero;

                            return StreamBuilder<
                                Duration>(
                              stream:
                                  _player
                                      .positionStream,

                              builder: (
                                context,
                                positionSnapshot,
                              ) {
                                final position =
                                    positionSnapshot
                                            .data ??
                                        Duration
                                            .zero;

                                final max =
                                    duration
                                        .inMilliseconds
                                        .toDouble();

                                final value =
                                    position
                                        .inMilliseconds
                                        .toDouble()
                                        .clamp(
                                          0,
                                          max > 0
                                              ? max
                                              : 1,
                                        );

                                return Column(
                                  children: [
                                    Slider(
                                      value:
                                          value.toDouble(),

                                      max:
                                          max > 0
                                              ? max
                                              : 1,

                                      activeColor:
                                          const Color(
                                        0xFF6B1FA2,
                                      ),

                                      onChanged:
                                          max <=
                                                  0
                                              ? null
                                              : (
                                                  value,
                                                ) {
                                                  _player
                                                      .seek(
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
                                        ),

                                        Text(
                                          _formatDuration(
                                            duration,
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

                        const SizedBox(
                          height: 20,
                        ),

                        StreamBuilder<
                            PlayerState>(
                          stream:
                              _player
                                  .playerStateStream,

                          builder: (
                            context,
                            snapshot,
                          ) {
                            final state =
                                snapshot.data;

                            final playing =
                                state?.playing ??
                                    false;

                            return IconButton(
                              iconSize:
                                  72,

                              color:
                                  const Color(
                                0xFF6B1FA2,
                              ),

                              icon: Icon(
                                playing
                                    ? Icons
                                        .pause_circle_filled
                                    : Icons
                                        .play_circle_fill,
                              ),

                              onPressed:
                                  () async {
                                if (playing) {
                                  await _player
                                      .pause();
                                } else {
                                  await _player
                                      .play();
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _formatDuration(
    Duration duration,
  ) {
    final minutes =
        duration.inMinutes
            .remainder(60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    final seconds =
        duration.inSeconds
            .remainder(60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }
}

// ================================================================
// EBOOK VIEWER
// ================================================================

class _EbookViewerScreen
    extends StatelessWidget {
  final String title;
  final String url;

  const _EbookViewerScreen({
    required this.title,
    required this.url,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
          ),

          color:
              Colors.black,

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        title: Text(
          title,

          maxLines: 1,

          overflow:
              TextOverflow.ellipsis,

          style:
              const TextStyle(
            fontSize: 18,

            fontWeight:
                FontWeight.w700,

            color:
                Color(
              0xFF3D004D,
            ),
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            30,
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              Container(
                width: 120,
                height: 120,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(
                    0xFFF3EAF5,
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons
                      .picture_as_pdf_rounded,

                  size: 65,

                  color:
                      Color(
                    0xFF6B1FA2,
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'Ebook Ready',

                style:
                    TextStyle(
                  fontSize: 21,

                  fontWeight:
                      FontWeight.w800,

                  color:
                      Color(
                    0xFF3D004D,
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'The sermon material is available as a PDF.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF777777,
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                width:
                    double.infinity,

                height: 50,

                child:
                    ElevatedButton(
                  onPressed: () {
                    // ==================================================
                    // The signed URL is ready.
                    //
                    // You can connect this to your preferred PDF
                    // viewer once you add a PDF viewer package.
                    // ==================================================

                    ScaffoldMessenger
                        .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'PDF URL is ready for the ebook viewer.',
                        ),
                      ),
                    );
                  },

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF6B1FA2,
                    ),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        25,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'Open Ebook',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}