import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_payment_provider.dart';
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
  bool _hasNetworkError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _errorMessage = null;
      });
    }

    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isLoggedIn = await authProvider.tryAutoLogin();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      final user = authProvider.user;
      final bool hasKyc = user != null &&
          user.panNumber != null &&
          user.panNumber!.isNotEmpty &&
          user.aadharNumber != null &&
          user.aadharNumber!.isNotEmpty;
      if (!hasKyc) {
        Navigator.pushReplacementNamed(context, AppRoutes.kyc);
        return;
      }

      final paymentProv = Provider.of<UserPaymentProvider>(context, listen: false);
      final bool fetchedSuccessfully = await paymentProv.fetchUserPayments();

      if (!mounted) return;

      if (!fetchedSuccessfully && paymentProv.payments.isEmpty) {
        setState(() {
          _hasNetworkError = true;
          _errorMessage = paymentProv.errorMessage ?? 'Could not reach backend server.';
        });
        return;
      }

      final bool hasPaid = paymentProv.payments.any((p) => p.status == 'SUCCESS');

      if (hasPaid) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.paymentCheckout);
      }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Brand Emblem
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
                
                // App Name with dynamic typography
                Text(
                  'VRIDHI',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8.0,
                    color: AppTheme.lightText,
                  ),
                ),
                Text(
                  'NETWORK',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                    color: AppTheme.primaryPink,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                if (_hasNetworkError) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'Connection Error',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage ?? 'Unable to connect to local backend server.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.softGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _checkAuth,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                          },
                          child: Text(
                            'Continue to Dashboard',
                            style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Modern loader spinner
                  const SpinKitDoubleBounce(
                    color: AppTheme.primaryPurple,
                    size: 40.0,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
