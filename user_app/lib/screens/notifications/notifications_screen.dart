import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'REFERRAL_SIGNUP':
        return Icons.person_add_outlined;
      case 'REFERRAL_APPROVED':
        return Icons.check_circle_outline;
      case 'REFERRAL_REJECTED':
        return Icons.error_outline;
      case 'SYSTEM':
      default:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'REFERRAL_SIGNUP':
        return AppTheme.neonCyan;
      case 'REFERRAL_APPROVED':
        return AppTheme.neonGreen;
      case 'REFERRAL_REJECTED':
        return Colors.redAccent;
      case 'SYSTEM':
      default:
        return AppTheme.primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () => notificationProvider.markAllAsRead(),
              child: const Text('Mark All Read'),
            )
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: notificationProvider.isLoading
            ? const Center(
                child: SpinKitRing(
                  color: AppTheme.primaryPurple,
                  size: 50.0,
                ),
              )
            : notificationProvider.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none, size: 80, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'All Caught Up!',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No new notifications to display.',
                          style: GoogleFonts.outfit(color: AppTheme.softGrey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => notificationProvider.fetchNotifications(),
                    color: AppTheme.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: notificationProvider.notifications.length,
                      itemBuilder: (context, index) {
                        final note = notificationProvider.notifications[index];
                        final String dateStr = '${DateFormat('jm').format(note.createdAt)} - ${DateFormat('yMMMd').format(note.createdAt)}';

                        return GestureDetector(
                          onTap: () {
                            if (!note.isRead) {
                              notificationProvider.markAsRead(note.id);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCardDecoration().copyWith(
                              color: note.isRead 
                                  ? AppTheme.glassCardBg 
                                  : AppTheme.primaryPurple.withValues(alpha: 0.05),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(note.type).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getTypeIcon(note.type),
                                    color: _getTypeColor(note.type),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              note.title,
                                              style: GoogleFonts.outfit(
                                                fontSize: 16,
                                                fontWeight: note.isRead 
                                                    ? FontWeight.bold 
                                                    : FontWeight.w900,
                                                color: AppTheme.lightText,
                                              ),
                                            ),
                                          ),
                                          if (!note.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primaryPink,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        note.message,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: note.isRead 
                                              ? AppTheme.softGrey 
                                              : AppTheme.lightText.withValues(alpha: 0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: AppTheme.softGrey.withValues(alpha: 0.6),
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
