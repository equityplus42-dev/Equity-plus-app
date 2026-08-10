import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class AssignmentDashboardStats {
  final int totalVideos;
  final int assignedVideos;
  final int unassignedVideos;
  final int activeAssignments;
  final int usersWithAccess;
  final int snapshotProtectedVideosCount;

  AssignmentDashboardStats({
    required this.totalVideos,
    required this.assignedVideos,
    required this.unassignedVideos,
    required this.activeAssignments,
    required this.usersWithAccess,
    required this.snapshotProtectedVideosCount,
  });

  factory AssignmentDashboardStats.fromJson(Map<String, dynamic> json) {
    return AssignmentDashboardStats(
      totalVideos: json['totalVideos'] ?? 0,
      assignedVideos: json['assignedVideos'] ?? 0,
      unassignedVideos: json['unassignedVideos'] ?? 0,
      activeAssignments: json['activeAssignments'] ?? 0,
      usersWithAccess: json['usersWithAccess'] ?? 0,
      snapshotProtectedVideosCount: json['snapshotProtectedVideosCount'] ?? 0,
    );
  }
}

class VideoAssignmentItem {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int duration;
  final String languageId;
  final String languageName;
  final String? productId;
  final String? productName;
  final String status;
  final int orderIndex;
  final int activeAccessCount;
  final int snapshotUserCount;
  final bool isSnapshotProtected;
  final String assignmentStatus;
  final String assignmentLabel;
  final String createdAt;

  VideoAssignmentItem({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.languageId,
    required this.languageName,
    this.productId,
    this.productName,
    required this.status,
    required this.orderIndex,
    required this.activeAccessCount,
    required this.snapshotUserCount,
    required this.isSnapshotProtected,
    required this.assignmentStatus,
    required this.assignmentLabel,
    required this.createdAt,
  });

  factory VideoAssignmentItem.fromJson(Map<String, dynamic> json) {
    return VideoAssignmentItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? 0,
      languageId: json['languageId'],
      languageName: json['languageName'] ?? 'Unknown',
      productId: json['productId'],
      productName: json['productName'],
      status: json['status'] ?? 'AVAILABLE',
      orderIndex: json['orderIndex'] ?? 0,
      activeAccessCount: json['activeAccessCount'] ?? 0,
      snapshotUserCount: json['snapshotUserCount'] ?? 0,
      isSnapshotProtected: json['isSnapshotProtected'] == true,
      assignmentStatus: json['assignmentStatus'] ?? 'UNASSIGNED',
      assignmentLabel: json['assignmentLabel'] ?? 'Unassigned',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class AssignedUserRecord {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String languageName;
  final String productName;
  final String assignedAt;
  final String status;
  final bool inSnapshot;
  final int watchedSecs;
  final bool isCompleted;

  AssignedUserRecord({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.languageName,
    required this.productName,
    required this.assignedAt,
    required this.status,
    required this.inSnapshot,
    required this.watchedSecs,
    required this.isCompleted,
  });

  factory AssignedUserRecord.fromJson(Map<String, dynamic> json) {
    return AssignedUserRecord(
      userId: json['userId'],
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      languageName: json['languageName'] ?? 'Unknown',
      productName: json['productName'] ?? 'None',
      assignedAt: json['assignedAt'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      inSnapshot: json['inSnapshot'] == true,
      watchedSecs: json['watchedSecs'] ?? 0,
      isCompleted: json['isCompleted'] == true,
    );
  }

  String get fullName => '$firstName $lastName'.trim().isEmpty ? email : '$firstName $lastName'.trim();
}

class AdminVideoAssignmentsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  AssignmentDashboardStats? _stats;
  List<VideoAssignmentItem> _assignmentItems = [];
  List<AssignedUserRecord> _assignedUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  AssignmentDashboardStats? get stats => _stats;
  List<VideoAssignmentItem> get assignmentItems => _assignmentItems;
  List<AssignedUserRecord> get assignedUsers => _assignedUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchDashboardStats() async {
    try {
      final response = await _apiClient.get('/admin/video-assignments/stats');
      if (response['data'] != null) {
        _stats = AssignmentDashboardStats.fromJson(response['data']);
        _safeNotify();
      }
    } catch (e) {
      debugPrint('Error fetching assignment stats: $e');
    }
  }

  Future<void> fetchVideoAssignments({String? languageId, String? productId, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final queryParams = <String, String>{};
      if (languageId != null && languageId.isNotEmpty) queryParams['languageId'] = languageId;
      if (productId != null && productId.isNotEmpty) queryParams['productId'] = productId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get('/admin/video-assignments', queryParams: queryParams.isNotEmpty ? queryParams : null);
      final List items = response['data']?['items'] ?? [];
      _assignmentItems = items.map((i) => VideoAssignmentItem.fromJson(i)).toList();
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
    }
  }

  Future<Map<String, dynamic>?> fetchVideoAssignmentDetails(String videoId, {String? search}) async {
    _isLoading = true;
    _safeNotify();

    try {
      final queryParams = search != null && search.isNotEmpty ? {'search': search} : null;
      final response = await _apiClient.get('/admin/video-assignments/$videoId', queryParams: queryParams);
      _isLoading = false;

      final List users = response['data']?['assignedUsers'] ?? [];
      _assignedUsers = users.map((u) => AssignedUserRecord.fromJson(u)).toList();
      _safeNotify();
      return response['data'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  Future<bool> assignVideoToUser(String userId, String videoId) async {
    try {
      await _apiClient.post('/admin/video-assignments/assign', {
        'userId': userId,
        'videoId': videoId,
      });
      await fetchDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return false;
    }
  }

  Future<bool> bulkAssignVideo(String videoId, List<String> userIds) async {
    try {
      await _apiClient.post('/admin/video-assignments/bulk-assign', {
        'videoId': videoId,
        'userIds': userIds,
      });
      await fetchDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return false;
    }
  }

  Future<Map<String, dynamic>?> unassignVideoFromUser(String userId, String videoId) async {
    try {
      final response = await _apiClient.post('/admin/video-assignments/$videoId/unassign', {
        'userId': userId,
      });
      _assignedUsers.removeWhere((u) => u.userId == userId);
      _safeNotify();
      await fetchDashboardStats();
      return response['data'];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserVideoAccessDetailsAdmin(String userId) async {
    try {
      final response = await _apiClient.get('/admin/video-assignments/user/$userId');
      return response['data'];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }

  Future<Map<String, dynamic>?> forceDeleteVideo(String videoId) async {
    try {
      final response = await _apiClient.delete('/admin/video-assignments/$videoId/force-delete');
      await fetchDashboardStats();
      await fetchVideoAssignments();
      return response['data'];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }
}
