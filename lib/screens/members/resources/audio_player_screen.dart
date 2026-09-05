import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SermonAudioPlayerScreen
    extends StatefulWidget {
  final String url;
  final String title;

  const SermonAudioPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SermonAudioPlayerScreen>
      createState() =>
          _SermonAudioPlayerScreenState();
}

class _SermonAudioPlayerScreenState
    extends State<SermonAudioPlayerScreen> {
  final AudioPlayer _player =
      AudioPlayer();

  double _speed = 1.0;

  @override
  void initState() {
    super.initState();

    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setUrl(
        widget.url,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _seek(
    Duration amount,
  ) async {
    final position =
        _player.position;

    final target =
        position + amount;

    await _player.seek(
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
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .headphones_rounded,
              size: 100,
              color:
                  Color(0xFF6B1FA2),
            ),

            const SizedBox(
              height: 30,
            ),

            Text(
              widget.title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF3D004D),
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            StreamBuilder<
                Duration?>(
              stream:
                  _player.positionStream,
              builder: (
                context,
                snapshot,
              ) {
                final position =
                    snapshot.data ??
                        Duration.zero;

                final duration =
                    _player
                            .duration ??
                        Duration.zero;

                return Column(
                  children: [
                    Slider(
                      value: duration
                              .inMilliseconds >
                          0
                          ? position
                              .inMilliseconds
                              .clamp(
                                0,
                                duration
                                    .inMilliseconds,
                              )
                              .toDouble()
                          : 0,
                      max: duration
                              .inMilliseconds >
                          0
                          ? duration
                              .inMilliseconds
                              .toDouble()
                          : 1,
                      onChanged: (
                        value,
                      ) {
                        _player.seek(
                          Duration(
                            milliseconds:
                                value
                                    .round(),
                          ),
                        );
                      },
                      activeColor:
                          const Color(
                        0xFF6B1FA2,
                      ),
                    ),
                  ],
                );
              },
            ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                IconButton(
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

                StreamBuilder<
                    PlayerState>(
                  stream: _player
                      .playerStateStream,
                  builder: (
                    context,
                    snapshot,
                  ) {
                    final playing =
                        snapshot.data
                                ?.playing ??
                            false;

                    return IconButton(
                      iconSize: 65,
                      color:
                          const Color(
                        0xFF6B1FA2,
                      ),
                      onPressed: () {
                        if (playing) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                      icon: Icon(
                        playing
                            ? Icons
                                .pause_circle
                            : Icons
                                .play_circle,
                      ),
                    );
                  },
                ),

                IconButton(
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
              height: 20,
            ),

            DropdownButton<double>(
              value: _speed,
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

                _player
                    .setSpeed(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}