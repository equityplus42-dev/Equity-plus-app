import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../providers/user_video_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quality options with their Cloudinary transformation strings
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kVideoQualities = ['Auto', '1080p', '720p', '480p', '360p', '240p'];
const List<double> kVideoSpeeds   = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

/// Builds the final Cloudinary URL for a given quality label.
/// - 'Auto' on native  → HLS adaptive (.m3u8, sp_hd streaming profile)
/// - 'Auto' on web     → q_auto,f_auto optimised MP4 (Chrome has no native HLS)
/// - '720p' etc.       → resolution-capped q_auto MP4
String buildQualityUrl(String originalUrl, String quality) {
  if (!originalUrl.contains('res.cloudinary.com')) return originalUrl;

  final uri = Uri.parse(originalUrl);
  final pathParts = uri.path.split('/');

  // Find '/upload/' index in the path
  final uploadIdx = pathParts.indexOf('upload');
  if (uploadIdx == -1) return originalUrl;

  // Parts before and after /upload/
  final before = pathParts.sublist(0, uploadIdx + 1).join('/');
  var after  = pathParts.sublist(uploadIdx + 1);

  // Strip optional version segment (e.g. 'v1720000000')
  if (after.isNotEmpty &&
      after[0].startsWith('v') &&
      int.tryParse(after[0].substring(1)) != null) {
    after = after.sublist(1);
  }

  final publicId = after.join('/');            // e.g. 'videos/myvideo.mp4'
  final base     = '${uri.scheme}://${uri.host}$before';

  switch (quality) {
    case 'Auto':
      if (kIsWeb) {
        // Web (Chrome) – no native HLS, use Cloudinary auto-optimised MP4
        return '$base/q_auto,f_auto/$publicId';
      } else {
        // Native – serve HLS adaptive bitrate
        final hlsId = publicId.replaceAll(RegExp(r'\.[^.]+$'), '.m3u8');
        return '$base/sp_hd/$hlsId';
      }
    case '1080p': return '$base/w_1920,h_1080,c_limit,q_auto/$publicId';
    case '720p':  return '$base/w_1280,h_720,c_limit,q_auto/$publicId';
    case '480p':  return '$base/w_854,h_480,c_limit,q_auto/$publicId';
    case '360p':  return '$base/w_640,h_360,c_limit,q_auto/$publicId';
    case '240p':  return '$base/w_426,h_240,c_limit,q_auto/$publicId';
    default:      return originalUrl;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoPlayerScreen
// ─────────────────────────────────────────────────────────────────────────────
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
  bool _hasError      = false;

  DateTime? _lastPlayTimestamp;
  String?   _sessionId;

  // ── Quality & Speed state (shared with fullscreen) ─────────────────────────
  String _currentQuality = 'Auto';
  double _currentSpeed   = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeVideoAndSession();
  }

  // ── Initialise controller ─────────────────────────────────────────────────
  Future<void> _initializeVideoAndSession() async {
    try {
      // 1. Cross-device resume position
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
        if (sessRes['data'] != null) _sessionId = sessRes['data']['sessionId'];
      } catch (_) {}

      // 3. Initialise controller at current quality
      await _createController(
        buildQualityUrl(widget.video.videoUrl.trim(), _currentQuality),
        resumePos: resumePos,
        autoPlay: true,
      );
    } catch (e) {
      debugPrint('Video Player init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _createController(
    String url, {
    int resumePos = 0,
    bool autoPlay = false,
  }) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw Exception('Invalid or missing video URL: "$url"');
    }
    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await _controller.initialize();
    _controller.addListener(_videoListener);
    await _controller.setPlaybackSpeed(_currentSpeed);

    if (resumePos > 0 && resumePos < _controller.value.duration.inSeconds) {
      await _controller.seekTo(Duration(seconds: resumePos));
    }
    if (mounted) {
      setState(() => _isInitialized = true);
      if (autoPlay) _controller.play();
    }
  }

  // ── Quality switching (preserve position + playing state) ─────────────────
  Future<void> _switchQuality(String quality) async {
    if (!_isInitialized || _currentQuality == quality) return;

    final savedPos    = _controller.value.position;
    final wasPlaying  = _controller.value.isPlaying;

    setState(() {
      _isInitialized  = false;
      _currentQuality = quality;
    });

    _controller.removeListener(_videoListener);
    await _controller.dispose();

    try {
      final url = buildQualityUrl(widget.video.videoUrl.trim(), quality);
      await _createController(url, resumePos: savedPos.inSeconds);
      if (wasPlaying && mounted) _controller.play();
    } catch (e) {
      debugPrint('Quality switch error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  // ── Speed change ──────────────────────────────────────────────────────────
  Future<void> _setSpeed(double speed) async {
    setState(() => _currentSpeed = speed);
    if (_isInitialized) await _controller.setPlaybackSpeed(speed);
  }

  // ── Playback position save ─────────────────────────────────────────────────
  void _videoListener() {
    if (!_controller.value.isInitialized) return;
    final isPlaying  = _controller.value.isPlaying;
    final now        = DateTime.now();
    final currentSecs = _controller.value.position.inSeconds;

    if (isPlaying) {
      if (_lastPlayTimestamp != null) {
        if (now.difference(_lastPlayTimestamp!).inSeconds >= 5) {
          _lastPlayTimestamp = now;
          _savePosition(currentSecs);
        }
      } else {
        _lastPlayTimestamp = now;
      }
    } else {
      if (_lastPlayTimestamp != null) {
        _savePosition(currentSecs);
        _lastPlayTimestamp = null;
      }
    }
  }

  void _savePosition(int absolutePositionSecs) {
    if (!mounted) return;
    if (_sessionId != null) {
      _apiClient.post('/sessions/ping/$_sessionId', {
        'watchSeconds': absolutePositionSecs,
        'lastPositionSecs': absolutePositionSecs,
      });
    }
    _apiClient.post(
      ApiConstants.recordVideoProgress(widget.video.id),
      {'watchedSecs': absolutePositionSecs},
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      final currentSecs = _controller.value.position.inSeconds;
      if (currentSecs > 0) _savePosition(currentSecs);
      if (_sessionId != null) {
        _apiClient.post('/sessions/end/$_sessionId', {
          'closedNormally': true,
          'lastPositionSecs': currentSecs,
        });
      }
      _controller.removeListener(_videoListener);
      _controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ── Cloudinary Settings Sheet (Quality + Speed) ─────────────────────────────
  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16152A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 38, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Quality Section ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.hd_rounded, color: AppTheme.neonCyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Quality',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.neonCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentQuality,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ...kVideoQualities.map((q) {
                    final selected = _currentQuality == q;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                      leading: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppTheme.neonCyan : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 9, height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.neonCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        q == 'Auto'
                            ? (kIsWeb ? 'Auto (Optimized)' : 'Auto (HLS Adaptive)')
                            : q,
                        style: GoogleFonts.outfit(
                          color: selected ? AppTheme.neonCyan : Colors.white,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: q == 'Auto'
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                kIsWeb ? 'BEST' : 'HLS',
                                style: GoogleFonts.outfit(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _switchQuality(q);
                      },
                    );
                  }),

                  const SizedBox(height: 8),

                  // ── Speed Section ────────────────────────────────────────
                  const Divider(height: 1, color: Colors.white10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                    child: Row(
                      children: [
                        const Icon(Icons.speed_rounded, color: AppTheme.primaryPurple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Playback Speed',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentSpeed == 1.0 ? 'Normal' : '${_currentSpeed}×',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ...kVideoSpeeds.map((speed) {
                    final selected = _currentSpeed == speed;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                      leading: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppTheme.primaryPurple : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 9, height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryPurple,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        speed == 1.0 ? 'Normal (1.0×)' : '${speed}×',
                        style: GoogleFonts.outfit(
                          color: selected ? AppTheme.primaryPurple : Colors.white,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        setSheet(() {});
                        _setSpeed(speed);
                        // Don't pop — let user pick quality and speed in one go
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Fullscreen navigation ─────────────────────────────────────────────────
  void _enterFullScreen() async {
    final shouldPopToHub = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullScreenVideoPage(
          controller: _controller,
          title: widget.video.title,
          currentQuality: _currentQuality,
          currentSpeed: _currentSpeed,
          onOpenSettings: _openSettingsSheet,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if ((shouldPopToHub == true) && mounted) Navigator.of(context).pop();
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
                    ? _buildErrorWidget()
                    : !_isInitialized
                        ? const CircularProgressIndicator(color: AppTheme.primaryPurple)
                        : CloudinaryVideoPlayer(
                            controller: _controller,
                            title: widget.video.title,
                            currentQuality: _currentQuality,
                            currentSpeed: _currentSpeed,
                            onOpenSettings: _openSettingsSheet,
                            onEnterFullScreen: _enterFullScreen,
                          ),
              ),
            ),
            _buildInfoPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
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
    );
  }

  Widget _buildInfoPanel() {
    final videoProvider = Provider.of<UserVideoProvider>(context);
    final snapshot = videoProvider.snapshot;
    final progress = videoProvider.progress;

    return Container(
      width: double.infinity,
      color: AppTheme.cardBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Title & Badges
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
                _badge(widget.video.languageName, AppTheme.neonCyan),
                if (widget.video.isCompleted) ...[
                  const SizedBox(width: 8),
                  _badge('COMPLETED', AppTheme.neonGreen),
                ],
              ],
            ),
            if (widget.video.description != null && widget.video.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.video.description!,
                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.softGrey),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            // 1. Assigned Language & Snapshot Card with Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.language, color: AppTheme.primaryPurple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASSIGNED LANGUAGE & SNAPSHOT',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.softGrey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              videoProvider.assignedLanguageName ?? widget.video.languageName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Progress', '${(progress?.percentage ?? 0.0).toStringAsFixed(1)}%', AppTheme.neonCyan),
                      _buildStatItem('Remaining', '${(progress?.remainingPercentage ?? 100.0).toStringAsFixed(1)}%', AppTheme.primaryPink),
                      _buildStatItem('Unlocked', '${videoProvider.unlockedVideos.length} / ${videoProvider.allVideos.length}', AppTheme.neonGreen),
                      _buildStatItem('To 25% Limit', progress?.remainingSecsLabel ?? '0s', Colors.amberAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Refund Eligibility Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (snapshot?.refundEligible ?? true)
                    ? AppTheme.neonGreen.withValues(alpha: 0.08)
                    : Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (snapshot?.refundEligible ?? true)
                      ? AppTheme.neonGreen.withValues(alpha: 0.3)
                      : Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (snapshot?.refundEligible ?? true) ? Icons.verified_user_outlined : Icons.report_problem_outlined,
                            color: (snapshot?.refundEligible ?? true) ? AppTheme.neonGreen : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'REFUND ELIGIBILITY STATUS',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: (snapshot?.refundEligible ?? true) ? AppTheme.neonGreen : Colors.redAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: (snapshot?.refundEligible ?? true) ? AppTheme.neonGreen : Colors.redAccent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          (snapshot?.refundEligible ?? true) ? 'ELIGIBLE' : 'NOT ELIGIBLE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (snapshot?.refundEligible ?? true)
                        ? 'You are eligible for a refund. Watching 25% or more of your snapshot content (${(progress?.percentage ?? 0.0).toStringAsFixed(1)}% watched) or completing 30 days will void eligibility.'
                        : 'Refund eligibility is permanently void (25%+ duration progress reached or 30 days completed).',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.lightText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppTheme.softGrey,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedicated Full-Screen Page
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final String currentQuality;
  final double currentSpeed;
  final VoidCallback onOpenSettings;

  const _FullScreenVideoPage({
    required this.controller,
    required this.title,
    required this.currentQuality,
    required this.currentSpeed,
    required this.onOpenSettings,
  });

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CloudinaryVideoPlayer(
        controller: widget.controller,
        title: widget.title,
        isFullScreen: true,
        currentQuality: widget.currentQuality,
        currentSpeed: widget.currentSpeed,
        onOpenSettings: widget.onOpenSettings,
        onExitFullScreen: () => Navigator.of(context).pop(),
        onBackToHub: () => Navigator.of(context).pop(true),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Cloudinary Video Player Widget ──
// ─────────────────────────────────────────────────────────────────────────────
class CloudinaryVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final bool isFullScreen;
  final String currentQuality;
  final double currentSpeed;
  final VoidCallback onOpenSettings;
  final VoidCallback? onEnterFullScreen;
  final VoidCallback? onExitFullScreen;
  final VoidCallback? onBackToHub;

  const CloudinaryVideoPlayer({
    super.key,
    required this.controller,
    required this.title,
    required this.currentQuality,
    required this.currentSpeed,
    required this.onOpenSettings,
    this.isFullScreen = false,
    this.onEnterFullScreen,
    this.onExitFullScreen,
    this.onBackToHub,
  });

  @override
  State<CloudinaryVideoPlayer> createState() => _CloudinaryVideoPlayerState();
}

class _CloudinaryVideoPlayerState extends State<CloudinaryVideoPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;
  String? _gestureNotice;
  Timer? _gestureNoticeTimer;

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
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _seekRelative(int seconds) async {
    final current  = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    Duration target = current + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    await widget.controller.seekTo(target);
    _showNotice(seconds > 0 ? '+$seconds Sec' : '$seconds Sec');
  }

  void _showNotice(String text) {
    _gestureNoticeTimer?.cancel();
    setState(() => _gestureNotice = text);
    _gestureNoticeTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _gestureNotice = null);
    });
  }

  void _togglePlayPause() {
    final value  = widget.controller.value;
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

  void _handleFullScreenToggle() {
    if (widget.isFullScreen) {
      widget.onExitFullScreen?.call();
    } else {
      widget.onEnterFullScreen?.call();
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return d.inHours > 0 ? '${two(d.inHours)}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value   = widget.controller.value;
    final isEnded = value.isInitialized &&
        value.position >= value.duration &&
        value.duration > Duration.zero;

    final playerContent = GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Video frame
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width:  value.isInitialized ? value.size.width  : 1920,
                height: value.isInitialized ? value.size.height : 1080,
                child: VideoPlayer(widget.controller),
              ),
            ),
          ),

          // 2. Double-tap seek zones
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

          // 3. Seek notice
          if (_gestureNotice != null)
            AnimatedOpacity(
              opacity: 1.0,
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
                      _gestureNotice!.contains('+')
                          ? Icons.fast_forward_rounded
                          : Icons.fast_rewind_rounded,
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
                    // ── Top Bar ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          if (widget.isFullScreen)
                            GestureDetector(
                              onTap: () => widget.onBackToHub?.call(),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          const SizedBox(width: 6),
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
                          // Quality + Speed badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            child: Text(
                              '${widget.currentQuality}  •  '
                              '${widget.currentSpeed == 1.0 ? '1×' : '${widget.currentSpeed}×'}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ⚙ Settings gear (opens Quality + Speed sheet)
                          GestureDetector(
                            onTap: widget.onOpenSettings,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Center Playback Buttons ────────────────────────────
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

                    // ── Bottom Bar (Progress + Timestamps + Fullscreen) ────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            widget.controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor:     AppTheme.primaryPurple,
                              bufferedColor:   Colors.white30,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: widget.isFullScreen ? 13 : 11,
                                ),
                              ),
                              GestureDetector(
                                onTap: _handleFullScreenToggle,
                                child: Icon(
                                  widget.isFullScreen
                                      ? Icons.fullscreen_exit_rounded
                                      : Icons.fullscreen_rounded,
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

    if (widget.isFullScreen) {
      return Container(color: Colors.black, child: playerContent);
    }
    return AspectRatio(
      aspectRatio: value.isInitialized && value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
      child: playerContent,
    );
  }
}
