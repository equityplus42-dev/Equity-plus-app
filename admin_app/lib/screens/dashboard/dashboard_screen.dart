import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDevMode = false;
  int _tapCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDevMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats();
    });
    // Periodically fetch stats silently in background every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDevMode = prefs.getBool('dev_mode_active') ?? false;
      });
    } catch (e) {
      debugPrint('Error loading dev mode: $e');
    }
  }

  Future<void> _toggleDevMode(bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dev_mode_active', active);
      setState(() {
        _isDevMode = active;
      });
    } catch (e) {
      debugPrint('Error saving dev mode: $e');
    }
  }

  void _promptDevPassword() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _isDevMode ? 'Deactivate Developer Mode' : 'Developer Access',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isDevMode 
                  ? 'Enter Developer PIN to disable advanced settings.' 
                  : 'Enter security passcode to unlock advanced control panels.',
                style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(color: AppTheme.lightText),
                decoration: InputDecoration(
                  hintText: 'Passcode',
                  hintStyle: GoogleFonts.outfit(color: AppTheme.softGrey),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.softGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == '998877') {
                  Navigator.pop(context);
                  final newStatus = !_isDevMode;
                  _toggleDevMode(newStatus);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newStatus 
                          ? 'Developer Mode Activated! 🛠️' 
                          : 'Developer Mode Deactivated! 🔒',
                      ),
                      backgroundColor: newStatus ? AppTheme.neonGreen : Colors.redAccent,
                    ),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid passcode! ❌'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard! 📋'),
        backgroundColor: AppTheme.primaryPurple,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareReferralLink(String code) {
    Share.share(
      'Join my referral network! Sign up using my code $code at: https://referral-system.com/register?ref=$code',
      subject: 'Loop Referral System Invite',
    );
  }

  void _showQRCodeDialog(String? base64Qr, String code) {
    showDialog(
      context: context,
      builder: (context) {
        ImageProvider imageProvider;
        if (base64Qr != null && base64Qr.startsWith('data:image')) {
          final String base64Str = base64Qr.split(',')[1];
          imageProvider = MemoryImage(base64Decode(base64Str));
        } else {
          imageProvider = const NetworkImage('https://via.placeholder.com/300?text=QR+Code');
        }

        return Dialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Invitation QR Code',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan this QR code to sign up directly',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.softGrey,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image(
                    image: imageProvider,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Code: $code',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboard = Provider.of<AdminDashboardProvider>(context);

    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: dashboard.isLoading
              ? const Center(
                  child: SpinKitFadingCube(
                    color: AppTheme.primaryPurple,
                    size: 50.0,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => dashboard.fetchDashboardStats(silent: true),
                  color: AppTheme.primaryPurple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tapCount++;
                                  if (_tapCount >= 7) {
                                    _tapCount = 0;
                                    _promptDevPassword();
                                  }
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'System Control',
                                    style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.softGrey),
                                  ),
                                  Text(
                                    'Administrator Hub',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.lightText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                              onPressed: () async {
                                await authProvider.logout();
                                if (!context.mounted) return;
                                Navigator.pushReplacementNamed(context, AppRoutes.login);
                              },
                            )
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Summary Stats Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard(
                              title: 'TOTAL USERS',
                              value: '${dashboard.totalUsers}',
                              icon: Icons.people_alt_outlined,
                              color: AppTheme.primaryPurple,
                            ),
                            _buildStatCard(
                              title: 'PENDING APPROVALS',
                              value: '${dashboard.pendingApprovals}',
                              icon: Icons.pending_actions_outlined,
                              color: Colors.amberAccent,
                              badge: dashboard.pendingApprovals > 0,
                            ),
                            _buildStatCard(
                              title: 'TOTAL REFERRALS',
                              value: '${dashboard.totalReferrals}',
                              icon: Icons.share_outlined,
                              color: AppTheme.neonCyan,
                            ),
                            _buildStatCard(
                              title: 'POINTS CREDITED',
                              value: '${dashboard.totalPointsDistributed}',
                              icon: Icons.monetization_on_outlined,
                              color: AppTheme.neonGreen,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Referral Code sharing section
                        Text(
                          'INVITATION SYSTEM',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softGrey,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Referral Code',
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                                    ),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        dashboard.referralCode ?? 'LOADING',
                                        style: GoogleFonts.outfit(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryPurple,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.lightText),
                                    onPressed: () {
                                      if (dashboard.referralCode != null) {
                                        _showQRCodeDialog(
                                          dashboard.qrCodeDataUrl,
                                          dashboard.referralCode!,
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_outlined, color: AppTheme.lightText),
                                    onPressed: () {
                                      if (dashboard.referralCode != null) {
                                        _copyToClipboard(dashboard.referralCode!);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, color: AppTheme.lightText),
                                    onPressed: () {
                                      if (dashboard.referralCode != null) {
                                        _shareReferralLink(dashboard.referralCode!);
                                      }
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // Quick Action Panel
                        Text(
                          'SYSTEM MANAGEMENT',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softGrey,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _buildMenuTile(
                          icon: Icons.rule_folder_outlined,
                          title: 'Pending Reward Approvals',
                          desc: 'Review and approve multi-level points payouts',
                          badgeCount: dashboard.pendingApprovals,
                          color: Colors.amberAccent,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.approvals).then((_) {
                            dashboard.fetchDashboardStats(silent: true);
                          }),
                        ),
                        _buildMenuTile(
                          icon: Icons.manage_accounts_outlined,
                          title: 'User Management Directory',
                          desc: 'Review signup lists and suspend or restore accounts',
                          color: AppTheme.primaryPurple,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.users).then((_) {
                            dashboard.fetchDashboardStats(silent: true);
                          }),
                        ),
                        _buildMenuTile(
                          icon: Icons.account_tree_outlined,
                          title: 'Global Hierarchy Tree',
                          desc: 'Visualize system-wide relational nodes paths',
                          color: AppTheme.neonCyan,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.hierarchy),
                        ),
                        if (_isDevMode) ...[
                          _buildMenuTile(
                            icon: Icons.tune_outlined,
                            title: 'Global Campaign Settings',
                            desc: 'Alter level distribution percentages and reward constants',
                            color: AppTheme.primaryPink,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.settings).then((_) {
                              dashboard.fetchDashboardStats(silent: true);
                            }),
                          ),
                          _buildMenuTile(
                            icon: Icons.analytics_outlined,
                            title: 'Analytics Reports Logs',
                            desc: 'Trace activity history and verify system health checks',
                            color: AppTheme.neonGreen,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool badge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (badge)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    int badgeCount = 0,
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  '$badgeCount PND',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.softGrey)
          ],
        ),
      ),
    );
  }
}
