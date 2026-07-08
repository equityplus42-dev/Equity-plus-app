import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'PREFERENCES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.softGrey,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.notifications_active_outlined,
              title: 'Push Notifications',
              subtitle: 'Alert on downline activities',
              trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppTheme.primaryPurple),
            ),
            _buildSettingTile(
              icon: Icons.lock_outline,
              title: 'Biometric Security',
              subtitle: 'Unlock app with fingerprint',
              trailing: Switch(value: false, onChanged: (_) {}, activeColor: AppTheme.primaryPurple),
            ),
            
            const SizedBox(height: 30),
            
            Text(
              'INFORMATION',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.softGrey,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingTile(
              icon: Icons.verified_user_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we manage your data security',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.softGrey),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    title: Text('Privacy Policy', style: GoogleFonts.outfit(color: AppTheme.lightText)),
                    content: Text(
                      'Your data is secure and encrypted.\n\nWe do not share your personal information with third parties without your explicit consent.\n\nAll data is stored securely on our servers.',
                      style: GoogleFonts.outfit(color: AppTheme.softGrey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: AppTheme.primaryPurple)),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: 'v1.0.0 (Production Stable)',
              trailing: const Text('Up to date', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, color: AppTheme.primaryPurple, size: 24).copyWith(icon: icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
extension on Icon {
  Icon copyWith({IconData? icon}) {
    return Icon(
      icon ?? this.icon,
      key: key,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
