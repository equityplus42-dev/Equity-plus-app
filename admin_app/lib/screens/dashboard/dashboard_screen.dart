import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../providers/update_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../widgets/change_password_dialog.dart';
import '../../core/constants/api_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats();
      Provider.of<AdminNotificationsProvider>(context, listen: false).fetchNotifications(silent: true);
    });
    // Periodically fetch stats silently in background every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats(silent: true);
        Provider.of<AdminNotificationsProvider>(context, listen: false).fetchNotifications(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
    final domain = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    Share.share(
      'Join my Vridhi Network! Download the User App and sign up using my referral code $code: $domain/download?ref=$code',
      subject: 'Vridhi Network Invite',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'System Control',
                                      style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.softGrey),
                                    ),
                                    const SizedBox(width: 8),
                                    Consumer<UpdateProvider>(
                                      builder: (context, updateProv, _) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryPurple.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.neonCyan.withOpacity(0.6), width: 0.8),
                                        ),
                                        child: Text(
                                          'v${updateProv.currentVersion} (${updateProv.currentBuildNumber})',
                                          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
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
                            Row(
                              children: [
                                Consumer<AdminNotificationsProvider>(
                                  builder: (context, notifProv, child) {
                                    final unread = notifProv.unreadCount;
                                    return Stack(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.notifications_outlined, color: AppTheme.lightText),
                                          onPressed: () {
                                            Navigator.pushNamed(context, AppRoutes.notifications);
                                          },
                                        ),
                                        if (unread > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.redAccent,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                              child: Text(
                                                '$unread',
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                                  onPressed: () async {
                                    await authProvider.logout();
                                    if (!context.mounted) return;
                                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                                  },
                                ),
                              ],
                            ),
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
                          title: 'Pending Rewards',
                          desc: 'Review and approve multi-level points payouts',
                          badgeCount: dashboard.pendingApprovals,
                          color: Colors.amberAccent,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.approvals).then((_) {
                            dashboard.fetchDashboardStats(silent: true);
                          }),
                        ),
                        _buildMenuTile(
                          icon: Icons.manage_accounts_outlined,
                          title: 'User Directory',
                          desc: 'Review signup lists and suspend or restore accounts',
                          color: AppTheme.primaryPurple,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.users).then((_) {
                            dashboard.fetchDashboardStats(silent: true);
                          }),
                        ),
                        _buildMenuTile(
                          icon: Icons.account_tree_outlined,
                          title: 'Hierarchy Tree',
                          desc: 'Visualize system-wide relational nodes paths',
                          color: AppTheme.neonCyan,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.hierarchy),
                        ),
                        _buildMenuTile(
                          icon: Icons.inventory_2_outlined,
                          title: 'Product',
                          desc: 'Manage video courses, folders, analytics, & products',
                          color: AppTheme.neonGreen,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.productHub),
                        ),
                        _buildMenuTile(
                          icon: Icons.payments_outlined,
                          title: 'Payments',
                          desc: 'Monitor Razorpay orders, transaction receipts, & user payments',
                          color: AppTheme.neonGreen,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.payments),
                        ),
                        _buildMenuTile(
                          icon: Icons.currency_exchange_outlined,
                          title: 'Refund Requests',
                          desc: 'Review refund applications, snapshot watch time, & approve payouts',
                          color: AppTheme.primaryPink,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.refunds),
                        ),
                        _buildMenuTile(
                          icon: Icons.lock_reset_outlined,
                          title: 'Change Password',
                          desc: 'Update your administrator account password',
                          color: AppTheme.primaryPurple,
                          onTap: () => ChangePasswordDialog.show(context),
                        ),
                        _buildMenuTile(
                          icon: Icons.campaign_rounded,
                          title: 'Announcements',
                          desc: 'Broadcast target-based announcements to users',
                          color: Colors.amberAccent,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.announcements),
                        ),
                        _buildMenuTile(
                          icon: Icons.security_rounded,
                          title: 'Audit Logs',
                          desc: 'Trace video uploads, deletion blocks, & security events',
                          color: AppTheme.neonCyan,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.auditLogs),
                        ),
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
