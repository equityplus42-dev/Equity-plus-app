import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Share Your Loop Code',
      'desc': 'Share your unique referral link or QR code with friends and family to start growing your loop.',
      'icon': 'share',
    },
    {
      'title': 'Grow Up To 3 Levels',
      'desc': 'Earn network rewards not just from people you invite directly, but also from indirect invites down to three depth levels.',
      'icon': 'hub',
    },
    {
      'title': 'Track Downline Trees',
      'desc': 'Visualize your entire affiliate network as a real-time tree structure and watch your reward points compile automatically.',
      'icon': 'account_tree',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    IconData iconData = Icons.share;
                    if (slide['icon'] == 'hub') iconData = Icons.hub;
                    if (slide['icon'] == 'account_tree') iconData = Icons.account_tree;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3), width: 2),
                            ),
                            child: Icon(
                              iconData,
                              size: 100,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 50),
                          Text(
                            slide['title']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lightText,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            slide['desc']!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppTheme.softGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? AppTheme.primaryPurple 
                          : AppTheme.softGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      }
                    },
                    child: Text(_currentPage == _slides.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
