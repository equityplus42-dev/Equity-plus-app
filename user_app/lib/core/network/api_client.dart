import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';
import '../../providers/update_provider.dart';

class AppUpdateRequiredException implements Exception {
  final String message;
  final Map<String, dynamic>? data;
  AppUpdateRequiredException(this.message, [this.data]);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...UpdateProvider().getVersionHeaders(),
    };
    
    final token = _storage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    final int statusCode = response.statusCode;
    Map<String, dynamic> responseJson = {};
    try {
      responseJson = json.decode(response.body);
    } catch (_) {}

    // Global Interception for Mandatory App Update Required
    if (statusCode == 426 || responseJson['errorCode'] == 'APP_UPDATE_REQUIRED') {
      final updateData = responseJson['data'] ?? {};
      UpdateProvider().triggerForceUpdateFromApi(updateData);
      throw AppUpdateRequiredException(
        responseJson['message'] ?? 'A mandatory application update is required to continue.',
        updateData,
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      return responseJson;
    } else {
      final String errorMessage = responseJson['message'] ?? 'An error occurred';
      throw Exception(errorMessage);
    }
  }


  Future<http.Response> _sendWithFailover(
    Future<http.Response> Function(String baseUrl) requestFn,
  ) async {
    final List<String> candidates = [
      ApiConstants.activeBaseUrl,
      ...ApiConstants.candidateBaseUrls.where((url) => url != ApiConstants.activeBaseUrl),
    ];

    Object? lastError;
    for (final candidate in candidates) {
      try {
        final response = await requestFn(candidate).timeout(const Duration(seconds: 3));
        if (response.statusCode == 404 && candidate != candidates.last) {
          lastError = Exception('Resource not found (404) at $candidate');
          continue;
        }
        ApiConstants.activeBaseUrl = candidate;
        return response;
      } on Exception catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('socketexception') ||
            errStr.contains('clientexception') ||
            errStr.contains('timeoutexception') ||
            errStr.contains('connection refused') ||
            errStr.contains('connection failed')) {
          lastError = e;
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Network error: Could not reach backend server ($lastError)');
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final response = await _sendWithFailover((base) async {
        Uri uri = Uri.parse('$base$endpoint');
        if (queryParams != null) {
          uri = uri.replace(queryParameters: queryParams);
        }
        return await _client.get(uri, headers: _getHeaders());
      });
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _sendWithFailover((base) async {
        final Uri uri = Uri.parse('$base$endpoint');
        return await _client.post(
          uri,
          headers: _getHeaders(),
          body: json.encode(body),
        );
      });
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _sendWithFailover((base) async {
        final Uri uri = Uri.parse('$base$endpoint');
        return await _client.put(
          uri,
          headers: _getHeaders(),
          body: json.encode(body),
        );
      });
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _sendWithFailover((base) async {
        final Uri uri = Uri.parse('$base$endpoint');
        return await _client.patch(
          uri,
          headers: _getHeaders(),
          body: json.encode(body),
        );
      });
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _sendWithFailover((base) async {
        final Uri uri = Uri.parse('$base$endpoint');
        return await _client.delete(uri, headers: _getHeaders());
      });
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Upload user avatar using multipart request
  Future<dynamic> uploadAvatar(Uint8List fileBytes, String fileName) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadAvatar}');
    try {
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication headers
      final token = _storage.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Infer content type from filename
      MediaType contentType = MediaType('image', 'jpeg');
      if (fileName.toLowerCase().endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (fileName.toLowerCase().endsWith('.gif')) {
        contentType = MediaType('image', 'gif');
      } else if (fileName.toLowerCase().endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'avatar', 
        fileBytes, 
        filename: fileName,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      throw Exception('Upload network error: $e');
    }
  }
}
