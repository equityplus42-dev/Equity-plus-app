import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Support'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM HEALTH STATUS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildHealthIndicator(
                title: 'Express Backend API Node',
                status: 'Connected',
                color: AppTheme.neonGreen,
              ),
              _buildHealthIndicator(
                title: 'TiDB Primary Node cluster',
                status: 'Operational',
                color: AppTheme.neonGreen,
              ),
              _buildHealthIndicator(
                title: 'Cloudinary Storage API',
                status: 'Ready',
                color: AppTheme.neonCyan,
              ),
              
              const SizedBox(height: 40),
              Text(
                'DOCUMENTATION LINKS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildDocLink(context, 'System Architecture & ERD Spec'),
              _buildDocLink(context, 'API Endpoint Routing Dictionary'),
              _buildDocLink(context, 'TiDB Database Backup Schema Guide'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthIndicator({
    required String title,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(status, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDocLink(BuildContext context, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening document... 📄'), backgroundColor: AppTheme.primaryPurple),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.lightText)),
            const Icon(Icons.open_in_new, color: AppTheme.softGrey, size: 18),
          ],
        ),
      ),
    );
  }
}
