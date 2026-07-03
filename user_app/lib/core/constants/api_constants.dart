class ApiConstants {
  // Replace with your local machine's IP address (e.g. 10.0.2.2 for Android emulator, or actual IP)
  static const String baseUrl = 'http://192.168.31.101:5000/api/v1';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';

  // User & Profile endpoints
  static const String profile = '/users/profile';
  static const String updateProfile = '/profile';
  static const String uploadAvatar = '/profile/avatar';

  // Referral endpoints
  static const String referrals = '/referrals';
  static const String referralStats = '/referrals/stats';
  static const String referralQR = '/referrals/qr';

  // Hierarchy endpoints
  static const String hierarchy = '/hierarchy';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String readAllNotifications = '/notifications/read-all';
  static String readNotification(String id) => '/notifications/$id/read';
}
