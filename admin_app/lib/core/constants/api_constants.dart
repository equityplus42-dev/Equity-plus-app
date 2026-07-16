import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _localUrl = kIsWeb ? 'http://localhost:5000/api/v1' : 'http://192.168.31.64:5000/api/v1';
  static const String _prodUrl = 'https://equity-plus-app-git-main-equilty-plus.vercel.app/api/v1';

  static const String baseUrl = kDebugMode ? _localUrl : _prodUrl;

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
  static const String uploadCampaignImage = '/admin/upload-campaign-image';
  static const String hierarchy = '/hierarchy';
  static const String referralQR = '/referrals/qr';

  static String approveReferral(String id) => '/admin/referrals/$id/approve';
  static String rejectReferral(String id) => '/admin/referrals/$id/reject';
  static String toggleUserApproval(String userId) => '/admin/users/$userId/approval';
}
