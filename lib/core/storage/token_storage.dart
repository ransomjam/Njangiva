import 'token_storage_stub.dart'
    if (dart.library.io) 'token_storage_io.dart'
    if (dart.library.js_interop) 'token_storage_web.dart';

/// Immutable pair of access & refresh tokens with UTC expiration.
class AuthTokenPair {
  const AuthTokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Treats tokens as expired 60 seconds before wall-clock expiry so in-flight
  /// requests do not fail mid-transfer.
  bool get isExpired => DateTime.now().toUtc().isAfter(
    expiresAt.subtract(const Duration(seconds: 60)),
  );

  factory AuthTokenPair.fromJson(Map<String, dynamic> json) {
    final expiresIn = switch (json['expires_in']) {
      final int v => v,
      final String v => int.tryParse(v) ?? 3600,
      _ => 3600,
    };
    return AuthTokenPair(
      accessToken: (json['access_token'] as String?) ?? '',
      refreshToken: (json['refresh_token'] as String?) ?? '',
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: expiresIn)),
    );
  }
}

/// Abstract repository for storing sensitive authentication credentials.
///
/// - On Android / iOS / Desktop: uses `FlutterSecureStorage` (Keystore / Keychain).
/// - On Web: falls back cleanly to browser session/local storage via `package:web`.
abstract interface class TokenStorage {
  Future<AuthTokenPair?> readTokens();
  Future<void> saveTokens(AuthTokenPair tokens);
  Future<void> clearTokens();

  factory TokenStorage.createPlatformDefault() => createPlatformTokenStorage();
}

/// In-memory implementation used for unit and widget tests.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._tokens]);

  AuthTokenPair? _tokens;

  @override
  Future<AuthTokenPair?> readTokens() async => _tokens;

  @override
  Future<void> saveTokens(AuthTokenPair tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clearTokens() async {
    _tokens = null;
  }
}
