import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import '../core/network/api_client.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static const String _keyPendingRefCode = 'pending_referral_code';
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  final StreamController<String> _codeStreamController = StreamController<String>.broadcast();
  Stream<String> get referralCodeStream => _codeStreamController.stream;

  /// Initialize App Links listener on app cold/warm start
  Future<void> initDeepLinks() async {
    try {
      _appLinks = AppLinks();

      // Check initial link on cold launch
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }

      // Listen for incoming deep links while app is warm/running
      _sub = _appLinks.uriLinkStream.listen(
        (Uri uri) => _handleIncomingUri(uri),
        onError: (err) => debugPrint('[DeepLinkService] AppLinks stream error: $err'),
      );
    } catch (e) {
      debugPrint('[DeepLinkService] Failed to initialize AppLinks: $e');
    }
  }

  void _handleIncomingUri(Uri uri) {
    debugPrint('[DeepLinkService] Incoming link: $uri');
    String? refCode;

    if (uri.queryParameters.containsKey('ref')) {
      refCode = uri.queryParameters['ref'];
    } else if (uri.pathSegments.isNotEmpty) {
      final lastSeg = uri.pathSegments.last;
      if (uri.pathSegments.contains('r') || lastSeg.length >= 4) {
        refCode = lastSeg;
      }
    }

    if (refCode != null && refCode.trim().isNotEmpty) {
      savePendingReferralCode(refCode.trim().toUpperCase());
    }
  }

  /// Save pending referral code into persistent storage
  Future<void> savePendingReferralCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingRefCode, cleanCode);
    _codeStreamController.add(cleanCode);
    debugPrint('[DeepLinkService] Pending referral code saved & broadcasted: $cleanCode');
  }

  /// Get or recover pending referral code using multi-layer fallback pipeline
  Future<String?> getOrRecoverPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check local SharedPreferences storage
    String? code = prefs.getString(_keyPendingRefCode);
    if (code != null && code.trim().isNotEmpty) {
      return code.trim().toUpperCase();
    }

    // 2. Query Backend IP-based Deferred Referral Lookup API
    try {
      final response = await ApiClient().get('/referrals/deferred-lookup');
      final data = response['data'] ?? {};
      final String? deferredCode = data['referralCode'];
      if (deferredCode != null && deferredCode.trim().isNotEmpty) {
        final cleanCode = deferredCode.trim().toUpperCase();
        await savePendingReferralCode(cleanCode);
        return cleanCode;
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Deferred API lookup non-fatal error: $e');
    }

    // 3. Fallback: Check device Clipboard for referral code, URL parameter, or shared message
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipText = clipboardData?.text?.trim();
      if (clipText != null && clipText.isNotEmpty) {
        String? extractedCode;
        if (clipText.contains('ref=')) {
          final match = RegExp(r'ref=([A-Za-z0-9_-]+)').firstMatch(clipText);
          if (match != null) extractedCode = match.group(1);
        } else if (clipText.contains('/r/')) {
          final match = RegExp(r'/r/([A-Za-z0-9_-]+)').firstMatch(clipText);
          if (match != null) extractedCode = match.group(1);
        } else if (RegExp(r'^[A-Za-z0-9_-]{4,20}$').hasMatch(clipText)) {
          extractedCode = clipText;
        }

        if (extractedCode != null && extractedCode.trim().isNotEmpty) {
          final cleanCode = extractedCode.trim().toUpperCase();
          await savePendingReferralCode(cleanCode);
          return cleanCode;
        }
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Clipboard fallback check error: $e');
    }

    return null;
  }

  /// Clear stored pending referral code after registration completion
  Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingRefCode);
  }

  void dispose() {
    _sub?.cancel();
  }
}
