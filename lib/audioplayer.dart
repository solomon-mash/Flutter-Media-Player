import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlay extends StatefulWidget {
  final String filepath;
  const AudioPlay(this.filepath, {Key? key}) : super(key: key);

  @override
  State<AudioPlay> createState() => _AudioPlayState();
}

class _AudioPlayState extends State<AudioPlay> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  void _initializeAudio() async {
    try {
      await _audioPlayer.setSource(DeviceFileSource(widget.filepath));
      final duration = await _audioPlayer.getDuration();
      setState(() {
        _audioDuration = duration ?? Duration.zero;
      });

      _audioPlayer.onPositionChanged.listen((Duration position) {
        setState(() {
          _currentPosition = position;
        });
      });

      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      });

      await _audioPlayer.play(DeviceFileSource(widget.filepath));

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error initializing audio: $e");
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play(DeviceFileSource(widget.filepath));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekForward() {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    _audioPlayer.seek(newPosition);
  }

  void _seekBackward() {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    _audioPlayer.seek(newPosition);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  Icons.music_note,
                  size: MediaQuery.of(context).size.height * 0.4,
                  color: Colors.blue,
                ),
              ),
            ),
            Slider(
              onChanged: (value) {
                final position = value * _audioDuration.inMilliseconds;
                _audioPlayer.seek(Duration(milliseconds: position.round()));
              },
              value: (_currentPosition.inMilliseconds > 0 &&
                      _currentPosition.inMilliseconds <
                          _audioDuration.inMilliseconds)
                  ? _currentPosition.inMilliseconds /
                      _audioDuration.inMilliseconds
                  : 0.0,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_currentPosition),
                    style: TextStyle(color: Color(0xFFC7C7C7)),
                  ),
                  Text(_formatDuration(_audioDuration),
                      style: TextStyle(color: Color(0xFFC7C7C7))),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.replay_10),
                  iconSize: 36.0,
                  onPressed: _seekBackward,
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 48.0,
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: Icon(Icons.forward_10),
                  iconSize: 36.0,
                  onPressed: _seekForward,
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
