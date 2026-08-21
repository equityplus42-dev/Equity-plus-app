import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/storage_service.dart';

class AdminReleaseProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  List<dynamic> _releases = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<dynamic> get releases => _releases;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReleases({String? appType, String? platform = 'ANDROID'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, String> queryParams = {};
      if (appType != null && appType.isNotEmpty) queryParams['appType'] = appType;
      if (platform != null && platform.isNotEmpty) queryParams['platform'] = platform;

      final response = await _apiClient.get('/app-version/admin/releases', queryParams: queryParams);
      if (response != null && response['success'] == true && response['data'] != null) {
        _releases = response['data']['releases'] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRelease({
    required String appType,
    required String platform,
    required String version,
    required int buildNumber,
    String? minimumSupportedVersion,
    int? minimumSupportedBuildNumber,
    required bool forceUpdate,
    String? releaseTitle,
    String? releaseNotes,
    String? downloadUrl,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (fileBytes != null && fileName != null && fileName.isNotEmpty) {
        // Multipart request for direct APK file upload
        final Uri uri = Uri.parse('${ApiConstants.baseUrl}/app-version/admin/releases');
        final request = http.MultipartRequest('POST', uri);

        final token = _storage.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['appType'] = appType;
        request.fields['platform'] = platform;
        request.fields['version'] = version;
        request.fields['buildNumber'] = buildNumber.toString();
        request.fields['forceUpdate'] = forceUpdate.toString();
        if (minimumSupportedVersion != null) request.fields['minimumSupportedVersion'] = minimumSupportedVersion;
        if (minimumSupportedBuildNumber != null) request.fields['minimumSupportedBuildNumber'] = minimumSupportedBuildNumber.toString();
        if (releaseTitle != null) request.fields['releaseTitle'] = releaseTitle;
        if (releaseNotes != null) request.fields['releaseNotes'] = releaseNotes;

        final multipartFile = http.MultipartFile.fromBytes(
          'apkFile',
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'vnd.android.package-archive'),
        );
        request.files.add(multipartFile);

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await fetchReleases(appType: appType);
          return true;
        } else {
          _errorMessage = 'Server returned HTTP ${response.statusCode} on APK upload';
          return false;
        }
      } else {
        // JSON request with external downloadUrl
        final body = {
          'appType': appType,
          'platform': platform,
          'version': version,
          'buildNumber': buildNumber,
          'minimumSupportedVersion': minimumSupportedVersion ?? version,
          'minimumSupportedBuildNumber': minimumSupportedBuildNumber ?? buildNumber,
          'forceUpdate': forceUpdate,
          'releaseTitle': releaseTitle,
          'releaseNotes': releaseNotes,
          'downloadUrl': downloadUrl,
        };

        final response = await _apiClient.post('/app-version/admin/releases', body);
        if (response != null && response['success'] == true) {
          await fetchReleases(appType: appType);
          return true;
        }
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> activateRelease(String releaseId, {String? currentAppType}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/app-version/admin/releases/$releaseId/activate', {});
      if (response != null && response['success'] == true) {
        await fetchReleases(appType: currentAppType);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deactivateRelease(String releaseId, {String? currentAppType}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/app-version/admin/releases/$releaseId/deactivate', {});
      if (response != null && response['success'] == true) {
        await fetchReleases(appType: currentAppType);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
