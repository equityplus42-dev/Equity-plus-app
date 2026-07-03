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

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String users = '/users';
  static const String approvals = '/approvals';
  static const String hierarchy = '/hierarchy';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String support = '/support';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      dashboard: (context) => const DashboardScreen(),
      users: (context) => const UsersScreen(),
      approvals: (context) => const ApprovalsScreen(),
      hierarchy: (context) => const HierarchyScreen(),
      reports: (context) => const ReportsScreen(),
      settings: (context) => const SettingsScreen(),
      notifications: (context) => const NotificationsScreen(),
      support: (context) => const SupportScreen(),
    };
  }
}
