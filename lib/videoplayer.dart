import 'dart:async';
import 'dart:io';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoPlay extends StatefulWidget {
  final String filepath;
  const VideoPlay(this.filepath, {Key? key}) : super(key: key);

  @override
  State<VideoPlay> createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  late FlickManager _flickManager;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.file(File(widget.filepath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _flickManager.flickControlManager?.play();
          }
        }),
    );

    _startHideTimer();
  }

  @override
  void dispose() {
    _flickManager.dispose();
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Reset

    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    _showControlsForAWhile();
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  void _showControlsForAWhile() {
    setState(() {
      _showControls = true;
    });
    _hideTimer?.cancel();
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: CupertinoPageScaffold(
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: _showControlsForAWhile,
              onDoubleTap: () {
                final currentPosition =
                    _flickManager.flickVideoManager!.videoPlayerValue!.position;
                final rewindPosition =
                    currentPosition - const Duration(seconds: 10);
                _flickManager.flickControlManager!.seekTo(rewindPosition);
              },
              onDoubleTapDown: (details) {
                final currentPosition =
                    _flickManager.flickVideoManager!.videoPlayerValue!.position;
                final forwardPosition =
                    currentPosition + const Duration(seconds: 10);
                _flickManager.flickControlManager!.seekTo(forwardPosition);
              },
              child: _flickManager.flickVideoManager?.videoPlayerController !=
                          null &&
                      _flickManager.flickVideoManager!.videoPlayerController!
                          .value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _flickManager.flickVideoManager!
                          .videoPlayerController!.value.aspectRatio,
                      child: FlickVideoPlayer(
                        flickManager: _flickManager,
                        flickVideoWithControls: FlickVideoWithControls(
                          controls: _showControls
                              ? CustomFlickControls(
                                  flickManager: _flickManager,
                                  toggleFullscreen: _toggleFullscreen,
                                )
                              : const SizedBox.shrink(),
                        ),
                        systemUIOverlay: [],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    ));
  }
}

class CustomFlickControls extends StatelessWidget {
  final FlickManager flickManager;
  final VoidCallback toggleFullscreen;

  const CustomFlickControls({
    Key? key,
    required this.flickManager,
    required this.toggleFullscreen,
  }) : super(key: key);

  // Seek backward by 5 seconds
  void _seekBackward() {
    final currentPosition =
        flickManager.flickVideoManager!.videoPlayerValue!.position;
    final rewindPosition = currentPosition - const Duration(seconds: 5);
    flickManager.flickControlManager!.seekTo(rewindPosition);
  }

  // Seek forward by 5 seconds
  void _seekForward() {
    final currentPosition =
        flickManager.flickVideoManager!.videoPlayerValue!.position;
    final forwardPosition = currentPosition + const Duration(seconds: 5);
    flickManager.flickControlManager!.seekTo(forwardPosition);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlickVideoProgressBar(
                flickProgressBarSettings: FlickProgressBarSettings(
                  height: 5,
                  handleRadius: 5,
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey[300]!,
                  backgroundColor: Colors.grey,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: flickManager
                          .flickVideoManager!.videoPlayerController!,
                      builder: (context, VideoPlayerValue value, child) {
                        return Text(
                          _formatDuration(value.position),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: flickManager
                          .flickVideoManager!.videoPlayerController!,
                      builder: (context, VideoPlayerValue value, child) {
                        return Text(
                          _formatDuration(value.duration),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _seekBackward,
                      child: Icon(
                        Icons.replay_5,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    FlickSoundToggle(),
                    FlickPlayToggle(),
                    GestureDetector(
                      onTap: _seekForward,
                      child: Icon(
                        Icons.forward_5,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    GestureDetector(
                      onTap: toggleFullscreen,
                      child: Icon(
                        flickManager.flickControlManager!.isFullscreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
