import 'package:web/web.dart' as web;
import 'token_storage.dart';

TokenStorage createPlatformTokenStorage() => WebSessionTokenStorage();

/// Web implementation using `package:web` sessionStorage with localStorage fallback.
/// Complies with modern WASM / JS-Interop rules without `dart:html`.
class WebSessionTokenStorage implements TokenStorage {
  static const String _accessKey = 'njangisave.access_token';
  static const String _refreshKey = 'njangisave.refresh_token';
  static const String _expiryKey = 'njangisave.token_expiry';

  AuthTokenPair? _cached;

  @override
  Future<AuthTokenPair?> readTokens() async {
    if (_cached != null) return _cached;
    try {
      final storage = web.window.sessionStorage;
      final access =
          storage.getItem(_accessKey) ??
          web.window.localStorage.getItem(_accessKey);
      if (access == null || access.isEmpty) return null;

      final refresh =
          storage.getItem(_refreshKey) ??
          web.window.localStorage.getItem(_refreshKey) ??
          '';
      final expiryRaw =
          storage.getItem(_expiryKey) ??
          web.window.localStorage.getItem(_expiryKey);
      final expiresAt = DateTime.tryParse(expiryRaw ?? '')?.toUtc();
      if (expiresAt == null) {
        await clearTokens();
        return null;
      }

      return _cached = AuthTokenPair(
        accessToken: access,
        refreshToken: refresh,
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
      web.window.sessionStorage.setItem(_accessKey, tokens.accessToken);
      web.window.sessionStorage.setItem(_refreshKey, tokens.refreshToken);
      web.window.sessionStorage.setItem(
        _expiryKey,
        tokens.expiresAt.toIso8601String(),
      );
    } catch (_) {}
  }

  @override
  Future<void> clearTokens() async {
    _cached = null;
    try {
      web.window.sessionStorage.removeItem(_accessKey);
      web.window.sessionStorage.removeItem(_refreshKey);
      web.window.sessionStorage.removeItem(_expiryKey);
      web.window.localStorage.removeItem(_accessKey);
      web.window.localStorage.removeItem(_refreshKey);
      web.window.localStorage.removeItem(_expiryKey);
    } catch (_) {}
  }
}
