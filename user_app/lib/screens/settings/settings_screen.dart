import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
    setState(() {
      _biometricEnabled = value;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings & Hub'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // FINANCIAL & TRANSACTIONS
            _buildSectionHeader('FINANCIAL & TRANSACTIONS'),
            _buildSettingTile(
              icon: Icons.receipt_long_outlined,
              iconColor: AppTheme.neonGreen,
              title: 'Payments',
              subtitle: 'Receipts & billing history',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.softGrey),
              onTap: () => Navigator.pushNamed(context, AppRoutes.paymentHistory),
            ),
            _buildSettingTile(
              icon: Icons.currency_exchange_outlined,
              iconColor: AppTheme.primaryPink,
              title: 'Refund Requests',
              subtitle: 'Apply for refund & track status',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.softGrey),
              onTap: () => Navigator.pushNamed(context, AppRoutes.refundRequest),
            ),

            const SizedBox(height: 24),

            // HELP & SUPPORT
            _buildSectionHeader('HELP & CUSTOMER SUPPORT'),
            _buildSettingTile(
              icon: Icons.support_agent_outlined,
              iconColor: AppTheme.neonCyan,
              title: 'Support Hub',
              subtitle: 'Help desk, FAQs & documentation',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.softGrey),
              onTap: () => Navigator.pushNamed(context, AppRoutes.support),
            ),

            const SizedBox(height: 24),

            // PREFERENCES & SECURITY
            _buildSectionHeader('PREFERENCES & SECURITY'),
            _buildSettingTile(
              icon: Icons.notifications_active_outlined,
              iconColor: AppTheme.primaryPurple,
              title: 'Push Notifications',
              subtitle: 'Alert on downline activities & updates',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: AppTheme.primaryPurple,
              ),
            ),
            _buildSettingTile(
              icon: Icons.lock_outline,
              iconColor: AppTheme.primaryPurple,
              title: 'Biometric Security',
              subtitle: 'Unlock app with fingerprint or Face ID',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _toggleBiometrics,
                activeColor: AppTheme.primaryPurple,
              ),
            ),

            const SizedBox(height: 24),

            // LEGAL & INFORMATION
            _buildSectionHeader('LEGAL & INFORMATION'),
            _buildSettingTile(
              icon: Icons.gavel_outlined,
              iconColor: AppTheme.neonCyan,
              title: 'Terms & Conditions',
              subtitle: '4000+ words legal agreement & 25% refund policy',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.neonCyan),
              onTap: () => Navigator.pushNamed(context, AppRoutes.termsAndConditions),
            ),
            _buildSettingTile(
              icon: Icons.verified_user_outlined,
              iconColor: AppTheme.softGrey,
              title: 'Privacy Policy',
              subtitle: 'Data protection and security compliance',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.softGrey),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      'Privacy Policy',
                      style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
                    ),
                    content: SingleChildScrollView(
                      child: Text(
                        'Your privacy and data security are our top priorities.\n\n'
                        '1. Data Encryption: All personal identifiable information (PII) and credentials are stored with end-to-end encryption.\n\n'
                        '2. Zero Third-Party Sharing: We never sell or share your activity or downline information with external third parties.\n\n'
                        '3. Verification Data: KYC and payment verification documents are strictly restricted to authorized compliance personnel.',
                        style: GoogleFonts.outfit(color: AppTheme.softGrey, height: 1.5),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.info_outline,
              iconColor: AppTheme.neonGreen,
              title: 'App Version',
              subtitle: 'v1.0.0 (Production Stable)',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Up to date',
                  style: GoogleFonts.outfit(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ACCOUNT ACTIONS
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                label: Text(
                  'Logout from App',
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.softGrey,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCardDecoration(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.softGrey,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

