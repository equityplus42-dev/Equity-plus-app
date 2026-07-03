import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/admin_approvals_provider.dart';
import 'providers/admin_users_provider.dart';
import 'providers/admin_settings_provider.dart';
import 'providers/admin_hierarchy_provider.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminApprovalsProvider()),
        ChangeNotifierProvider(create: (_) => AdminUsersProvider()),
        ChangeNotifierProvider(create: (_) => AdminSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdminHierarchyProvider()),
      ],
      child: MaterialApp(
        title: 'Loop Admin Network',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
