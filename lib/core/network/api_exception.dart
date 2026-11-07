import 'package:dio/dio.dart';

enum ApiErrorKind {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  rateLimited,
  server,
  corsOrPreflight,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.code,
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;
  final String? code;

  factory ApiException.fromDioException(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        kind: ApiErrorKind.corsOrPreflight,
        message:
            'Could not reach the server. On Flutter Web, verify backend CORS headers '
            '(Access-Control-Allow-Origin and OPTIONS preflight).',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        kind: ApiErrorKind.network,
        message: 'Request timed out. Please check your internet connection.',
      );
    }
    final response = error.response;
    if (response != null) {
      return ApiException.fromResponse(response);
    }
    return ApiException(
      kind: ApiErrorKind.unknown,
      message: error.message ?? 'An unexpected network error occurred.',
    );
  }

  factory ApiException.fromResponse(Response<dynamic> response) {
    final status = response.statusCode ?? 500;
    final data = response.data;
    var message = 'Request failed with status $status.';
    String? code;

    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? message).toString();
      code = data['code']?.toString() ?? data['error']?.toString();
    }

    final kind = switch (status) {
      400 || 422 => ApiErrorKind.validation,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      429 => ApiErrorKind.rateLimited,
      >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };

    return ApiException(
      kind: kind,
      message: message,
      statusCode: status,
      code: code,
    );
  }

  @override
  String toString() => 'ApiException($kind, status=$statusCode): $message';
}
