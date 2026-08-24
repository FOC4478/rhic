import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SermonVideoPlayerScreen
    extends StatefulWidget {
  final String url;
  final String title;

  const SermonVideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SermonVideoPlayerScreen>
      createState() =>
          _SermonVideoPlayerScreenState();
}

class _SermonVideoPlayerScreenState
    extends State<SermonVideoPlayerScreen> {
  late VideoPlayerController
      _controller;

  bool _loading = true;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    _controller =
        VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seek(
    Duration amount,
  ) {
    final current =
        _controller.value.position;

    final target =
        current + amount;

    _controller.seekTo(
      target < Duration.zero
          ? Duration.zero
          : target,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,

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

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
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

                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                  ),
                ),

                const SizedBox(
                  height: 15,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    IconButton(
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () {
                        _seek(
                          const Duration(
                            seconds: -10,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons
                            .replay_10_rounded,
                      ),
                    ),

                    IconButton(
                      color: Colors.white,
                      iconSize: 55,
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
                      icon: Icon(
                        _controller
                                .value
                                .isPlaying
                            ? Icons.pause_circle
                            : Icons
                                .play_circle,
                      ),
                    ),

                    IconButton(
                      color: Colors.white,
                      iconSize: 32,
                      onPressed: () {
                        _seek(
                          const Duration(
                            seconds: 10,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons
                            .forward_10_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                DropdownButton<double>(
                  value: _speed,
                  dropdownColor:
                      Colors.grey.shade900,
                  style:
                      const TextStyle(
                    color: Colors.white,
                  ),
                  items: const [
                    0.5,
                    0.75,
                    1.0,
                    1.25,
                    1.5,
                    2.0,
                  ].map(
                    (speed) {
                      return DropdownMenuItem<
                          double>(
                        value: speed,
                        child: Text(
                          '${speed}x',
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (
                    value,
                  ) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _speed = value;
                    });

                    _controller
                        .setPlaybackSpeed(
                      value,
                    );
                  },
                ),
              ],
            ),
    );
  }
}