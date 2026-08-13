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
  if (originalUrl.isEmpty) return originalUrl;

  // Cloudflare Stream adaptive HLS URLs
  if (originalUrl.contains('cloudflarestream.com')) {
    return originalUrl;
  }

  // Cloudflare R2 Storage direct video URLs
  if (originalUrl.contains('.r2.cloudflarestorage.com') || originalUrl.contains('.r2.dev')) {
    return originalUrl;
  }

  // Cloudinary URL transformation
  if (originalUrl.contains('res.cloudinary.com')) {
    final uri = Uri.parse(originalUrl);
    final pathParts = uri.path.split('/');

    final uploadIdx = pathParts.indexOf('upload');
    if (uploadIdx == -1) return originalUrl;

    final before = pathParts.sublist(0, uploadIdx + 1).join('/');
    var after  = pathParts.sublist(uploadIdx + 1);

    if (after.isNotEmpty &&
        after[0].startsWith('v') &&
        int.tryParse(after[0].substring(1)) != null) {
      after = after.sublist(1);
    }

    final publicId = after.join('/');
    final base     = '${uri.scheme}://${uri.host}$before';

    switch (quality) {
      case 'Auto':  return '$base/q_auto,f_auto/$publicId';
      case '1080p': return '$base/w_1920,h_1080,c_limit,q_auto/$publicId';
      case '720p':  return '$base/w_1280,h_720,c_limit,q_auto/$publicId';
      case '480p':  return '$base/w_854,h_480,c_limit,q_auto/$publicId';
      case '360p':  return '$base/w_640,h_360,c_limit,q_auto/$publicId';
      case '240p':  return '$base/w_426,h_240,c_limit,q_auto/$publicId';
      default:      return originalUrl;
    }
  }

  return originalUrl;
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

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller.initialize();
    } catch (e) {
      if (url != widget.video.videoUrl && widget.video.videoUrl.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
        await _controller.initialize();
      } else {
        rethrow;
      }
    }

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
                            _currentSpeed == 1.0 ? 'Normal' : '$_currentSpeed×',
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
                        speed == 1.0 ? 'Normal (1.0×)' : '$speed×',
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
            _hasError
                ? SizedBox(height: 230, child: Center(child: _buildErrorWidget()))
                : !_isInitialized
                    ? const SizedBox(
                        height: 230,
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
                      )
                    : CloudinaryVideoPlayer(
                        controller: _controller,
                        title: widget.video.title,
                        currentQuality: _currentQuality,
                        currentSpeed: _currentSpeed,
                        onOpenSettings: _openSettingsSheet,
                        onEnterFullScreen: _enterFullScreen,
                      ),
            Expanded(
              child: _buildInfoPanel(),
            ),
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

  int _selectedTabIndex = 0;

  Widget _buildInfoPanel() {
    final videoProvider = Provider.of<UserVideoProvider>(context);
    final snapshot = videoProvider.snapshot;
    final progress = videoProvider.progress;
    final isRefundEligible = snapshot?.refundEligible ?? true;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0E17),
      child: Column(
        children: [
          // ── Header: Title & Compact Status Badges ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.video.title,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniChip(widget.video.languageName, AppTheme.neonCyan, Icons.language_rounded),
                    if (widget.video.isCompleted) ...[
                      const SizedBox(width: 8),
                      _miniChip('Completed', AppTheme.neonGreen, Icons.check_circle_rounded),
                    ],
                    const SizedBox(width: 8),
                    // Sleek Refund Status Pill (Tapping opens Policy Sheet)
                    GestureDetector(
                      onTap: () => _showRefundPolicySheet(context, snapshot, progress),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isRefundEligible ? AppTheme.neonGreen : Colors.redAccent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isRefundEligible ? AppTheme.neonGreen : Colors.redAccent).withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRefundEligible ? Icons.verified_user_rounded : Icons.report_problem_rounded,
                              color: isRefundEligible ? AppTheme.neonGreen : Colors.redAccent,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isRefundEligible ? 'Refund Eligible' : 'Refund Void',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isRefundEligible ? AppTheme.neonGreen : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Segmented Tab Selector ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Row(
              children: [
                _buildTabPill(0, 'Overview', Icons.description_outlined),
                _buildTabPill(1, 'Progress', Icons.analytics_outlined),
                _buildTabPill(2, 'Playlist (${videoProvider.allVideos.length})', Icons.playlist_play_rounded),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Tab Content Container ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildSelectedTabContent(videoProvider, snapshot, progress),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar Helper Pill ───────────────────────────────────────────────────
  Widget _buildTabPill(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Content Router ────────────────────────────────────────────────────
  Widget _buildSelectedTabContent(UserVideoProvider videoProvider, dynamic snapshot, dynamic progress) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(videoProvider);
      case 1:
        return _buildProgressTab(videoProvider, snapshot, progress);
      case 2:
        return _buildPlaylistTab(videoProvider);
      default:
        return _buildOverviewTab(videoProvider);
    }
  }

  // ── Tab 0: Overview ───────────────────────────────────────────────────────
  Widget _buildOverviewTab(UserVideoProvider videoProvider) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.video.description != null && widget.video.description!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this Video',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonCyan,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.video.description!,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Metadata grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _buildMetaRow(
                Icons.language_rounded,
                'Assigned Language',
                videoProvider.assignedLanguageName ?? widget.video.languageName,
                AppTheme.neonCyan,
              ),
              const Divider(color: Colors.white10, height: 18),
              _buildMetaRow(
                Icons.folder_special_rounded,
                'Snapshot Folder Videos',
                '${videoProvider.allVideos.length} Videos Total',
                AppTheme.primaryPurple,
              ),
              const Divider(color: Colors.white10, height: 18),
              _buildMetaRow(
                Icons.timer_outlined,
                'Watched Duration',
                '${widget.video.watchedSecs} sec watched',
                AppTheme.neonGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Progress & Refund ──────────────────────────────────────────────
  Widget _buildProgressTab(UserVideoProvider videoProvider, dynamic snapshot, dynamic progress) {
    final double percentage = progress?.percentage ?? 0.0;
    final isRefundEligible = snapshot?.refundEligible ?? true;

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 25% Threshold Progress Bar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WATCH PROGRESS',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonCyan,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: percentage >= 25.0 ? Colors.amberAccent : AppTheme.neonCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Visual Progress Bar with 25% threshold marker
              Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (percentage / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.neonCyan],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ),
                  // 25% threshold indicator dot
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.25 - 20,
                    top: 0, bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0%', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                  Text('25% Refund Limit', style: GoogleFonts.outfit(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  Text('100%', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4 Stat Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            _buildStatCard('Total Progress', '${percentage.toStringAsFixed(1)}%', AppTheme.neonCyan, Icons.pie_chart_rounded),
            _buildStatCard('Remaining Allowed', '${(progress?.remainingPercentage ?? 100.0).toStringAsFixed(1)}%', AppTheme.primaryPink, Icons.timelapse_rounded),
            _buildStatCard('Unlocked Videos', '${videoProvider.unlockedVideos.length} / ${videoProvider.allVideos.length}', AppTheme.neonGreen, Icons.lock_open_rounded),
            _buildStatCard('Time to 25% Limit', progress?.remainingSecsLabel ?? '0s', Colors.amberAccent, Icons.hourglass_bottom_rounded),
          ],
        ),

        const SizedBox(height: 14),

        // Compact Refund Policy Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (isRefundEligible ? AppTheme.neonGreen : Colors.redAccent).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isRefundEligible ? AppTheme.neonGreen : Colors.redAccent).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isRefundEligible ? Icons.shield_outlined : Icons.shield_moon_outlined,
                color: isRefundEligible ? AppTheme.neonGreen : Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRefundEligible ? 'Refund Guarantee Active' : 'Refund Policy Voided',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isRefundEligible ? AppTheme.neonGreen : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRefundEligible
                          ? 'Watching under 25% total duration keeps your 30-day money-back guarantee.'
                          : 'You have watched 25%+ of content or 30 days completed.',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                onPressed: () => _showRefundPolicySheet(context, snapshot, progress),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Playlist / Up Next ─────────────────────────────────────────────
  Widget _buildPlaylistTab(UserVideoProvider videoProvider) {
    final allVideos = videoProvider.allVideos;

    if (allVideos.isEmpty) {
      return Center(
        key: const ValueKey(2),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No other videos available in this folder.',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'FOLDER PLAYLIST',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.neonCyan,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allVideos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final v = allVideos[idx];
            final isCurrent = v.id == widget.video.id;

            return GestureDetector(
              onTap: () {
                if (!isCurrent) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: v)),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent ? AppTheme.primaryPurple : Colors.white10,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.primaryPurple
                            : Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCurrent
                            ? Icons.play_arrow_rounded
                            : (v.isCompleted ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.title,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? AppTheme.neonCyan : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCurrent
                                ? 'Now Playing'
                                : '${v.duration > 0 ? '${(v.duration / 60).toStringAsFixed(1)} mins' : 'Video'} • ${v.languageName}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isCurrent ? AppTheme.neonCyan.withValues(alpha: 0.8) : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (v.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DONE',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.neonGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────
  Widget _miniChip(String label, Color color, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      );

  Widget _buildMetaRow(IconData icon, String label, String value, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accentColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)),
              Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 9, color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Sheet for Full Refund Policy Details ────────────────────────────
  void _showRefundPolicySheet(BuildContext context, dynamic snapshot, dynamic progress) {
    final isEligible = snapshot?.refundEligible ?? true;
    final percentage = progress?.percentage ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16152A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    isEligible ? Icons.verified_user_rounded : Icons.report_problem_rounded,
                    color: isEligible ? AppTheme.neonGreen : Colors.redAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Refund Policy Status',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Text(
                isEligible
                    ? '✓ You are currently ELIGIBLE for a full refund.'
                    : '✕ Refund eligibility has been PERMANENTLY VOIDED.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEligible ? AppTheme.neonGreen : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Refund Rules & Terms:\n'
                '• If a user watches less than 25% of total uploaded folder duration within 30 days of joining, they are eligible for a 100% refund.\n'
                '• Reaching 25.0% watch progress (Current: ${percentage.toStringAsFixed(1)}%) or completing 30 days permanently voids refund eligibility.',
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got It', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  late bool _isLandscape;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Calculate aspect ratio: if aspectRatio < 1.0, video is vertical (portrait / 9:16).
    final value = widget.controller.value;
    final double aspectRatio = (value.isInitialized && value.aspectRatio > 0)
        ? value.aspectRatio
        : (value.isInitialized && value.size.height > 0
            ? value.size.width / value.size.height
            : 16 / 9);

    final bool isVertical = aspectRatio < 1.0;
    // Default initial orientation: vertical videos open in portrait, horizontal in landscape.
    _isLandscape = !isVertical;
    _applyOrientation(_isLandscape);
  }

  void _applyOrientation(bool isLandscape) {
    if (isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    _applyOrientation(_isLandscape);
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
        isLandscape: _isLandscape,
        onToggleOrientation: _toggleOrientation,
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
  final bool? isLandscape;
  final String currentQuality;
  final double currentSpeed;
  final VoidCallback onOpenSettings;
  final VoidCallback? onToggleOrientation;
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
    this.isLandscape,
    this.onToggleOrientation,
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
                          if (widget.isFullScreen && widget.onToggleOrientation != null) ...[
                            // Orientation toggle button (Landscape / Portrait)
                            GestureDetector(
                              onTap: widget.onToggleOrientation,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isLandscape == true
                                      ? Icons.screen_lock_portrait_rounded
                                      : Icons.screen_lock_landscape_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
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
                            colors: VideoProgressColors(
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
