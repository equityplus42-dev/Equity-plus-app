import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

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

              const SizedBox(height: 20),
              Text(
                'RAZORPAY & TEST ACCOUNT CONTROLS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Feature 5: Membership Payment Pricing (Rs 1 Test Mode)
              _buildDevTile(
                context,
                icon: Icons.currency_rupee_rounded,
                title: 'Membership Payment Pricing',
                desc: 'Set membership fee amount in ₹ (e.g. ₹1 for live Razorpay testing)',
                color: Colors.amberAccent,
                onTap: () => _showUpdatePriceDialog(context),
              ),

              // Feature 6: Reset Test Account Payment Status
              _buildDevTile(
                context,
                icon: Icons.restart_alt_rounded,
                title: 'Reset Test User Payment Status',
                desc: 'Clear payment & product access records for test account to retry checkout',
                color: Colors.deepOrangeAccent,
                onTap: () => _showResetPaymentDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdatePriceDialog(BuildContext context) async {
    final apiClient = ApiClient();
    final controller = TextEditingController(text: '1');
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          if (isLoading) {
            apiClient.get('/payments/membership-price').then((res) {
              if (res != null && res['data'] != null) {
                final currentPrice = res['data']['price'];
                controller.text = '$currentPrice';
              }
              setState(() => isLoading = false);
            }).catchError((_) {
              setState(() => isLoading = false);
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            title: Text(
              'Change Membership Payment Price',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the membership fee in INR (₹) for user registration and payments:',
                  style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primaryPink))
                else
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, color: Colors.amberAccent),
                      labelText: 'Payment Amount (₹)',
                      labelStyle: GoogleFonts.outfit(color: AppTheme.softGrey),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPink),
                onPressed: isLoading
                    ? null
                    : () async {
                        final val = int.tryParse(controller.text.trim()) ?? 1;
                        try {
                          await apiClient.post('/payments/admin/membership-price', {'price': val});
                          if (!context.mounted) return;
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Membership payment price set to ₹$val!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: Text('Update Price', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPaymentDialog(BuildContext context) {
    final apiClient = ApiClient();
    final controller = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            title: Text(
              'Reset Test Account Payment',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the test user email address to wipe payment history and enable fresh Razorpay checkout testing:',
                  style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.neonCyan),
                    hintText: 'e.g. user@gmail.com',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (isResetting) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
                onPressed: isResetting
                    ? null
                    : () async {
                        final email = controller.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a user email address')),
                          );
                          return;
                        }
                        setState(() => isResetting = true);
                        try {
                          final res = await apiClient.post('/payments/admin/reset-user-payment', {'email': email});
                          if (!context.mounted) return;
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Payment status reset successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setState(() => isResetting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: Text('Reset Payment Status', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
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
