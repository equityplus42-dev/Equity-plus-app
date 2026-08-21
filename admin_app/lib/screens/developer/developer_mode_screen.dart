import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class DeveloperModeScreen extends StatelessWidget {
  const DeveloperModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVELOPER MODE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPink,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        'Developer Control Hub',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                    tooltip: 'Logout Developer Session',
                    onPressed: () async {
                      await authProvider.logout();
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              Text(
                'Authenticated Session: ${authProvider.user?.email ?? 'Developer'}',
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
              ),

              const SizedBox(height: 30),

              Text(
                'ADVANCED ENGINE CONTROLS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Feature 1: Campaign Settings
              _buildDevTile(
                context,
                icon: Icons.tune_outlined,
                title: 'Campaign Settings',
                desc: 'Alter reward percentages, hierarchy limits & campaign ads',
                color: AppTheme.primaryPink,
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),

              // Feature 2: System Audit Logs
              _buildDevTile(
                context,
                icon: Icons.security_rounded,
                title: 'System Audit Logs',
                desc: 'Trace video uploads, deletion blocks & security events',
                color: AppTheme.neonCyan,
                onTap: () => Navigator.pushNamed(context, AppRoutes.auditLogs),
              ),

              // Feature 3: Reports & System Health Logs
              _buildDevTile(
                context,
                icon: Icons.analytics_outlined,
                title: 'Reports & Data Logs',
                desc: 'Export user directory CSV, transaction ledgers & health index',
                color: AppTheme.neonGreen,
                onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
              ),

              // Feature 4: App Version & Release Hub
              _buildDevTile(
                context,
                icon: Icons.system_update_rounded,
                title: 'App Version & Release Hub',
                desc: 'Publish APK updates, manage builds, rollback & enforce updates',
                color: AppTheme.primaryGold,
                onTap: () => Navigator.pushNamed(context, AppRoutes.releases),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevTile(
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
