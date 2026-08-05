import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminVideoAnalyticsScreen extends StatefulWidget {
  const AdminVideoAnalyticsScreen({super.key});

  @override
  State<AdminVideoAnalyticsScreen> createState() => _AdminVideoAnalyticsScreenState();
}

class _AdminVideoAnalyticsScreenState extends State<AdminVideoAnalyticsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _globalStats;
  List<dynamic> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final globalRes = await _apiClient.get('/analytics/admin/global');
      final videoRes = await _apiClient.get('/videos/admin/all');

      if (mounted) {
        setState(() {
          _globalStats = globalRes['data'];
          _videos = videoRes['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Analytics Dashboard'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: _isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Global Stats Cards
                    Text(
                      'PLATFORM OVERVIEW',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard('Most Active Language', _globalStats?['mostActiveLanguage'] ?? 'English', Icons.language, AppTheme.neonCyan),
                        _buildStatCard('Most Active Product', _globalStats?['mostActiveProduct'] ?? 'General', Icons.category, AppTheme.neonGreen),
                        _buildStatCard('Total Snapshots', '${_globalStats?['totalUserSnapshots'] ?? 0}', Icons.camera_alt, Colors.amberAccent),
                        _buildStatCard('Active Playbacks', '${_globalStats?['totalPlaybackSessions'] ?? 0}', Icons.play_circle_fill, AppTheme.primaryPink),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Per-Video Analytics List
                    Text(
                      'PER-VIDEO ENGAGEMENT (${_videos.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.softGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final v = _videos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['title'] ?? 'Untitled Video',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
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
                                      v['language']?['name'] ?? 'General',
                                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Duration: ${v['duration']}s',
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Version: v${v['currentVersionNumber'] ?? 1}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.lightText)),
                                  Text('Order Index: #${v['orderIndex']}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
          ),
        ],
      ),
    );
  }
}
