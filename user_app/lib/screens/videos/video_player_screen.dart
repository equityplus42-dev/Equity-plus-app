import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/user_video_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final UserVideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ApiClient _apiClient = ApiClient();
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  DateTime? _lastPlayTimestamp;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeVideoAndSession();
  }

  Future<void> _initializeVideoAndSession() async {
    try {
      // 1. Fetch cross-device latest resume position
      int resumePos = widget.video.watchedSecs;
      try {
        final posRes = await _apiClient.get('/sessions/${widget.video.id}/resume');
        if (posRes['data'] != null && posRes['data']['lastPositionSecs'] != null) {
          resumePos = posRes['data']['lastPositionSecs'];
        }
      } catch (_) {}

      // 2. Start Playback Session
      try {
        final sessRes = await _apiClient.post('/sessions/${widget.video.id}/start', {
          'platform': 'FLUTTER_MOBILE',
          'deviceName': 'User Device',
        });
        if (sessRes['data'] != null) {
          _sessionId = sessRes['data']['sessionId'];
        }
      } catch (_) {}

      // 3. Initialize Controller
      Uri uri = Uri.parse(widget.video.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);

      await _controller.initialize();
      _controller.addListener(_videoListener);

      if (resumePos > 0) {
        await _controller.seekTo(Duration(seconds: resumePos));
      }

      setState(() {
        _isInitialized = true;
      });
      _controller.play();
    } catch (e) {
      debugPrint('Video Player error: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;

    final isPlaying = _controller.value.isPlaying;
    final now = DateTime.now();
    final currentSecs = _controller.value.position.inSeconds;

    if (isPlaying) {
      if (_lastPlayTimestamp != null) {
        final elapsed = now.difference(_lastPlayTimestamp!).inSeconds;
        if (elapsed >= 5) {
          _lastPlayTimestamp = now;

          // Heartbeat progress
          Provider.of<UserVideoProvider>(context, listen: false).recordPlaybackHeartbeat(
            widget.video.id,
            elapsed,
          );

          // Ping playback session
          if (_sessionId != null) {
            _apiClient.post('/sessions/ping/$_sessionId', {
              'watchSeconds': elapsed,
              'lastPositionSecs': currentSecs,
            });
          }
        }
      } else {
        _lastPlayTimestamp = now;
      }
    } else {
      if (_lastPlayTimestamp != null) {
        final elapsed = now.difference(_lastPlayTimestamp!).inSeconds;
        if (elapsed > 0) {
          Provider.of<UserVideoProvider>(context, listen: false).recordPlaybackHeartbeat(
            widget.video.id,
            elapsed,
          );
        }
        _lastPlayTimestamp = null;
      }
    }
  }

  @override
  void dispose() {
    if (_sessionId != null && _isInitialized) {
      final currentSecs = _controller.value.position.inSeconds;
      _apiClient.post('/sessions/end/$_sessionId', {
        'closedNormally': true,
        'lastPositionSecs': currentSecs,
      });
    }
    if (_isInitialized) {
      _controller.removeListener(_videoListener);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.video.title,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _hasError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to play video',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.video.videoUrl,
                            style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : !_isInitialized
                        ? const CircularProgressIndicator(color: AppTheme.primaryPurple)
                        : AspectRatio(
                            aspectRatio: _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 16 / 9,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_controller),
                                _VideoControls(controller: _controller),
                              ],
                            ),
                          ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppTheme.cardBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.video.languageName,
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
                        ),
                      ),
                      if (widget.video.isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'COMPLETED',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.neonGreen),
                          ),
                        ),
                      ]
                    ],
                  ),
                  if (widget.video.description != null && widget.video.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.video.description!,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.softGrey),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (widget.controller.value.isPlaying) {
                  widget.controller.pause();
                } else {
                  widget.controller.play();
                }
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppTheme.primaryPurple,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
