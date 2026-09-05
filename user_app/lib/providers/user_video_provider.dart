import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class UserVideoModel {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int duration;
  final String languageName;
  final String categoryId;
  final String categoryName;
  final String provider;   // 'CLOUDFLARE_R2', 'CLOUDINARY', 'CLOUDFLARE_STREAM', 'YOUTUBE'
  int watchedSecs;
  bool isCompleted;
  final bool isLocked;
  final String unlockNotice;

  UserVideoModel({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.languageName,
    this.categoryId = '',
    this.categoryName = 'Time Management',
    this.provider = 'CLOUDINARY',
    required this.watchedSecs,
    required this.isCompleted,
    this.isLocked = false,
    this.unlockNotice = 'Unlock after 25% learning progress or 30 days.',
  });

  factory UserVideoModel.fromJson(Map<String, dynamic> json) {
    return UserVideoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? 0,
      languageName: json['languageName'] ?? 'General',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? (json['category']?['name'] ?? 'Time Management'),
      provider: json['provider'] ?? 'CLOUDINARY',
      watchedSecs: json['watchedSecs'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      isLocked: json['isLocked'] ?? false,
      unlockNotice: json['unlockNotice'] ?? 'Unlock after 25% learning progress or 30 days.',
    );
  }
}

class SnapshotModel {
  final String? takenAt;
  final int videoCount;
  final int totalDurationSeconds;
  final bool refundEligible;
  final String? refundLostAt;
  final bool newVideosUnlocked;

  SnapshotModel({
    this.takenAt,
    required this.videoCount,
    required this.totalDurationSeconds,
    required this.refundEligible,
    this.refundLostAt,
    required this.newVideosUnlocked,
  });

  factory SnapshotModel.fromJson(Map<String, dynamic> json) {
    return SnapshotModel(
      takenAt: json['takenAt'] ?? json['snapshotTakenAt'],
      videoCount: (json['videoCount'] ?? json['snapshotVideoCount'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (json['totalDurationSeconds'] ?? json['snapshotTotalDurationSeconds'] as num?)?.toInt() ?? 0,
      refundEligible: json['refundEligible'] ?? true,
      refundLostAt: json['refundLostAt'],
      newVideosUnlocked: json['newVideosUnlocked'] ?? false,
    );
  }
}

class SnapshotProgressModel {
  final int totalWatchedSecs;
  final int totalSnapshotDurationSecs;
  final double percentage;
  final double remainingPercentage;
  final int daysJoined;
  final int remainingDays;
  final int remainingSecsTo25Percent;

  SnapshotProgressModel({
    required this.totalWatchedSecs,
    required this.totalSnapshotDurationSecs,
    required this.percentage,
    required this.remainingPercentage,
    required this.daysJoined,
    required this.remainingDays,
    required this.remainingSecsTo25Percent,
  });

  /// Human-readable label for the time remaining to reach 25% threshold.
  String get remainingSecsLabel {
    if (remainingSecsTo25Percent <= 0) return 'Reached';
    if (remainingSecsTo25Percent < 60) return '${remainingSecsTo25Percent}s';
    final mins = remainingSecsTo25Percent ~/ 60;
    final secs = remainingSecsTo25Percent % 60;
    return secs > 0 ? '${mins}m ${secs}s' : '${mins}m';
  }

  factory SnapshotProgressModel.fromJson(Map<String, dynamic> json) {
    return SnapshotProgressModel(
      totalWatchedSecs: (json['totalWatchedSecs'] as num?)?.toInt() ?? 0,
      totalSnapshotDurationSecs: (json['totalSnapshotDurationSecs'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      remainingPercentage: (json['remainingPercentage'] as num?)?.toDouble() ?? 100.0,
      daysJoined: (json['daysJoined'] as num?)?.toInt() ?? 0,
      remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 30,
      remainingSecsTo25Percent: (json['remainingSecsTo25Percent'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserVideoProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<UserVideoModel> _unlockedVideos = [];
  List<UserVideoModel> _lockedVideos = [];
  String? _assignedLanguageName;
  String? _assignedProductName;
  bool _isDisclaimerAccepted = false;
  bool _disclaimerNeedsReacceptance = false;
  int _currentDisclaimerVersion = 1;

  SnapshotModel? _snapshot;
  SnapshotProgressModel? _progress;

  bool _needsLanguageSelection = false;
  List<Map<String, dynamic>> _availableLanguages = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool _isTestUser = false;
  String? _selectedLanguageId;

  List<UserVideoModel> get unlockedVideos => _unlockedVideos;
  List<UserVideoModel> get lockedVideos => _lockedVideos;
  List<UserVideoModel> get allVideos => [..._unlockedVideos, ..._lockedVideos];
  String? get assignedLanguageName => _assignedLanguageName;
  String? get assignedProductName => _assignedProductName;
  bool get isDisclaimerAccepted => _isDisclaimerAccepted;
  bool get disclaimerNeedsReacceptance => _disclaimerNeedsReacceptance;
  int get currentDisclaimerVersion => _currentDisclaimerVersion;

  bool get isTestUser => _isTestUser;
  String? get selectedLanguageId => _selectedLanguageId;

  bool get needsLanguageSelection => _needsLanguageSelection;
  List<Map<String, dynamic>> get availableLanguages => _availableLanguages;

  SnapshotModel? get snapshot => _snapshot;
  SnapshotProgressModel? get progress => _progress;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserVideos({String? languageId}) async {
    _isLoading = true;
    _errorMessage = null;
    if (languageId != null) {
      _selectedLanguageId = languageId;
    }
    notifyListeners();

    try {
      String endpoint = ApiConstants.userVideos;
      if (_selectedLanguageId != null && _selectedLanguageId!.isNotEmpty) {
        endpoint += '?languageId=$_selectedLanguageId';
      }

      final response = await _apiClient.get(endpoint);
      final data = response['data'] ?? {};

      _isTestUser = data['isTestUser'] == true;

      _needsLanguageSelection = data['needsLanguageSelection'] == true;
      if (data['availableLanguages'] != null) {
        _availableLanguages = (data['availableLanguages'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _availableLanguages = [];
      }

      _isDisclaimerAccepted = data['isDisclaimerAccepted'] ?? false;
      _disclaimerNeedsReacceptance = data['disclaimerNeedsReacceptance'] ?? false;
      _currentDisclaimerVersion = data['currentDisclaimerVersion'] ?? 1;

      if (data['assignedLanguage'] != null) {
        _assignedLanguageName = data['assignedLanguage']['name'];
      } else {
        _assignedLanguageName = null;
      }

      if (data['assignedProduct'] != null) {
        _assignedProductName = data['assignedProduct']['name'];
      } else {
        _assignedProductName = null;
      }

      final snapshotData = data['userSnapshot'] ?? data['snapshot'];
      if (snapshotData != null) {
        _snapshot = SnapshotModel.fromJson(snapshotData);
      } else {
        _snapshot = null;
      }

      final progressData = data['userSnapshot'] ?? data['progress'];
      if (progressData != null) {
        _progress = SnapshotProgressModel.fromJson(progressData);
      } else {
        _progress = null;
      }

      final List rawUnlocked = data['unlockedVideos'] ?? [];
      _unlockedVideos = rawUnlocked.map((item) => UserVideoModel.fromJson(item)).toList();

      final List rawLocked = data['lockedVideos'] ?? [];
      _lockedVideos = rawLocked.map((item) => UserVideoModel.fromJson(item)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> filterByLanguage(String? languageId) async {
    _selectedLanguageId = languageId;
    await fetchUserVideos();
  }

  Future<bool> selectLanguage(String languageId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(ApiConstants.selectLanguage, {
        'languageId': languageId,
      });
      final data = response['data'] ?? {};
      _needsLanguageSelection = false;

      _isDisclaimerAccepted = data['isDisclaimerAccepted'] ?? false;
      _disclaimerNeedsReacceptance = data['disclaimerNeedsReacceptance'] ?? false;
      _currentDisclaimerVersion = data['currentDisclaimerVersion'] ?? 1;

      if (data['assignedLanguage'] != null) {
        _assignedLanguageName = data['assignedLanguage']['name'];
      }

      if (data['assignedProduct'] != null) {
        _assignedProductName = data['assignedProduct']['name'];
      }

      final snapshotData = data['userSnapshot'] ?? data['snapshot'];
      if (snapshotData != null) {
        _snapshot = SnapshotModel.fromJson(snapshotData);
      }
      final progressData = data['userSnapshot'] ?? data['progress'];
      if (progressData != null) {
        _progress = SnapshotProgressModel.fromJson(progressData);
      }

      final List rawUnlocked = data['unlockedVideos'] ?? [];
      _unlockedVideos = rawUnlocked.map((item) => UserVideoModel.fromJson(item)).toList();

      final List rawLocked = data['lockedVideos'] ?? [];
      _lockedVideos = rawLocked.map((item) => UserVideoModel.fromJson(item)).toList();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptDisclaimer() async {
    try {
      await _apiClient.post(ApiConstants.acceptDisclaimer, {});
      _isDisclaimerAccepted = true;
      _disclaimerNeedsReacceptance = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> recordProgress(String videoId, int watchedSecs) async {
    try {
      final vIndex = _unlockedVideos.indexWhere((item) => item.id == videoId);
      if (vIndex != -1) {
        _unlockedVideos[vIndex].watchedSecs = math.max(_unlockedVideos[vIndex].watchedSecs, watchedSecs);
        notifyListeners();
      }

      await _apiClient.post(ApiConstants.recordVideoProgress(videoId), {
        'watchedSecs': watchedSecs,
      });

      await fetchUserVideos();
    } catch (e) {
      debugPrint('Error recording video progress: $e');
    }
  }

  Future<void> recordPlaybackHeartbeat(String videoId, int sessionWatchedSecs) async {
    try {
      await _apiClient.post(ApiConstants.recordPlaybackHeartbeat(videoId), {
        'sessionWatchedSecs': sessionWatchedSecs,
      });
      await fetchUserVideos();
    } catch (e) {
      debugPrint('Error recording playback heartbeat: $e');
    }
  }
}
