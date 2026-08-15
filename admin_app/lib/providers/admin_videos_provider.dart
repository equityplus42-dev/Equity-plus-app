import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class AdminVideoModel {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int duration;
  final String languageId;
  final String languageName;
  final String status;
  final int orderIndex;
  final bool isAssignedToSnapshot;
  final String createdAt;

  AdminVideoModel({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.languageId,
    required this.languageName,
    required this.status,
    required this.orderIndex,
    required this.isAssignedToSnapshot,
    required this.createdAt,
  });

  factory AdminVideoModel.fromJson(Map<String, dynamic> json) {
    return AdminVideoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? 0,
      languageId: json['languageId'],
      languageName: json['language'] != null ? json['language']['name'] : 'Unknown',
      status: json['status'] ?? 'AVAILABLE',
      orderIndex: json['orderIndex'] ?? 0,
      isAssignedToSnapshot: json['isAssignedToSnapshot'] == true || json['deletionProtected'] == true,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class AdminVideosProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<AdminVideoModel> _videos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminVideoModel> get videos => _videos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVideos({String? languageId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = languageId != null && languageId.isNotEmpty
          ? {'languageId': languageId}
          : null;
      final response = await _apiClient.get(ApiConstants.adminVideos, queryParams: queryParams);
      final List data = response['data'] ?? [];
      _videos = data.map((item) => AdminVideoModel.fromJson(item)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> createVideo({
    required String title,
    String? description,
    required String videoUrl,
    String? thumbnailUrl,
    required String languageId,
    int? duration,
    String? r2ObjectKey,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(ApiConstants.adminVideos, {
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'languageId': languageId,
        if (duration != null && duration > 0) 'duration': duration,
        if (r2ObjectKey != null && r2ObjectKey.isNotEmpty) 'r2ObjectKey': r2ObjectKey,
      });
      await fetchVideos(languageId: languageId);
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reorderVideos(List<Map<String, dynamic>> videoOrders, {String? languageId}) async {
    try {
      await _apiClient.patch(ApiConstants.reorderVideos, {
        'videoOrders': videoOrders,
      });
      await fetchVideos(languageId: languageId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVideo(String id, {String? languageId}) async {
    try {
      // Instantly remove locally from provider state by exact video ID
      _videos.removeWhere((v) => v.id == id);
      notifyListeners();

      await _apiClient.delete('${ApiConstants.adminVideos}/$id');
      await fetchVideos(languageId: languageId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      await fetchVideos(languageId: languageId);
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignUserLanguage(String userId, String languageId) async {
    try {
      await _apiClient.put(ApiConstants.assignUserLanguage(userId), {
        'languageId': languageId,
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
