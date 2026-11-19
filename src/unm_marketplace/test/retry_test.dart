import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/api_error.dart';
import 'package:unm_marketplace/state/retry.dart';

ApiError err(int status) => ApiError(status: status, code: 'x', message: 'x');

void main() {
  test('client errors are never retried', () {
    for (final s in [400, 401, 403, 404, 409, 429]) {
      expect(retryPolicy(0, err(s)), isNull, reason: '$s');
    }
  });

  test(
    'network and server errors are retried with backoff, at most 3 times',
    () {
      expect(retryPolicy(0, err(0)), const Duration(milliseconds: 500));
      expect(retryPolicy(1, err(503)), const Duration(seconds: 1));
      expect(retryPolicy(2, err(500)), const Duration(seconds: 2));
      expect(retryPolicy(3, err(500)), isNull);
    },
  );

  test('unknown errors are not retried', () {
    expect(retryPolicy(0, StateError('bug')), isNull);
  });
}
