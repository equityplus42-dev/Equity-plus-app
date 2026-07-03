import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Alerts'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_none, size: 80, color: AppTheme.softGrey),
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
                'All operations are currently running normally.',
                style: GoogleFonts.outfit(color: AppTheme.softGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
