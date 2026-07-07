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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isLoggedIn = await authProvider.tryAutoLogin();
    
    if (!mounted) return;
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
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
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                'LOOP ADMIN',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.0,
                  color: AppTheme.lightText,
                ),
              ),
              Text(
                'MANAGEMENT SYSTEM',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                  color: AppTheme.primaryPink,
                ),
              ),
              
              const SizedBox(height: 50),
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
