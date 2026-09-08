
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class SermonAudioPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const SermonAudioPlayerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<SermonAudioPlayerScreen> createState() =>
      _SermonAudioPlayerScreenState();
}

class _SermonAudioPlayerScreenState
    extends State<SermonAudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();

  double _speed = 1.0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      await _player.setUrl(widget.url);

      // Automatically start playing.
      await _player.play();

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
    _player.dispose();
    super.dispose();
  }

  Future<void> _seek(Duration amount) async {
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;

    var target = position + amount;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (duration > Duration.zero && target > duration) {
      target = duration;
    }

    await _player.seek(target);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B1FA2),
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
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Unable to play audio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadAudio,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.headphones_rounded,
                        size: 100,
                        color: Color(0xFF6B1FA2),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3D004D),
                        ),
                      ),

                      const SizedBox(height: 40),

                      StreamBuilder<Duration>(
                        stream: _player.positionStream,
                        builder: (context, snapshot) {
                          final position =
                              snapshot.data ?? Duration.zero;

                          final duration =
                              _player.duration ?? Duration.zero;

                          final maxMilliseconds =
                              duration.inMilliseconds;

                          final currentMilliseconds =
                              position.inMilliseconds.clamp(
                            0,
                            maxMilliseconds > 0
                                ? maxMilliseconds
                                : 0,
                          );

                          return Column(
                            children: [
                              Slider(
                                value: maxMilliseconds > 0
                                    ? currentMilliseconds.toDouble()
                                    : 0,
                                max: maxMilliseconds > 0
                                    ? maxMilliseconds.toDouble()
                                    : 1,
                                onChanged: (value) {
                                  _player.seek(
                                    Duration(
                                      milliseconds: value.round(),
                                    ),
                                  );
                                },
                                activeColor:
                                    const Color(0xFF6B1FA2),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
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

                          StreamBuilder<PlayerState>(
                            stream: _player.playerStateStream,
                            builder: (context, snapshot) {
                              final playing =
                                  snapshot.data?.playing ?? false;

                              return IconButton(
                                iconSize: 65,
                                color: const Color(0xFF6B1FA2),
                                onPressed: () {
                                  if (playing) {
                                    _player.pause();
                                  } else {
                                    _player.play();
                                  }
                                },
                                icon: Icon(
                                  playing
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                ),
                              );
                            },
                          ),

                          IconButton(
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

                      const SizedBox(height: 20),

                      DropdownButton<double>(
                        value: _speed,
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

                          _player.setSpeed(value);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}

