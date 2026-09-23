import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerCard extends StatefulWidget {
  final String audioPath;

  const AudioPlayerCard({super.key, required this.audioPath});

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final AudioPlayer _player = AudioPlayer();
  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  double _speed = 1.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      await _player.setFilePath(widget.audioPath);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to load audio: $error');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Color(0xFFDC2626)));
    }

    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final max = duration.inMilliseconds.toDouble();
            final value = max == 0
                ? 0.0
                : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EAF2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data?.playing ?? false;
                          return IconButton(
                            tooltip: isPlaying ? 'Pause' : 'Play',
                            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                            onPressed: () => isPlaying ? _player.pause() : _player.play(),
                          );
                        },
                      ),
                      Expanded(
                        child: Slider(
                          value: value,
                          max: max == 0 ? 1 : max,
                          onChanged: max == 0
                              ? null
                              : (newValue) => _player.seek(
                                    Duration(milliseconds: newValue.round()),
                                  ),
                        ),
                      ),
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      PopupMenuButton<double>(
                        tooltip: 'Playback speed',
                        initialValue: _speed,
                        onSelected: (speed) {
                          setState(() => _speed = speed);
                          _player.setSpeed(speed);
                        },
                        itemBuilder: (context) => _speeds
                            .map(
                              (speed) => PopupMenuItem(
                                value: speed,
                                child: Text('${speed}x'),
                              ),
                            )
                            .toList(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${_speed}x',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
