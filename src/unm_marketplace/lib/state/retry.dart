import '../core/api/api_error.dart';

/// Riverpod retry policy: only retry failures that might fix themselves (network
/// down, 5xx), at most 3 times. A 404 or 403 will not change by asking again.
Duration? retryPolicy(int retryCount, Object error) {
  if (retryCount >= 3) return null;
  if (error is! ApiError) return null;
  final transient = error.status == 0 || error.status >= 500;
  if (!transient) return null;
  return Duration(milliseconds: 500 * (1 << retryCount));
}
