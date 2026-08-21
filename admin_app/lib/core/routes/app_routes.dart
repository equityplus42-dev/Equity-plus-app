import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/approvals/approvals_screen.dart';
import '../../screens/hierarchy/hierarchy_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/support/support_screen.dart';
import '../../screens/videos/admin_video_management_screen.dart';
import '../../screens/language_requests/admin_language_requests_screen.dart';
import '../../screens/products/admin_products_screen.dart';
import '../../screens/analytics/admin_video_analytics_screen.dart';
import '../../screens/announcements/admin_announcements_screen.dart';
import '../../screens/audit/admin_audit_logs_screen.dart';

import '../../screens/products/admin_product_hub_screen.dart';
import '../../screens/videos/admin_video_hub_screen.dart';
import '../../screens/payments/admin_payments_screen.dart';
import '../../screens/refunds/admin_refunds_screen.dart';

import '../../screens/release/admin_release_management_screen.dart';

import '../../screens/developer/developer_mode_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String developerMode = '/developer-mode';
  static const String users = '/users';
  static const String approvals = '/approvals';
  static const String hierarchy = '/hierarchy';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String productHub = '/product-hub';
  static const String videoHub = '/video-hub';
  static const String videos = '/videos';
  static const String languageRequests = '/language-requests';
  static const String products = '/products';
  static const String videoAnalytics = '/video-analytics';
  static const String announcements = '/announcements';
  static const String auditLogs = '/audit-logs';
  static const String payments = '/payments';
  static const String refunds = '/refunds';
  static const String releases = '/releases';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      developerMode: (context) => const DeveloperModeScreen(),
      users: (context) => const UsersScreen(),
      approvals: (context) => const ApprovalsScreen(),
      hierarchy: (context) => const HierarchyScreen(),
      reports: (context) => const ReportsScreen(),
      settings: (context) => const SettingsScreen(),
      notifications: (context) => const NotificationsScreen(),
      support: (context) => const SupportScreen(),
      productHub: (context) => const AdminProductHubScreen(),
      videoHub: (context) => const AdminVideoHubScreen(),
      videos: (context) => const AdminVideoManagementScreen(),
      languageRequests: (context) => const AdminLanguageRequestsScreen(),
      products: (context) => const AdminProductsScreen(),
      videoAnalytics: (context) => const AdminVideoAnalyticsScreen(),
      announcements: (context) => const AdminAnnouncementsScreen(),
      auditLogs: (context) => const AdminAuditLogsScreen(),
      payments: (context) => const AdminPaymentsScreen(),
      refunds: (context) => const AdminRefundsScreen(),
      releases: (context) => const AdminReleaseManagementScreen(),
    };
  }
}

