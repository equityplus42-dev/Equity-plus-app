import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

enum DownloadStatus {
  idle,
  downloading,
  verifying,
  readyToInstall,
  installing,
  success,
  failed,
}

class UpdateProvider extends ChangeNotifier {
  static final UpdateProvider _instance = UpdateProvider._internal();
  factory UpdateProvider() => _instance;
  UpdateProvider._internal();

  final ApiClient _apiClient = ApiClient();

  String _appType = 'ADMIN_APP';
  String _platform = 'ANDROID';
  String _currentVersion = '1.0.0';
  int _currentBuildNumber = 1;
  bool _isInitialized = false;

  // Update check results
  bool _updateAvailable = false;
  bool _forceUpdate = false;
  String _latestVersion = '';
  int _latestBuildNumber = 0;
  String _releaseTitle = '';
  String _releaseNotes = '';
  String _downloadUrl = '';
  String _websiteUrl = '';
  int _fileSizeBytes = 0;
  String? _expectedSha256;
  bool _dismissedOptional = false;

  // Download state machine
  DownloadStatus _status = DownloadStatus.idle;
  double _progress = 0.0; // 0.0 to 1.0
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String _downloadSpeed = '';
  String? _errorMessage;
  String? _downloadedFilePath;

  // Getters
  String get appType => _appType;
  String get platform => _platform;
  String get currentVersion => _currentVersion;
  int get currentBuildNumber => _currentBuildNumber;
  bool get isInitialized => _isInitialized;

  bool get updateAvailable => _updateAvailable;
  bool get forceUpdate => _forceUpdate;
  bool get shouldShowOptionalDialog => _updateAvailable && !_forceUpdate && !_dismissedOptional;
  String get latestVersion => _latestVersion;
  int get latestBuildNumber => _latestBuildNumber;
  String get releaseTitle => _releaseTitle;
  String get releaseNotes => _releaseNotes;
  String get downloadUrl => _downloadUrl;
  String get websiteUrl => _websiteUrl.isNotEmpty ? _websiteUrl : _downloadUrl;
  int get fileSizeBytes => _fileSizeBytes;
  String? get expectedSha256 => _expectedSha256;

  DownloadStatus get status => _status;
  double get progress => _progress;
  int get receivedBytes => _receivedBytes;
  int get totalBytes => _totalBytes;
  String get downloadSpeed => _downloadSpeed;
  String? get errorMessage => _errorMessage;

  void configureAppType(String appType) {
    _appType = appType;
  }

  /// Launch external web browser for manual APK / Website download
  Future<void> openWebsiteDownloadUrl() async {
    final targetUrl = _websiteUrl.isNotEmpty ? _websiteUrl : _downloadUrl;
    if (targetUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(targetUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[UpdateProvider] Could not launch website download URL: $e');
      }
    }
  }

  bool _isChecking = false;
  Future<void>? _initFuture;

  Future<void> initPackageInfo({String appType = 'ADMIN_APP', bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return;
    if (_initFuture != null && !forceRefresh) return _initFuture;

    _initFuture = _doInitPackageInfo(appType);
    return _initFuture;
  }

  Future<void> _doInitPackageInfo(String appType) async {
    _appType = appType;
    try {
      if (!kIsWeb) {
        final info = await PackageInfo.fromPlatform();
        _currentVersion = info.version.isNotEmpty ? info.version : '1.0.0';
        _currentBuildNumber = int.tryParse(info.buildNumber) ?? 1;
        _platform = Platform.isAndroid ? 'ANDROID' : (Platform.isIOS ? 'IOS' : (Platform.isWindows ? 'WINDOWS' : 'DESKTOP'));
      }
    } catch (e) {
      debugPrint('[UpdateProvider] Admin PackageInfo fallback: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Headers to attach to all ApiClient outgoing HTTP requests
  Map<String, String> getVersionHeaders() {
    return {
      'X-App-Type': _appType,
      'X-App-Platform': _platform,
      'X-App-Version': _currentVersion,
      'X-App-Build-Number': _currentBuildNumber.toString(),
    };
  }

  /// Perform version check against backend API endpoint
  Future<void> checkForUpdates({bool forceRefreshPackageInfo = false}) async {
    if (_isChecking) return; // Prevent concurrent version-check recursion

    _isChecking = true;
    try {
      // Re-read installed app build number from native platform OS binary
      if (!kIsWeb) {
        try {
          final info = await PackageInfo.fromPlatform();
          if (info.version.isNotEmpty) _currentVersion = info.version;
          final parsedBuild = int.tryParse(info.buildNumber);
          if (parsedBuild != null) _currentBuildNumber = parsedBuild;
        } catch (_) {}
      }

      final queryParams = {
        'appType': _appType,
        'platform': _platform,
        'currentVersion': _currentVersion,
        'currentBuildNumber': _currentBuildNumber.toString(),
      };

      final response = await _apiClient.get('/app-version/check', queryParams: queryParams);
      if (response != null && response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final bool isAvail = data['updateAvailable'] == true;
        final bool isForce = data['forceUpdate'] == true;

        _latestVersion = data['latestVersion'] ?? _currentVersion;
        _latestBuildNumber = data['latestBuildNumber'] ?? _currentBuildNumber;
        _releaseTitle = data['releaseTitle'] ?? 'New Admin Update Available';
        _releaseNotes = data['releaseNotes'] ?? '';
        _downloadUrl = data['downloadUrl'] ?? '';
        _websiteUrl = data['websiteUrl'] ?? '';
        _fileSizeBytes = data['fileSizeBytes'] ?? 0;
        _expectedSha256 = data['sha256Checksum'];

        // If the installed build actually matches or exceeds requirements, clear force update
        if (!isAvail && !isForce) {
          _updateAvailable = false;
          _forceUpdate = false;
          _status = DownloadStatus.idle;
        } else {
          _updateAvailable = isAvail;
          _forceUpdate = isForce;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[UpdateProvider] Admin update check error (non-fatal): $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Trigger force update state globally when API interceptor catches APP_UPDATE_REQUIRED
  void triggerForceUpdateFromApi(Map<String, dynamic> data) {
    // Single-flight lock: ignore duplicate 426 interceptor calls while already in update flow
    if (_forceUpdate && _status != DownloadStatus.idle) {
      return;
    }

    _updateAvailable = true;
    _forceUpdate = true;
    _latestVersion = data['latestVersion'] ?? _currentVersion;
    _latestBuildNumber = data['latestBuildNumber'] ?? _currentBuildNumber;
    _releaseTitle = data['releaseTitle'] ?? 'Admin Dashboard Update Required';
    _releaseNotes = data['releaseNotes'] ?? 'A newer admin version is required to continue.';
    _downloadUrl = data['downloadUrl'] ?? '';
    _websiteUrl = data['websiteUrl'] ?? '';
    _fileSizeBytes = data['fileSizeBytes'] ?? 0;
    _expectedSha256 = data['sha256Checksum'];

    notifyListeners();
  }

  void dismissOptionalUpdate() {
    _dismissedOptional = true;
    notifyListeners();
  }

  /// Download APK with real progress & SHA-256 validation
  Future<void> downloadAndInstallApk() async {
    if (_downloadUrl.isEmpty) {
      _errorMessage = 'Download URL is invalid or empty';
      _status = DownloadStatus.failed;
      notifyListeners();
      return;
    }

    if (_status == DownloadStatus.downloading ||
        _status == DownloadStatus.verifying ||
        _status == DownloadStatus.installing) {
      return; // Prevent concurrent duplicate downloads or install attempts
    }

    _status = DownloadStatus.downloading;
    _progress = 0.0;
    _receivedBytes = 0;
    _totalBytes = _fileSizeBytes;
    _errorMessage = null;
    _downloadSpeed = '0 KB/s';
    notifyListeners();

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (status.isDenied) {
          await Permission.requestInstallPackages.request();
        }
      }

      final dir = await getTemporaryDirectory();
      final apkName = 'update_${_appType.toLowerCase()}_$_latestVersion.apk';
      final file = File('${dir.path}/$apkName');

      if (await file.exists()) {
        await file.delete();
      }

      final client = http.Client();
      String fullDownloadUrl = _downloadUrl;
      if (!fullDownloadUrl.startsWith('http')) {
        final baseUrl = ApiConstants.baseUrl.endsWith('/')
            ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
            : ApiConstants.baseUrl;
        final relUrl = fullDownloadUrl.startsWith('/') ? fullDownloadUrl : '/$fullDownloadUrl';
        fullDownloadUrl = '$baseUrl$relUrl';
      }
      final request = http.Request('GET', Uri.parse(fullDownloadUrl));
      final response = await client.send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server returned HTTP ${response.statusCode} on APK download');
      }

      final contentLength = response.contentLength ?? _fileSizeBytes;
      if (contentLength > 0) _totalBytes = contentLength;

      final sink = file.openWrite();
      final stopwatch = Stopwatch()..start();
      int lastBytes = 0;
      int lastTimeMs = 0;
      double lastNotifiedProgress = 0.0;

      await for (final chunk in response.stream) {
        _receivedBytes += chunk.length;
        sink.add(chunk);

        if (_totalBytes > 0) {
          _progress = (_receivedBytes / _totalBytes).clamp(0.0, 1.0);
        }

        final elapsedMs = stopwatch.elapsedMilliseconds;
        final timePassed = (elapsedMs - lastTimeMs) >= 500;
        final progressPassed = (_progress - lastNotifiedProgress) >= 0.01;

        if (timePassed || progressPassed) {
          if (elapsedMs - lastTimeMs > 0) {
            final diffBytes = _receivedBytes - lastBytes;
            final diffSecs = (elapsedMs - lastTimeMs) / 1000.0;
            if (diffSecs > 0) {
              final bytesPerSec = diffBytes / diffSecs;
              if (bytesPerSec > 1024 * 1024) {
                _downloadSpeed = '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
              } else {
                _downloadSpeed = '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
              }
            }
            lastBytes = _receivedBytes;
            lastTimeMs = elapsedMs;
          }
          lastNotifiedProgress = _progress;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();
      stopwatch.stop();

      // Ensure final 100% download state is notified to UI before verification
      _progress = 1.0;
      if (_totalBytes > 0) _receivedBytes = _totalBytes;
      notifyListeners();

      _downloadedFilePath = file.path;

      if (_expectedSha256 != null && _expectedSha256!.isNotEmpty) {
        _status = DownloadStatus.verifying;
        notifyListeners();

        final fileBytes = await file.readAsBytes();
        final actualHash = sha256.convert(fileBytes).toString().toLowerCase();
        final expectedHash = _expectedSha256!.trim().toLowerCase();

        if (actualHash != expectedHash) {
          await file.delete();
          _status = DownloadStatus.failed;
          _errorMessage = 'Checksum verification failed. Download file was corrupted.';
          notifyListeners();
          return;
        }
      }

      _status = DownloadStatus.readyToInstall;
      notifyListeners();

      await triggerInstallation();
    } catch (e) {
      debugPrint('[UpdateProvider] Download APK Error: $e');
      _status = DownloadStatus.failed;
      _errorMessage = 'Download failed: ${e.toString().replaceAll('Exception:', '')}';
      notifyListeners();
    }
  }

  Future<void> triggerInstallation() async {
    if (_downloadedFilePath == null || !File(_downloadedFilePath!).existsSync()) {
      _status = DownloadStatus.failed;
      _errorMessage = 'Downloaded APK file is missing. Please retry.';
      notifyListeners();
      return;
    }

    if (_status == DownloadStatus.installing) return; // Prevent duplicate installer launches

    _status = DownloadStatus.installing;
    notifyListeners();

    try {
      if (!kIsWeb && Platform.isAndroid) {
        final installPerm = await Permission.requestInstallPackages.status;
        if (!installPerm.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      }

      final result = await OpenFilex.open(
        _downloadedFilePath!,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        // Installer intent was handed off to Android OS.
        _status = DownloadStatus.success;
      } else {
        debugPrint('[UpdateProvider] OpenFilex open result: ${result.type} - ${result.message}');
        _errorMessage = 'Package Installer: ${result.message}. Please grant "Install Unknown Apps" permission in device settings or tap "Download via Browser".';
        _status = DownloadStatus.readyToInstall;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Installation launch failed: $e';
      _status = DownloadStatus.readyToInstall;
      notifyListeners();
    }
  }

  void resetDownloadState() {
    _status = DownloadStatus.idle;
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
