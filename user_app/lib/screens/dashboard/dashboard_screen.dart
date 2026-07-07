import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard metrics and notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
      Provider.of<AuthProvider>(context, listen: false).refreshProfile();
    });
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
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final String name = authProvider.user?.fullName ?? 'Referral User';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final int points = authProvider.user?.points ?? dashboardProvider.totalPoints;

    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: dashboardProvider.isLoading
              ? const Center(
                  child: SpinKitFadingCube(
                    color: AppTheme.primaryPurple,
                    size: 50.0,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await dashboardProvider.fetchDashboardData();
                    await notificationProvider.fetchNotifications();
                    await authProvider.refreshProfile();
                  },
                  color: AppTheme.primaryPurple,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryPurple,
                                    backgroundImage: authProvider.user?.avatarUrl != null
                                        ? NetworkImage(authProvider.user!.avatarUrl!)
                                        : null,
                                    child: authProvider.user?.avatarUrl == null
                                        ? Text(
                                            initial,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello,',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: AppTheme.softGrey,
                                      ),
                                    ),
                                    Text(
                                      name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lightText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Notifications button with badge
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined, size: 28),
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                                ),
                                if (notificationProvider.unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryPink,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${notificationProvider.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Premium Point balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.glassCardDecoration().copyWith(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple.withOpacity(0.15),
                                AppTheme.primaryPink.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'TOTAL REWARD BALANCE',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.softGrey,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: AppTheme.neonGreen,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$points',
                                    style: GoogleFonts.outfit(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.lightText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PTS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.neonGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: AppTheme.borderGrey.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${dashboardProvider.totalReferrals}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.lightText,
                                        ),
                                      ),
                                      const Text('Referrals'),
                                    ],
                                  ),
                                  Container(width: 1.5, height: 30, color: AppTheme.borderGrey),
                                  Column(
                                    children: [
                                      Text(
                                        '${dashboardProvider.approvedReferrals}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.lightText,
                                        ),
                                      ),
                                      const Text('Approved'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Referral Code',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dashboardProvider.referralCode ?? 'LOADING',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryPurple,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner, color: AppTheme.lightText),
                                    onPressed: () {
                                      if (dashboardProvider.referralCode != null) {
                                        _showQRCodeDialog(
                                          dashboardProvider.qrCodeDataUrl,
                                          dashboardProvider.referralCode!,
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_outlined, color: AppTheme.lightText),
                                    onPressed: () {
                                      if (dashboardProvider.referralCode != null) {
                                        _copyToClipboard(dashboardProvider.referralCode!);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined, color: AppTheme.lightText),
                                    onPressed: () {
                                      if (dashboardProvider.referralCode != null) {
                                        _shareReferralLink(dashboardProvider.referralCode!);
                                      }
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Menu list items
                        Text(
                          'NETWORK VIEWS',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softGrey,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMenuCard(
                                icon: Icons.people_outline,
                                title: 'Referral Logs',
                                subtitle: 'List of members',
                                color: AppTheme.primaryPurple,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.referrals),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMenuCard(
                                icon: Icons.account_tree_outlined,
                                title: 'Hierarchy Tree',
                                subtitle: 'Downline network',
                                color: AppTheme.neonCyan,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.hierarchy),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMenuCard(
                                icon: Icons.settings_applications_outlined,
                                title: 'App Settings',
                                subtitle: 'Theme & security',
                                color: AppTheme.primaryPink,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMenuCard(
                                icon: Icons.support_agent_outlined,
                                title: 'Support Hub',
                                subtitle: 'Help & documentation',
                                color: AppTheme.neonGreen,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.support),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Logout Action
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              await authProvider.logout();
                              if (!context.mounted) return;
                              Navigator.pushReplacementNamed(context, AppRoutes.login);
                            },
                            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                            label: const Text(
                              'Logout from App',
                              style: TextStyle(color: Colors.redAccent, fontSize: 16),
                            ),
                          ),
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

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.softGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
