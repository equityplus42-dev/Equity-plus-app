import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = kIsWeb ? 'http://localhost:5000/api/v1' : 'http://192.168.31.101:5000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';

  // Admin specific endpoints
  static const String stats = '/admin/stats';
  static const String users = '/users';
  static const String userDetail = '/users';
  static const String pendingReferrals = '/admin/referrals/pending';
  static const String updateSetting = '/admin/settings';
  static const String getSettings = '/settings';
  static const String hierarchy = '/hierarchy';
  static const String referralQR = '/referrals/qr';

  static String approveReferral(String id) => '/admin/referrals/$id/approve';
  static String rejectReferral(String id) => '/admin/referrals/$id/reject';
  static String toggleUserApproval(String userId) => '/admin/users/$userId/approval';
}
