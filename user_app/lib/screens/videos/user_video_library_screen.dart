// dart:ui removed — no longer needed after removing locked video blur cards
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/user_video_provider.dart';
import '../../widgets/disclaimer_dialog.dart';
import 'video_player_screen.dart';
import '../../core/theme/app_theme.dart';

class UserVideoLibraryScreen extends StatefulWidget {
  const UserVideoLibraryScreen({super.key});

  @override
  State<UserVideoLibraryScreen> createState() => _UserVideoLibraryScreenState();
}

class _UserVideoLibraryScreenState extends State<UserVideoLibraryScreen> {
  bool _checkedDisclaimer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkDisclaimerAndLoad();
    });
  }

  Future<void> _checkDisclaimerAndLoad() async {
    final provider = Provider.of<UserVideoProvider>(context, listen: false);
    await provider.fetchUserVideos();

    if (!mounted) return;

    if (!provider.isDisclaimerAccepted || provider.disclaimerNeedsReacceptance) {
      final accepted = await DisclaimerDialog.show(context);
      if (!accepted && mounted) {
        Navigator.of(context).pop(); // Opt out automatically
        return;
      }
    }

    if (mounted) {
      setState(() {
        _checkedDisclaimer = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<UserVideoProvider>(context);
    final snapshot = videoProvider.snapshot;
    final progress = videoProvider.progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Learning Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppTheme.neonCyan),
            tooltip: 'Watch History & Progress',
            onPressed: () {
              Navigator.pushNamed(context, '/watch-history');
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: !_checkedDisclaimer || videoProvider.isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : RefreshIndicator(
                onRefresh: () => videoProvider.fetchUserVideos(),
                color: AppTheme.primaryPurple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Snapshot & Language Banner
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPurple.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.language, color: AppTheme.primaryPurple, size: 24),
                                ),
                                const SizedBox(width: 14),
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
                                        videoProvider.assignedLanguageName ?? 'English (Default)',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.lightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.swap_horiz, size: 16, color: AppTheme.neonCyan),
                                  label: Text('Change', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/language-request');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),

                            // Progress Metrics Row
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

                      const SizedBox(height: 20),

                      // Refund Status Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (snapshot?.refundEligible ?? true)
                              ? AppTheme.neonGreen.withOpacity(0.08)
                              : Colors.redAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (snapshot?.refundEligible ?? true)
                                ? AppTheme.neonGreen.withOpacity(0.3)
                                : Colors.redAccent.withOpacity(0.3),
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
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'REFUND ELIGIBILITY STATUS',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: (snapshot?.refundEligible ?? true) ? AppTheme.neonGreen : Colors.redAccent,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (snapshot?.refundEligible ?? true) ? AppTheme.neonGreen : Colors.redAccent,
                                    borderRadius: BorderRadius.circular(20),
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
                            const SizedBox(height: 10),
                            Text(
                              (snapshot?.refundEligible ?? true)
                                  ? 'You are eligible for a refund. Watching 25% or more of your snapshot content (${(progress?.percentage ?? 0.0).toStringAsFixed(1)}% watched) or completing 30 days will void eligibility.'
                                  : 'Refund eligibility is permanently void (25%+ duration progress reached or 30 days completed).',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Unlocked Videos Section
                      Text(
                        'COURSE VIDEOS (${videoProvider.unlockedVideos.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),

                      videoProvider.unlockedVideos.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 30.0),
                                child: Column(
                                  children: [
                                    const Icon(Icons.video_library_outlined, size: 50, color: AppTheme.softGrey),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Videos in Snapshot',
                                      style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: videoProvider.unlockedVideos.length,
                              itemBuilder: (context, index) {
                                final v = videoProvider.unlockedVideos[index];
                                final progress = v.duration > 0
                                    ? (v.watchedSecs / v.duration).clamp(0.0, 1.0)
                                    : 0.0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: AppTheme.glassCardDecoration(),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VideoPlayerScreen(video: v),
                                          ),
                                        ).then((_) {
                                          videoProvider.fetchUserVideos();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: v.isCompleted
                                                        ? AppTheme.neonGreen.withOpacity(0.15)
                                                        : AppTheme.primaryPurple.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    v.isCompleted ? Icons.check_circle : Icons.play_circle_fill,
                                                    color: v.isCompleted ? AppTheme.neonGreen : AppTheme.primaryPurple,
                                                    size: 26,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        v.title,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.lightText,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        () {
                                                          String fmt(int secs) {
                                                            if (secs >= 60) {
                                                              final m = secs ~/ 60;
                                                              final s = secs % 60;
                                                              return '${m}m ${s.toString().padLeft(2, '0')}s';
                                                            }
                                                            return '${secs}s';
                                                          }
                                                          final effTotal = v.duration > 0 ? v.duration : (v.watchedSecs > 0 ? v.watchedSecs : 0);
                                                          if (v.watchedSecs > 0) {
                                                            return 'Watched ${fmt(v.watchedSecs)} of ${fmt(effTotal)}';
                                                          }
                                                          return effTotal > 0 ? '${fmt(effTotal)} duration' : 'Video';
                                                        }(),
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 12,
                                                          color: AppTheme.softGrey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.softGrey),
                                              ],
                                            ),
                                            if (v.watchedSecs > 0) ...[
                                              const SizedBox(height: 10),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: Colors.white10,
                                                  color: v.isCompleted ? AppTheme.neonGreen : AppTheme.primaryPurple,
                                                  minHeight: 3,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      if (videoProvider.lockedVideos.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'LOCKED VIDEOS (${videoProvider.lockedVideos.length})',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: videoProvider.lockedVideos.length,
                          itemBuilder: (context, index) {
                            final lv = videoProvider.lockedVideos[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.lock, color: Colors.amber, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lv.title,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.lightText.withOpacity(0.7),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'LOCKED',
                                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lv.unlockNotice.isNotEmpty ? lv.unlockNotice : 'Unlocks after 25% learning progress or 30 days.',
                                          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
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
}
