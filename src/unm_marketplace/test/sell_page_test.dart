import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/models.dart';

import 'fakes.dart';
import 'harness.dart';

PickedPhoto photo(String name, int size) => PickedPhoto(bytes: Uint8List(size), name: name);

void main() {
  testWidgets('needs a photo before Next', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser();
    await pumpApp(tester, fakes, '/sell');
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Add at least one photo.'), findsOneWidget);
    expect(find.text('Details'), findsWidgets);
  });

  testWidgets('rejects a 6 MB photo with the photo message', (tester) async {
    final fakes = Fakes()
      ..auth.user = fakeUser()
      ..nextPicked = [photo('big.jpg', 6 * 1024 * 1024)];
    await pumpApp(tester, fakes, '/sell');
    await tester.tap(find.byKey(const Key('add-photos')));
    await settle(tester);
    expect(find.text('Photos must be JPEG, PNG or WebP, up to 5 MB.'), findsOneWidget);
  });

  testWidgets('publishes a listing through the three steps', (tester) async {
    final fakes = Fakes()
      ..auth.user = fakeUser()
      ..nextPicked = [photo('lamp.jpg', 1000)];
    final h = await pumpApp(tester, fakes, '/sell');
    await tester.tap(find.byKey(const Key('add-photos')));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('field-title')), 'Desk lamp');
    await tester.enterText(find.byKey(const Key('field-price')), '45');
    await tester.enterText(find.byKey(const Key('field-description')), 'Warm light.');
    await tester.tap(find.byKey(const Key('field-category')));
    await settle(tester);
    await tester.tap(find.text('Home & Garden').last);
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.text('Review'), findsWidgets);
    await tester.tap(find.text('Publish'));
    await settle(tester);
    expect(fakes.listings.created?.title, 'Desk lamp');
    expect(fakes.listings.created?.price, '45');
    expect(fakes.listings.created?.categorySlug, 'home-garden');
    expect(fakes.listings.createdPhotos, hasLength(1));
    expect(find.text('Your listing is live.'), findsOneWidget);
    expect(h.location, '/listing/1');
  });

  testWidgets('blocks a bad price on the details step', (tester) async {
    final fakes = Fakes()
      ..auth.user = fakeUser()
      ..nextPicked = [photo('lamp.jpg', 1000)];
    await pumpApp(tester, fakes, '/sell');
    await tester.tap(find.byKey(const Key('add-photos')));
    await settle(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('field-price')), '1,200');
    await tester.tap(find.text('Next'));
    await settle(tester);
    expect(find.textContaining('Enter a price'), findsOneWidget);
  });
}
