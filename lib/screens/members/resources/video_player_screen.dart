
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SermonVideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const SermonVideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SermonVideoPlayerScreen> createState() =>
      _SermonVideoPlayerScreenState();
}

class _SermonVideoPlayerScreenState
    extends State<SermonVideoPlayerScreen> {
  late VideoPlayerController _controller;

  bool _loading = true;
  String? _error;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      await _controller.initialize();

      // Automatically start playing.
      await _controller.play();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _seek(Duration amount) async {
    final current = _controller.value.position;
    final duration = _controller.value.duration;

    var target = current + amount;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (target > duration) {
      target = duration;
    }

    await _controller.seekTo(target);
  }

  @override
  Widget build(BuildContext context) {
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

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 60,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Unable to play video.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    AspectRatio(
                      aspectRatio:
                          _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller),

                          ValueListenableBuilder<
                              VideoPlayerValue>(
                            valueListenable: _controller,
                            builder: (
                              context,
                              value,
                              child,
                            ) {
                              if (value.isPlaying) {
                                return const SizedBox.shrink();
                              }

                              return IconButton(
                                iconSize: 75,
                                color: Colors.white,
                                onPressed: () {
                                  _controller.play();
                                },
                                icon: const Icon(
                                  Icons.play_circle,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFF7931E),
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white24,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        IconButton(
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () {
                            _seek(
                              const Duration(seconds: -10),
                            );
                          },
                          icon: const Icon(
                            Icons.replay_10_rounded,
                          ),
                        ),

                        ValueListenableBuilder<
                            VideoPlayerValue>(
                          valueListenable: _controller,
                          builder: (
                            context,
                            value,
                            child,
                          ) {
                            return IconButton(
                              color: Colors.white,
                              iconSize: 55,
                              onPressed: () {
                                if (value.isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                }
                              },
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                            );
                          },
                        ),

                        IconButton(
                          color: Colors.white,
                          iconSize: 32,
                          onPressed: () {
                            _seek(
                              const Duration(seconds: 10),
                            );
                          },
                          icon: const Icon(
                            Icons.forward_10_rounded,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    DropdownButton<double>(
                      value: _speed,
                      dropdownColor: Colors.grey.shade900,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      items: const [
                        0.5,
                        0.75,
                        1.0,
                        1.25,
                        1.5,
                        2.0,
                      ].map((speed) {
                        return DropdownMenuItem<double>(
                          value: speed,
                          child: Text('${speed}x'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _speed = value;
                        });

                        _controller.setPlaybackSpeed(
                          value,
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

