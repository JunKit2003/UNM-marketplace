import 'package:dio/dio.dart';

/// Error returned by the API (`{ error: { code, message, fields } }`) or the network.
class ApiError implements Exception {
  ApiError({
    required this.status,
    required this.code,
    required this.message,
    this.fields = const {},
  });

  final int status;
  final String code;
  final String message;
  final Map<String, String> fields;

  bool get isUnauthenticated => status == 401;
  bool get isNotFound => status == 404;

  static ApiError from(Object error) {
    if (error is ApiError) return error;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final e = data['error'] as Map;
        return ApiError(
          status: error.response?.statusCode ?? 0,
          code: '${e['code']}',
          message: '${e['message']}',
          fields: {
            for (final entry in ((e['fields'] as Map?) ?? {}).entries)
              '${entry.key}': '${entry.value}',
          },
        );
      }
      return ApiError(
        status: error.response?.statusCode ?? 0,
        code: 'network',
        message:
            "Couldn't reach the server. Check your connection and try again.",
      );
    }
    return ApiError(
      status: 0,
      code: 'unknown',
      message: 'Something went wrong. Please try again.',
    );
  }

  @override
  String toString() => 'ApiError($status, $code, $message)';
}

/// Run a request and turn any failure into an [ApiError].
Future<T> guard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    throw ApiError.from(e);
  }
}
