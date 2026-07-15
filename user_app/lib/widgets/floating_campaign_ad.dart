import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/dashboard_provider.dart';
import '../core/theme/app_theme.dart';

class FloatingCampaignAd extends StatefulWidget {
  const FloatingCampaignAd({super.key});

  @override
  State<FloatingCampaignAd> createState() => _FloatingCampaignAdState();
}

class _FloatingCampaignAdState extends State<FloatingCampaignAd> {
  bool _isOpened = true; // Initially visible when dashboard opens

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch url: $urlString');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final settings = dashboardProvider.systemSettings;

    // Check if campaign is enabled
    final bool isEnabled = settings['campaign_ad_enabled'] == 'true';
    if (!isEnabled) {
      return const SizedBox();
    }

    final String title = settings['campaign_ad_title'] ?? 'Special Promo Offer';
    final String description = settings['campaign_ad_description'] ?? 'Check out our latest exclusive updates.';
    final String imageUrl = settings['campaign_ad_image_url'] ?? 'https://picsum.photos/400/250';
    final String redirectUrl = settings['campaign_ad_redirect_url'] ?? 'https://google.com';

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Dimensions
    const double cardWidth = 240.0;
    const double cardHeight = 270.0;
    const double rightPadding = 16.0;

    // Positions based on opened/closed state
    // When opened: aligned to the right edge
    // When closed: pushed off-screen (only a small tab is visible)
    final double targetLeft = _isOpened 
        ? screenWidth - cardWidth - rightPadding 
        : screenWidth - 36.0; // Show a small 36px tab sticking out

    final double targetTop = screenHeight - cardHeight - 110.0; // Float near bottom

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      left: targetLeft,
      top: targetTop,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sticky Arrow Drawer Handle (Only visible/useful when closed to pull it back)
          if (!_isOpened)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isOpened = true;
                });
              },
              child: Container(
                width: 36,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),

          // Main Ad Card Container
          if (_isOpened)
            Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image and Close Button Stack
                    Stack(
                      children: [
                        // Ad Picture Thumbnail
                        GestureDetector(
                          onTap: () => _launchURL(redirectUrl),
                          child: SizedBox(
                            width: cardWidth,
                            height: 110,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.borderGrey.withOpacity(0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      color: AppTheme.softGrey,
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppTheme.borderGrey.withOpacity(0.2),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryPurple),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Close 'X' Button on top-right
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isOpened = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Title & Description Text
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Container(
                        width: double.infinity,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () => _launchURL(redirectUrl),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Visit Website',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
