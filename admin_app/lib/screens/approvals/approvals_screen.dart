import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_approvals_provider.dart';
import '../../providers/admin_dashboard_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminApprovalsProvider>(context, listen: false).fetchPendingApprovals();
    });
  }

  Future<void> _approve(String id) async {
    final success = await Provider.of<AdminApprovalsProvider>(context, listen: false).approveReferral(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral reward approved! Points distributed.'), backgroundColor: AppTheme.neonGreen),
      );
      // Reload dashboard counts
      Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats();
    }
  }

  Future<void> _reject(String id) async {
    final success = await Provider.of<AdminApprovalsProvider>(context, listen: false).rejectReferral(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral reward declined.'), backgroundColor: Colors.redAccent),
      );
      Provider.of<AdminDashboardProvider>(context, listen: false).fetchDashboardStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvals = Provider.of<AdminApprovalsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Approvals'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: approvals.isLoading
            ? const Center(child: SpinKitPulse(color: AppTheme.primaryPurple))
            : approvals.pendingReferrals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_outlined, size: 80, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'All Set!',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No pending referral rewards requiring review.',
                          style: GoogleFonts.outfit(color: AppTheme.softGrey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => approvals.fetchPendingApprovals(),
                    color: AppTheme.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: approvals.pendingReferrals.length,
                      itemBuilder: (context, index) {
                        final ref = approvals.pendingReferrals[index];
                        final dateStr = DateFormat('yMMMd').format(ref.createdAt);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'NEW SIGNUP INVITE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.softGrey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Referrer and Referee info
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Referee (New User)', style: TextStyle(fontSize: 11, color: AppTheme.softGrey.withValues(alpha: 0.8))),
                                        const SizedBox(height: 2),
                                        Text(ref.refereeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText)),
                                        Text(ref.refereeEmail, style: const TextStyle(fontSize: 12, color: AppTheme.softGrey)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward, color: AppTheme.primaryPurple, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Referrer (Inviter)', style: TextStyle(fontSize: 11, color: AppTheme.softGrey.withValues(alpha: 0.8))),
                                        const SizedBox(height: 2),
                                        Text(ref.referrerName ?? 'User', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText)),
                                        Text(ref.referrerEmail ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.softGrey)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: AppTheme.borderGrey.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              
                              // Points and buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.stars, color: Colors.amberAccent, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        '+${ref.points} PTS to Referrers',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.lightText),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () => _reject(ref.id),
                                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                        child: const Text('Decline'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _approve(ref.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.neonGreen,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
