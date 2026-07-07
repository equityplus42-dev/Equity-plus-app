import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Hub'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOW CAN WE HELP?',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              
              // Search bar mock
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search FAQ and guides...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.softGrey),
                  fillColor: AppTheme.cardBg.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                'QUICK CONTACTS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildSupportContact(
                icon: Icons.email_outlined,
                title: 'Email Support',
                value: 'support@referralloop.com',
                color: AppTheme.primaryPurple,
              ),
              _buildSupportContact(
                icon: Icons.chat_bubble_outline_outlined,
                title: 'Live Chat Simulator',
                value: 'Available 24/7 in-app',
                color: AppTheme.neonCyan,
              ),
              _buildSupportContact(
                icon: Icons.article_outlined,
                title: 'Documentation',
                value: 'Read referral guides online',
                color: AppTheme.primaryPink,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportContact({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
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
                value,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.softGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
