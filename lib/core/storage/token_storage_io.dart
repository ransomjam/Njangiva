import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'token_storage.dart';

TokenStorage createPlatformTokenStorage() => SecureNativeTokenStorage();

/// Native implementation backed by `FlutterSecureStorage` (Android Keystore,
/// iOS Keychain, Windows DPAPI).
class SecureNativeTokenStorage implements TokenStorage {
  SecureNativeTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  static const String _accessKey = 'njangisave.access_token';
  static const String _refreshKey = 'njangisave.refresh_token';
  static const String _expiryKey = 'njangisave.token_expiry';

  AuthTokenPair? _cached;

  @override
  Future<AuthTokenPair?> readTokens() async {
    if (_cached != null) return _cached;
    try {
      final access = await _storage.read(key: _accessKey);
      if (access == null || access.isEmpty) return null;
      final refresh = await _storage.read(key: _refreshKey);
      final expiryRaw = await _storage.read(key: _expiryKey);
      final expiresAt = DateTime.tryParse(expiryRaw ?? '')?.toUtc();
      if (expiresAt == null) {
        await clearTokens();
        return null;
      }
      return _cached = AuthTokenPair(
        accessToken: access,
        refreshToken: refresh ?? '',
        expiresAt: expiresAt,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTokens(AuthTokenPair tokens) async {
    _cached = tokens;
    try {
      await Future.wait([
        _storage.write(key: _accessKey, value: tokens.accessToken),
        _storage.write(key: _refreshKey, value: tokens.refreshToken),
        _storage.write(
          key: _expiryKey,
          value: tokens.expiresAt.toIso8601String(),
        ),
      ]);
    } catch (_) {}
  }

  @override
  Future<void> clearTokens() async {
    _cached = null;
    try {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
        _storage.delete(key: _expiryKey),
      ]);
    } catch (_) {}
  }
}
