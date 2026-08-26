import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_notifications_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminNotificationsProvider>(context, listen: false).fetchNotifications();
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'REFERRAL_SIGNUP':
        return Icons.person_add_alt_1_rounded;
      case 'CASH_PAYMENT_REQUEST':
        return Icons.payments_rounded;
      case 'PAYMENT':
        return Icons.monetization_on_rounded;
      case 'REFUND':
        return Icons.currency_exchange_rounded;
      case 'ADMIN_ALERT':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'REFERRAL_SIGNUP':
        return AppTheme.neonCyan;
      case 'CASH_PAYMENT_REQUEST':
        return Colors.amber;
      case 'PAYMENT':
        return AppTheme.neonGreen;
      case 'REFUND':
        return Colors.amber;
      case 'ADMIN_ALERT':
        return AppTheme.primaryPurple;
      default:
        return AppTheme.softGrey;
    }
  }

  String? _extractPaymentId(String message) {
    final match = RegExp(r'Payment ID:\s*([a-zA-Z0-9_-]+)').firstMatch(message);
    return match?.group(1);
  }

  /// Confirmation dialog before clearing all notifications
  Future<void> _confirmClearAll(AdminNotificationsProvider provider) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'Clear Notifications',
          style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Choose what to clear:\n\n• "Mine Only" clears your admin notifications.\n• "All Users" clears notifications for every user in the system.',
          style: GoogleFonts.outfit(color: AppTheme.softGrey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'mine'),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.neonCyan)),
            child: Text('Mine Only', style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'all'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('All Users', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    bool success;
    String msg;
    if (choice == 'mine') {
      success = await provider.clearMyNotifications();
      msg = success ? '🗑️ Your notifications cleared' : 'Failed to clear notifications';
    } else {
      success = await provider.clearAllUsersNotifications();
      msg = success ? '🗑️ All users\' notifications cleared' : 'Failed to clear all notifications';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? AppTheme.neonGreen : Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildCashApprovalButton(AdminNotificationModel item, AdminNotificationsProvider provider) {
    final paymentId = _extractPaymentId(item.message);
    final bool isApproved = item.isRead;

    if (isApproved || paymentId == null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.neonGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: AppTheme.neonGreen),
            const SizedBox(width: 4),
            Text(
              'CASH APPROVED',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.neonGreen),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: ElevatedButton.icon(
        onPressed: () async {
          final success = await provider.approveCashPayment(paymentId);
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Cash Payment Verified & Approved! User access granted.'),
                  backgroundColor: AppTheme.neonGreen,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? 'Approval failed'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
        label: Text(
          'Approve Cash Payment (Tick)',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonGreen,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<AdminNotificationsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (notifProvider.notifications.isNotEmpty) ...[
            if (notifProvider.unreadCount > 0)
              TextButton.icon(
                onPressed: () => notifProvider.markAllRead(),
                icon: const Icon(Icons.done_all, size: 18, color: AppTheme.neonCyan),
                label: Text(
                  'Mark All Read',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              tooltip: 'Clear All Notifications',
              onPressed: () => _confirmClearAll(notifProvider),
            ),
          ],
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: notifProvider.isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : notifProvider.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No System Alerts',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Notifications for user signups, cash payments, and refunds will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => notifProvider.fetchNotifications(),
                    color: AppTheme.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifProvider.notifications[index];
                        final color = _getNotificationColor(item.type);
                        final icon = _getNotificationIcon(item.type);
                        final bool isCashRequest = item.type == 'CASH_PAYMENT_REQUEST' || item.title.contains('Cash Payment');

                        return GestureDetector(
                          onTap: () {
                            if (!item.isRead) {
                              notifProvider.markAsRead(item.id);
                            }
                            if (item.type == 'REFUND') {
                              Navigator.pushNamed(context, AppRoutes.refunds);
                            } else if (item.type == 'REFERRAL_SIGNUP') {
                              Navigator.pushNamed(context, AppRoutes.approvals);
                            } else if (item.type == 'PAYMENT' || item.type == 'CASH_PAYMENT_REQUEST') {
                              Navigator.pushNamed(context, AppRoutes.payments);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCardDecoration().copyWith(
                              border: Border.all(
                                color: item.isRead
                                    ? Colors.white.withOpacity(0.08)
                                    : color.withOpacity(0.5),
                                width: item.isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color.withOpacity(0.4)),
                                  ),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                color: AppTheme.lightText,
                                              ),
                                            ),
                                          ),
                                          if (!item.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.neonCyan,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.message,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: AppTheme.softGrey,
                                          height: 1.3,
                                        ),
                                      ),

                                      // If Cash Payment Request, show tick mark approve button
                                      if (isCashRequest) ...[
                                        _buildCashApprovalButton(item, notifProvider),
                                      ],

                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(item.createdAt),
                                          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
