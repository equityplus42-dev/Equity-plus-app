import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class AdminVideoHubScreen extends StatelessWidget {
  const AdminVideoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Hub'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Text(
                'VIDEO MANAGEMENT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),

              _buildTile(
                context,
                icon: Icons.video_library_outlined,
                title: 'Video Library',
                desc: 'Upload videos & manage language folders',
                color: AppTheme.neonGreen,
                onTap: () => Navigator.pushNamed(context, AppRoutes.videos),
              ),

              _buildTile(
                context,
                icon: Icons.mark_chat_unread_outlined,
                title: 'Language Requests',
                desc: 'Review & approve user language change requests',
                color: Colors.amber,
                onTap: () => Navigator.pushNamed(context, AppRoutes.languageRequests),
              ),

              _buildTile(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'Course Products',
                desc: 'Configure video packages & paid product layers',
                color: AppTheme.neonCyan,
                onTap: () => Navigator.pushNamed(context, AppRoutes.products),
              ),

              _buildTile(
                context,
                icon: Icons.bar_chart_rounded,
                title: 'Video Analytics',
                desc: 'Track engagement rates & watch progress metrics',
                color: AppTheme.primaryPurple,
                onTap: () => Navigator.pushNamed(context, AppRoutes.videoAnalytics),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.softGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.softGrey),
          ],
        ),
      ),
    );
  }
}
