import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/user_video_provider.dart';
import '../../core/theme/app_theme.dart';
import 'video_player_screen.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserVideoProvider>(context, listen: false).fetchUserVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<UserVideoProvider>(context);
    final allVideos = videoProvider.allVideos;
    final continueWatching = allVideos.where((v) => v.watchedSecs > 0 && !v.isCompleted).toList();
    final completed = allVideos.where((v) => v.isCompleted).toList();

    int totalWatchedSecs = 0;
    for (final v in allVideos) {
      totalWatchedSecs += v.watchedSecs;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch History & Progress'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: videoProvider.isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.glassCardDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat('Total Watched', '${totalWatchedSecs}s', AppTheme.neonCyan),
                          _buildHeaderStat('In Progress', '${continueWatching.length}', Colors.amberAccent),
                          _buildHeaderStat('Completed', '${completed.length}', AppTheme.neonGreen),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue Watching Section
                    Text(
                      'CONTINUE WATCHING (${continueWatching.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    continueWatching.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('No videos currently in progress.', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: continueWatching.length,
                            itemBuilder: (context, index) {
                              final v = continueWatching[index];
                              return _buildVideoTile(context, v);
                            },
                          ),

                    const SizedBox(height: 24),

                    // Completed Section
                    Text(
                      'COMPLETED VIDEOS (${completed.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    completed.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('No completed videos yet.', style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: completed.length,
                            itemBuilder: (context, index) {
                              final v = completed[index];
                              return _buildVideoTile(context, v);
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
        ),
      ],
    );
  }

  Widget _buildVideoTile(BuildContext context, UserVideoModel v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: v.isCompleted ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.primaryPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            v.isCompleted ? Icons.check_circle : Icons.play_arrow_rounded,
            color: v.isCompleted ? AppTheme.neonGreen : AppTheme.primaryPurple,
          ),
        ),
        title: Text(
          v.title,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText),
        ),
        subtitle: Text(
          () {
            final effDur = v.duration > 0 ? v.duration : (v.watchedSecs > 0 ? v.watchedSecs : 0);
            return 'Watched: ${v.watchedSecs}s / Total: ${effDur}s';
          }(),
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.softGrey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VideoPlayerScreen(video: v)),
          );
        },
      ),
    );
  }
}
