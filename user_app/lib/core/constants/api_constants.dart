class ApiConstants {
  // Set to true to connect to your local backend.
  // Set to false (default) to connect to the live Vercel backend.
  static const bool useLocalBackend = false;

  // Emulator default: 10.0.2.2 routes to host machine's localhost.
  // For physical device run: flutter run --dart-define=LOCAL_API_URL=http://192.168.31.64:5000/api/v1
  static const String _localUrl = String.fromEnvironment(
    'LOCAL_API_URL',
    defaultValue: 'http://10.0.2.2:5000/api/v1',
  );
  static const String _prodUrl = 'https://equity-plus-app.vercel.app/api/v1';

  static const String baseUrl = useLocalBackend ? _localUrl : _prodUrl;

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String requestOtp = '/auth/forgot-password/request-otp';
  static const String verifyOtp = '/auth/forgot-password/verify-otp';
  static const String resetPassword = '/auth/forgot-password/reset';

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
