class ApiConstants {
  // Set to true to connect to your local backend.
  // Set to false to connect to the live Vercel backend.
  static const bool useLocalBackend = true;

  static const String _prodUrl = 'https://equity-plus-app.vercel.app/api/v1';

  // Candidate Base URLs for local ADB, Wi-Fi, and production resilience
  static const List<String> candidateBaseUrls = [
    'http://127.0.0.1:5000/api/v1',
    'http://192.168.31.64:5000/api/v1',
    'http://192.168.31.217:5000/api/v1',
    'http://10.0.2.2:5000/api/v1',
    'https://equity-plus-app.vercel.app/api/v1',
  ];

  static String activeBaseUrl = useLocalBackend ? candidateBaseUrls.first : _prodUrl;
  static String get baseUrl => useLocalBackend ? activeBaseUrl : _prodUrl;

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

  // Video & Disclaimer endpoints
  static const String userVideos = '/videos';
  static const String selectLanguage = '/videos/select-language';
  static const String acceptDisclaimer = '/videos/disclaimer/accept';
  static String recordVideoProgress(String id) => '/videos/$id/progress';
  static const String refundStatus = '/videos/refund-status';
  static const String videoProgressStatus = '/videos/progress';
  static const String lockedVideos = '/videos/locked';
  static String secureVideoAccess(String videoId) => '/videos/$videoId/access';
  static String recordPlaybackHeartbeat(String videoId) => '/videos/$videoId/heartbeat';

  // Language Change Requests & Public Languages
  static const String publicLanguages = '/languages';
  static const String languageRequestsMy = '/language-requests/my';
}
