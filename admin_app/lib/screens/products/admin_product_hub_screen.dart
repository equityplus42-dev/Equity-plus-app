import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class AdminProductHubScreen extends StatelessWidget {
  const AdminProductHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Hub'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Text(
                'PRODUCT CATEGORIES',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),

              _buildCategoryCard(
                context,
                icon: Icons.play_circle_outline,
                title: 'Videos',
                desc: 'Manage multilingual video content, courses, & requests',
                color: AppTheme.neonGreen,
                onTap: () => Navigator.pushNamed(context, AppRoutes.videoHub),
              ),

              _buildCategoryCard(
                context,
                icon: Icons.add_circle_outline_rounded,
                title: 'Add Category',
                desc: 'Configure new product types & modules',
                color: AppTheme.softGrey.withOpacity(0.5),
                isDisabled: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Additional product categories coming soon!'),
                      backgroundColor: AppTheme.primaryPurple,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDisabled ? AppTheme.softGrey : AppTheme.lightText,
                        ),
                      ),
                      if (isDisabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SOON',
                            style: GoogleFonts.outfit(fontSize: 9, color: AppTheme.softGrey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
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
