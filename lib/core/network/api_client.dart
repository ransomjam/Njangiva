import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import '../utils/platform_info.dart';
import 'api_exception.dart';

/// Unified Cross-Platform Dio HTTP Client for NjangiSave.
///
/// Features:
/// - Automatic `Authorization: Bearer <token>` injection
/// - Single-flight 401 token refresh so concurrent 401s queue behind one refresh
/// - Cross-platform compatibility (Native sockets on Mobile & `fetch` on Web)
/// - Raw `Uint8List` multipart upload & byte download (no `dart:io` `File`)
///
/// **IMPORTANT BACKEND CORS WARNING FOR FLUTTER WEB**:
/// When running on Flutter Web, browsers enforce CORS preflight (`OPTIONS`) checks
/// whenever `Authorization` or custom headers (`X-NjangiSave-Platform`) are sent.
/// Your backend MUST return:
/// - `Access-Control-Allow-Origin: <origin>`
/// - `Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS`
/// - `Access-Control-Allow-Headers: Content-Type, Authorization, X-NjangiSave-Platform`
/// - `Access-Control-Allow-Credentials: true`
class NjangiApiClient {
  NjangiApiClient({
    required TokenStorage tokenStorage,
    String? baseUrl,
    Dio? dio,
  }) : _tokenStorage = tokenStorage,
       _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl ?? AppConstants.defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (_) => true,
      headers: {
        'Accept': 'application/json',
        'X-NjangiSave-Platform': PlatformInfo.platformName,
      },
    );

    if (kIsWeb) {
      _dio.options.extra['withCredentials'] = true;
    }

    _dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest));
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;
  Future<AuthTokenPair?>? _refreshInFlight;
  Future<void> Function()? onSessionExpired;

  Dio get raw => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    var tokens = await _tokenStorage.readTokens();
    if (tokens != null && tokens.isExpired && tokens.refreshToken.isNotEmpty) {
      tokens = await _refreshTokens();
    }

    if (tokens != null && tokens.accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }

    return handler.next(options);
  }

  Future<AuthTokenPair?> _refreshTokens() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthTokenPair?> _performRefresh() async {
    final current = await _tokenStorage.readTokens();
    if (current == null || current.refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final response = await _dio.post<dynamic>(
        '/api/auth/token/refresh',
        data: {'refresh_token': current.refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final body = response.data;
      if (response.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body['access_token'] != null) {
        final refreshed = AuthTokenPair.fromJson(body);
        await _tokenStorage.saveTokens(refreshed);
        return refreshed;
      }

      await _expireSession();
      return null;
    } on DioException {
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clearTokens();
    await onSessionExpired?.call();
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) async {
    return _send(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      ),
      allowAuthRetry: !skipAuth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) async {
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      ),
      allowAuthRetry: !skipAuth,
    );
  }

  /// Uploads raw `Uint8List` bytes across Mobile and Web without `dart:io` `File`.
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required Uint8List bytes,
    required String fileName,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formMap = <String, dynamic>{
      ...?extraFields,
      fieldName: MultipartFile.fromBytes(bytes, filename: fileName),
    };
    final formData = FormData.fromMap(formMap);

    return _send(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      ),
    );
  }

  /// Downloads raw `Uint8List` bytes from an endpoint.
  Future<Uint8List> downloadBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw ApiException.fromResponse(response);
      }
      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request, {
    bool allowAuthRetry = true,
  }) async {
    late Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }

    var status = response.statusCode ?? 0;
    if (status == 401 && allowAuthRetry) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        try {
          response = await request();
          status = response.statusCode ?? 0;
        } on DioException catch (e) {
          throw ApiException.fromDioException(e);
        }
      }
      if (status == 401) {
        await _expireSession();
      }
    }

    if (status >= 200 && status < 300) {
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{'data': data};
    }

    throw ApiException.fromResponse(response);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage.createPlatformDefault();
});

final apiClientProvider = Provider<NjangiApiClient>((ref) {
  return NjangiApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});
