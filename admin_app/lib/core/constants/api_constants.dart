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
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';

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

  // Language & Video endpoints
  static const String languages = '/languages';
  static const String adminVideos = '/videos/admin';
  static String assignUserLanguage(String userId) => '/videos/admin/users/$userId/language';
  static String resetUserVideoProgress(String userId) => '/videos/admin/users/$userId/reset-video-progress';
  static String getUserSnapshotAdmin(String userId) => '/videos/admin/users/$userId/snapshot';
  static const String reorderVideos = '/videos/admin/reorder';

  // Language Change Requests & Products endpoints
  static const String languageRequestsAdmin = '/language-requests/admin';
  static String reviewLanguageRequest(String id) => '/language-requests/admin/$id/review';
  static const String products = '/products';
  static const String productsAdmin = '/products/admin';
  static String archiveProduct(String id) => '/products/admin/$id/archive';
  static String assignUserProduct(String userId) => '/products/admin/users/$userId/product';
}
