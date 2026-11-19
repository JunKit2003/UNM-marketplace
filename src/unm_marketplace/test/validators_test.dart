import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/models.dart';
import 'package:unm_marketplace/features/sell/validators.dart';

void main() {
  test('validatePrice rejects what the API rejects', () {
    for (final bad in ['1,200', '-5', '12.345', '', '1000001', 'abc', ' ']) {
      expect(validatePrice(bad), isNotNull, reason: bad);
    }
    for (final ok in ['0', '12.5', '45', '1000000', '12.50']) {
      expect(validatePrice(ok), isNull, reason: ok);
    }
  });

  test('validatePhoto checks type and 5 MB size', () {
    PickedPhoto p(String name, int bytes) =>
        PickedPhoto(bytes: Uint8List(bytes), name: name);
    expect(validatePhoto(p('a.jpg', 100)), isNull);
    expect(validatePhoto(p('a.JPEG', 100)), isNull);
    expect(validatePhoto(p('a.webp', 100)), isNull);
    expect(validatePhoto(p('a.png', 5 * 1024 * 1024)), isNull);
    expect(validatePhoto(p('a.png', 5 * 1024 * 1024 + 1)), photoError);
    expect(validatePhoto(p('a.gif', 100)), photoError);
    expect(photoError, 'Photos must be JPEG, PNG or WebP, up to 5 MB.');
  });

  test('validateTitle', () {
    expect(validateTitle('ab'), isNotNull);
    expect(validateTitle('Desk lamp'), isNull);
    expect(validateTitle('x' * 81), isNotNull);
  });
}
