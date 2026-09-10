import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class PasskeyCredentialModel {
  final String id;
  final String name;
  final String deviceType;
  final bool backedUp;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  PasskeyCredentialModel({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.backedUp,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory PasskeyCredentialModel.fromJson(Map<String, dynamic> json) {
    return PasskeyCredentialModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Passkey',
      deviceType: json['deviceType'] ?? 'singleDevice',
      backedUp: json['backedUp'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'])
          : null,
    );
  }
}

class PasskeyService {
  static final PasskeyService _instance = PasskeyService._internal();
  factory PasskeyService() => _instance;
  PasskeyService._internal();

  static const MethodChannel _channel = MethodChannel('com.referral.user_app/passkey');
  final ApiClient _apiClient = ApiClient();

  /// Checks if Passkeys are supported on the current device and platform
  Future<bool> isSupported() async {
    if (kIsWeb) {
      return true;
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final supported = await _channel.invokeMethod<bool>('isPasskeySupported');
        return supported ?? false;
      } catch (e) {
        debugPrint('[PasskeyService] isSupported error: $e');
        return false;
      }
    }
    return false;
  }

  /// Initiates Passkey login (supports discoverable / resident passkeys without typing email)
  Future<Map<String, dynamic>?> loginWithPasskey({String? email}) async {
    // 1. Fetch authentication challenge from backend
    final optionsRes = await _apiClient.post('/auth/passkey/login/options', {
      if (email != null && email.isNotEmpty) 'email': email,
    });

    final options = optionsRes['data'];
    if (options == null) {
      throw Exception('Failed to receive authentication challenge from server');
    }

    // 2. Invoke native platform authenticator (Android Credential Manager)
    String? assertionJson;
    try {
      assertionJson = await _channel.invokeMethod<String>('getPasskey', {
        'requestJson': jsonEncode(options),
      });
    } on PlatformException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        // User backed out of biometric prompt — silently return null without showing error
        return null;
      }
      throw Exception(e.message ?? 'Passkey authentication failed');
    }

    if (assertionJson == null || assertionJson.isEmpty) {
      return null;
    }

    // 3. Send WebAuthn assertion to backend to verify and issue standard JWT
    final verifyRes = await _apiClient.post('/auth/passkey/login/verify', {
      'response': jsonDecode(assertionJson),
    });

    final data = verifyRes['data'];
    return {
      'user': UserModel.fromJson(data['user']),
      'token': data['token'] as String,
      'passkeyUsed': data['passkeyUsed'],
    };
  }

  /// Verifies Passkey identity for Password Reset without requiring an Email OTP
  Future<Map<String, dynamic>?> verifyPasskeyForReset({String? email}) async {
    // 1. Fetch authentication challenge from backend
    final optionsRes = await _apiClient.post('/auth/passkey/login/options', {
      if (email != null && email.isNotEmpty) 'email': email,
    });

    final options = optionsRes['data'];
    if (options == null) {
      throw Exception('Failed to receive authentication challenge from server');
    }

    // 2. Invoke native platform authenticator (Android Credential Manager)
    String? assertionJson;
    try {
      assertionJson = await _channel.invokeMethod<String>('getPasskey', {
        'requestJson': jsonEncode(options),
      });
    } on PlatformException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        return null;
      }
      throw Exception(e.message ?? 'Passkey verification failed');
    }

    if (assertionJson == null || assertionJson.isEmpty) {
      return null;
    }

    // 3. Send WebAuthn assertion to backend to issue verified resetToken
    final verifyRes = await _apiClient.post('/auth/passkey/reset-password/verify', {
      'response': jsonDecode(assertionJson),
    });

    final data = verifyRes['data'];
    return {
      'email': data['email'] as String,
      'resetToken': data['resetToken'] as String,
      'passkeyName': data['passkeyName'] as String?,
    };
  }

  /// Registers a new Passkey on the current device for the authenticated user
  Future<PasskeyCredentialModel?> registerPasskey({String? nickname}) async {
    // 1. Fetch registration options from backend
    final optionsRes = await _apiClient.post('/auth/passkey/register/options', {});
    final options = optionsRes['data'];
    if (options == null) {
      throw Exception('Failed to receive registration challenge from server');
    }

    // 2. Invoke native platform authenticator to generate public/private keypair
    String? attestationJson;
    try {
      attestationJson = await _channel.invokeMethod<String>('createPasskey', {
        'requestJson': jsonEncode(options),
      });
    } on PlatformException catch (e) {
      if (e.code == 'USER_CANCELLED') {
        return null;
      }
      throw Exception(e.message ?? 'Passkey creation failed');
    }

    if (attestationJson == null || attestationJson.isEmpty) {
      return null;
    }

    // 3. Send attestation response to backend to store public key
    final verifyRes = await _apiClient.post('/auth/passkey/register/verify', {
      'response': jsonDecode(attestationJson),
      'name': nickname ?? 'My Passkey',
    });

    return PasskeyCredentialModel.fromJson(verifyRes['data']);
  }

  /// Lists all passkeys registered to the current authenticated user
  Future<List<PasskeyCredentialModel>> listPasskeys() async {
    final res = await _apiClient.get('/auth/passkey/credentials');
    final List list = res['data'] ?? [];
    return list.map((item) => PasskeyCredentialModel.fromJson(item)).toList();
  }

  /// Deletes a passkey
  Future<bool> deletePasskey(String id) async {
    final res = await _apiClient.delete('/auth/passkey/credentials/$id');
    return res['success'] == true;
  }

  /// Renames a passkey
  Future<bool> renamePasskey(String id, String newName) async {
    final res = await _apiClient.patch('/auth/passkey/credentials/$id', {
      'name': newName,
    });
    return res['success'] == true;
  }
}
