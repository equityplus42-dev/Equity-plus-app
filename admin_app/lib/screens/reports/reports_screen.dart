import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'CAMPAIGN STATISTICS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.softGrey,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              title: 'Campaign Performance Index',
              value: 'High Active',
              indicatorColor: AppTheme.neonGreen,
            ),
            _buildReportCard(
              title: 'Network Multiplier Coefficient',
              value: '1.84x',
              indicatorColor: AppTheme.neonCyan,
            ),
            
            const SizedBox(height: 30),
            
            Text(
              'EXPORT DATA LOGS',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.softGrey,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildExportTile(
              context: context,
              icon: Icons.table_chart_outlined,
              title: 'Export Users Directory (CSV)',
              subtitle: 'Compiles registration details & code lists',
            ),
            _buildExportTile(
              context: context,
              icon: Icons.history_outlined,
              title: 'Export Referral Transaction Ledger (CSV)',
              subtitle: 'Dumps chronological reward allocations logs',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required Color indicatorColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.lightText),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: indicatorColor.withOpacity(0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExportTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulating compilation... file assembly complete! 📂'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryPurple, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download_outlined, color: AppTheme.softGrey),
          ],
        ),
      ),
    );
  }
}
