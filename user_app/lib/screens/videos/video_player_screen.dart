import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../providers/user_video_provider.dart';
import '../../core/constants/api_constants.dart';
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
      String finalUrl = widget.video.videoUrl.trim();
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        throw Exception('Invalid or missing video URL: "$finalUrl"');
      }
      Uri uri = Uri.parse(finalUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();

      _controller.addListener(_videoListener);

      if (resumePos > 0 && resumePos < _controller.value.duration.inSeconds) {
        await _controller.seekTo(Duration(seconds: resumePos));
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('Video Player error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
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

          // Save absolute position (not elapsed delta) so resume is always accurate
          _savePosition(currentSecs);
        }
      } else {
        _lastPlayTimestamp = now;
      }
    } else {
      if (_lastPlayTimestamp != null) {
        // Paused — save current position immediately
        _savePosition(currentSecs);
        _lastPlayTimestamp = null;
      }
    }
  }

  /// Saves the absolute playback position to both the session ping and progress API.
  void _savePosition(int absolutePositionSecs) {
    if (!mounted) return;

    // 1. Session ping with absolute position
    if (_sessionId != null) {
      _apiClient.post('/sessions/ping/$_sessionId', {
        'watchSeconds': absolutePositionSecs,
        'lastPositionSecs': absolutePositionSecs,
      });
    }

    // 2. Direct progress save with absolute position (bypasses heartbeat delta issues)
    _apiClient.post(
      ApiConstants.recordVideoProgress(widget.video.id),
      {'watchedSecs': absolutePositionSecs},
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      final currentSecs = _controller.value.position.inSeconds;

      // Always save final position on exit (back button, fullscreen exit, etc.)
      if (currentSecs > 0) {
        _savePosition(currentSecs);
      }

      if (_sessionId != null) {
        _apiClient.post('/sessions/end/$_sessionId', {
          'closedNormally': true,
          'lastPositionSecs': currentSecs,
        });
      }

      _controller.removeListener(_videoListener);
      _controller.dispose();
    }
    // Restore portrait + system UI on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
                        : YouTubeStyleVideoPlayer(
                            controller: _controller,
                            title: widget.video.title,
                            onEnterFullScreen: _enterFullScreen,
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
                          color: AppTheme.neonCyan.withValues(alpha: 0.15),
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
                            color: AppTheme.neonGreen.withValues(alpha: 0.15),
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

  /// Push a dedicated fullscreen route; the controller is shared so playback continues.
  /// If the user taps the back arrow inside fullscreen, the route returns `true`
  /// and we also pop VideoPlayerScreen to land back on the Video Learning Hub.
  void _enterFullScreen() async {
    final shouldPopToHub = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenVideoPage(
          controller: _controller,
          title: widget.video.title,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );

    // Back arrow in fullscreen returns true → also exit the video player
    if ((shouldPopToHub == true) && mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated Full-Screen Page (pushed as a new route)
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;

  const _FullScreenVideoPage({required this.controller, required this.title});

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  @override
  void initState() {
    super.initState();
    // Force landscape + hide all system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restore portrait + system UI when leaving fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: YouTubeStyleVideoPlayer(
        controller: widget.controller,
        title: widget.title,
        isFullScreen: true,
        // ⛶ exit icon → just exit fullscreen, stay on video player
        onExitFullScreen: () => Navigator.of(context).pop(),
        // ← back arrow → exit fullscreen AND video player → back to Hub
        onBackToHub: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YouTube-Style Video Player Widget
// ─────────────────────────────────────────────────────────────────────────────
class YouTubeStyleVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final bool isFullScreen;
  final VoidCallback? onEnterFullScreen;
  final VoidCallback? onExitFullScreen;
  /// Called when the top-left back arrow is tapped in fullscreen — go all the way back to hub
  final VoidCallback? onBackToHub;

  const YouTubeStyleVideoPlayer({
    super.key,
    required this.controller,
    required this.title,
    this.isFullScreen = false,
    this.onEnterFullScreen,
    this.onExitFullScreen,
    this.onBackToHub,
  });

  @override
  State<YouTubeStyleVideoPlayer> createState() => _YouTubeStyleVideoPlayerState();
}

class _YouTubeStyleVideoPlayerState extends State<YouTubeStyleVideoPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;
  double _currentSpeed = 1.0;
  String? _gestureNotice;
  Timer? _gestureNoticeTimer;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _gestureNoticeTimer?.cancel();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _seekRelative(int seconds) async {
    final current = widget.controller.value.position;
    final target = current + Duration(seconds: seconds);
    final duration = widget.controller.value.duration;

    Duration finalPos = target;
    if (finalPos < Duration.zero) finalPos = Duration.zero;
    if (finalPos > duration) finalPos = duration;

    await widget.controller.seekTo(finalPos);
    _showNotice(seconds > 0 ? '+$seconds Sec' : '$seconds Sec');
  }

  void _showNotice(String text) {
    _gestureNoticeTimer?.cancel();
    setState(() {
      _gestureNotice = text;
    });
    _gestureNoticeTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _gestureNotice = null;
        });
      }
    });
  }

  void _togglePlayPause() {
    final value = widget.controller.value;
    final isEnded = value.position >= value.duration;

    if (isEnded) {
      widget.controller.seekTo(Duration.zero);
      widget.controller.play();
    } else if (value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    _startHideTimer();
  }

  void _openSpeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Playback Speed',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              ..._speeds.map((speed) {
                final isSelected = _currentSpeed == speed;
                return ListTile(
                  title: Text(
                    speed == 1.0 ? 'Normal (1.0x)' : '${speed}x',
                    style: GoogleFonts.outfit(
                      color: isSelected ? AppTheme.neonCyan : AppTheme.lightText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, color: AppTheme.neonCyan) : null,
                  onTap: () {
                    setState(() {
                      _currentSpeed = speed;
                    });
                    widget.controller.setPlaybackSpeed(speed);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _handleFullScreenToggle() {
    if (widget.isFullScreen) {
      // Bottom-right icon: just exit fullscreen, stay on video player
      widget.onExitFullScreen?.call();
    } else {
      widget.onEnterFullScreen?.call();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final isEnded = value.isInitialized && value.position >= value.duration && value.duration > Duration.zero;

    // In fullscreen mode: fill entire screen. In normal mode: AspectRatio box.
    final playerContent = GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Video fills the container
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: value.isInitialized ? value.size.width : 1920,
                height: value.isInitialized ? value.size.height : 1080,
                child: VideoPlayer(widget.controller),
              ),
            ),
          ),

          // 2. Double-tap gesture zones (Left = -10s, Right = +10s)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () => _seekRelative(-10),
                    child: Container(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () => _seekRelative(10),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),

          // 3. Gesture notice overlay
          if (_gestureNotice != null)
            AnimatedOpacity(
              opacity: _gestureNotice != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _gestureNotice!.contains('+') ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _gestureNotice!,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Controls overlay
          if (_showControls || !value.isPlaying || isEnded)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
                    stops: [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Row(
                        children: [
                          // Back/exit button in fullscreen
                          if (widget.isFullScreen)
                            GestureDetector(
                              // ← Back arrow: go all the way back to Video Learning Hub
                              onTap: () => widget.onBackToHub?.call(),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: widget.isFullScreen ? 15 : 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Speed Selector Badge
                          GestureDetector(
                            onTap: _openSpeedSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _currentSpeed == 1.0 ? '1.0x' : '${_currentSpeed}x',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Playback Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: widget.isFullScreen ? 42 : 36,
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                          onPressed: () => _seekRelative(-10),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: widget.isFullScreen ? 52 : 44,
                            icon: Icon(
                              isEnded
                                  ? Icons.replay_rounded
                                  : (value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              color: Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          iconSize: widget.isFullScreen ? 42 : 36,
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                          onPressed: () => _seekRelative(10),
                        ),
                      ],
                    ),

                    // Bottom Bar (Progress + Timestamps + Fullscreen Toggle)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            widget.controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppTheme.primaryPurple,
                              bufferedColor: Colors.white30,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: widget.isFullScreen ? 13 : 11),
                              ),
                              GestureDetector(
                                onTap: _handleFullScreenToggle,
                                child: Icon(
                                  widget.isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: widget.isFullScreen ? 28 : 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    // Fullscreen: fill entire scaffold body, no aspect ratio constraint
    if (widget.isFullScreen) {
      return Container(
        color: Colors.black,
        child: playerContent,
      );
    }

    // Normal mode: constrain to 16:9 aspect ratio
    return AspectRatio(
      aspectRatio: value.isInitialized && value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
      child: playerContent,
    );
  }
}
