import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  final http.Client _client = http.Client();
  final StorageService _storage = StorageService();

  Map<String, String> _getHeaders() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final token = _storage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final Map<String, dynamic> responseJson = json.decode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return responseJson;
    } else {
      final String errorMessage = responseJson['message'] ?? 'An error occurred';
      throw Exception(errorMessage);
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.get(uri, headers: _getHeaders());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: json.encode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.put(
        uri,
        headers: _getHeaders(),
        body: json.encode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.patch(
        uri,
        headers: _getHeaders(),
        body: json.encode(body),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.delete(uri, headers: _getHeaders());
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /**
   * Upload user avatar using multipart request
   */
  Future<dynamic> uploadAvatar(Uint8List fileBytes, String fileName) async {
    final Uri uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadAvatar}');
    try {
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication headers
      final token = _storage.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      final multipartFile = http.MultipartFile.fromBytes(
        'avatar', 
        fileBytes, 
        filename: fileName
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
