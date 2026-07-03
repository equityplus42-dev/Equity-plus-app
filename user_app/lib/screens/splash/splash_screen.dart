import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for splash animation to look good
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isLoggedIn = await authProvider.tryAutoLogin();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Brand Emblem
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.primaryPink],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.share,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              
              // App Name with dynamic typography
              Text(
                'LOOP',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8.0,
                  color: AppTheme.lightText,
                ),
              ),
              Text(
                'REFERRAL NETWORK',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: AppTheme.primaryPink,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Modern loader spinner
              const SpinKitDoubleBounce(
                color: AppTheme.primaryPurple,
                size: 40.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
