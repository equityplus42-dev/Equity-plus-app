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
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/videos/user_video_library_screen.dart';
import '../../screens/language_requests/user_language_request_screen.dart';
import '../../screens/videos/watch_history_screen.dart';
import '../../screens/payments/payment_history_screen.dart';
import '../../screens/payments/payment_checkout_screen.dart';
import '../../screens/refunds/user_refund_request_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String referrals = '/referrals';
  static const String hierarchy = '/hierarchy';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String kyc = '/kyc';
  static const String qrScanner = '/qr-scanner';
  static const String videos = '/videos';
  static const String languageRequest = '/language-request';
  static const String watchHistory = '/watch-history';
  static const String paymentHistory = '/payment-history';
  static const String paymentCheckout = '/payment-checkout';
  static const String refundRequest = '/refund-request';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      dashboard: (context) => const DashboardScreen(),
      referrals: (context) => const ReferralsScreen(),
      hierarchy: (context) => const HierarchyScreen(),
      notifications: (context) => const NotificationsScreen(),
      profile: (context) => const ProfileScreen(),
      settings: (context) => const SettingsScreen(),
      support: (context) => const SupportScreen(),
      kyc: (context) => const KycScreen(),
      qrScanner: (context) => const QrScannerScreen(),
      videos: (context) => const UserVideoLibraryScreen(),
      languageRequest: (context) => const UserLanguageRequestScreen(),
      watchHistory: (context) => const WatchHistoryScreen(),
      paymentHistory: (context) => const PaymentHistoryScreen(),
      paymentCheckout: (context) => const PaymentCheckoutScreen(),
      refundRequest: (context) => const UserRefundRequestScreen(),
    };
  }
}
