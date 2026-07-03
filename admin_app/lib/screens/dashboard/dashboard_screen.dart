import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats();
    });
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
                  onRefresh: () => dashboard.fetchDashboardStats(),
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
                            IconButton(
                              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                              onPressed: () async {
                                await authProvider.logout();
                                if (!mounted) return;
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
                          onTap: () => Navigator.pushNamed(context, AppRoutes.approvals),
                        ),
                        _buildMenuTile(
                          icon: Icons.manage_accounts_outlined,
                          title: 'User Management Directory',
                          desc: 'Review signup lists and suspend or restore accounts',
                          color: AppTheme.primaryPurple,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.users),
                        ),
                        _buildMenuTile(
                          icon: Icons.account_tree_outlined,
                          title: 'Global Hierarchy Tree',
                          desc: 'Visualize system-wide relational nodes paths',
                          color: AppTheme.neonCyan,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.hierarchy),
                        ),
                        _buildMenuTile(
                          icon: Icons.tune_outlined,
                          title: 'Global Campaign Settings',
                          desc: 'Alter level distribution percentages and reward constants',
                          color: AppTheme.primaryPink,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                        ),
                        _buildMenuTile(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics Reports Logs',
                          desc: 'Trace activity history and verify system health checks',
                          color: AppTheme.neonGreen,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
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
