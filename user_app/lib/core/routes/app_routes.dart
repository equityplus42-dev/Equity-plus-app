import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/referral/referrals_screen.dart';
import '../../screens/hierarchy/hierarchy_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/support/support_screen.dart';
import '../../screens/auth/kyc_screen.dart';
import '../../screens/auth/qr_scanner_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String referrals = '/referrals';
  static const String hierarchy = '/hierarchy';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String kyc = '/kyc';
  static const String qrScanner = '/qr-scanner';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => const DashboardScreen(),
      referrals: (context) => const ReferralsScreen(),
      hierarchy: (context) => const HierarchyScreen(),
      notifications: (context) => const NotificationsScreen(),
      profile: (context) => const ProfileScreen(),
      settings: (context) => const SettingsScreen(),
      support: (context) => const SupportScreen(),
      kyc: (context) => const KycScreen(),
      qrScanner: (context) => const QrScannerScreen(),
    };
  }
}
