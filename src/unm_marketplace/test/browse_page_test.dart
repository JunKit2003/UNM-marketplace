import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/models.dart';

import 'fakes.dart';
import 'harness.dart';
import 'samples.dart';

List<Listing> manyListings(int n) => [
      for (var i = 1; i <= n; i++) Listing.fromJson(listingJson(id: i, title: 'Item $i', price: i * 10)),
    ];

void main() {
  testWidgets('shows the hero and a card per listing', (tester) async {
    final fakes = Fakes()..listings.listings = manyListings(3)..listings.total = 3;
    await pumpApp(tester, fakes, '/');
    expect(find.text('Buy, sell and swap on campus.'), findsOneWidget);
    expect(find.text('Try the demo'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('RM 30'), findsOneWidget);
  });

  testWidgets('search and category update the URL', (tester) async {
    final fakes = Fakes();
    final h = await pumpApp(tester, fakes, '/');
    await tester.enterText(find.byKey(const Key('search-field')), 'lamp');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(h.location, '/?q=lamp');
    await tester.tap(find.byKey(const Key('category-home-garden')));
    await settle(tester);
    expect(h.location, '/?q=lamp&category=home-garden');
    expect(fakes.listings.searches.last.$1.categorySlug, 'home-garden');
    expect(fakes.listings.searches.last.$1.q, 'lamp');
  });

  testWidgets('reads filters from the URL', (tester) async {
    final fakes = Fakes();
    await pumpApp(tester, fakes, '/?q=desk&sort=price_asc&min=10');
    final f = fakes.listings.searches.last.$1;
    expect((f.q, f.sort, f.min), ('desk', 'price_asc', 10));
  });

  testWidgets('loads the next page near the end of the list', (tester) async {
    final fakes = Fakes()..listings.listings = manyListings(30)..listings.total = 30;
    await pumpApp(tester, fakes, '/');
    expect(fakes.listings.searches.map((s) => s.$2), [1]);
    await tester.fling(find.byType(CustomScrollView), const Offset(0, -20000), 5000);
    await settle(tester);
    expect(fakes.listings.searches.map((s) => s.$2), [1, 2]);
    expect(find.text('Item 30', skipOffstage: false), findsOneWidget);
  });

  testWidgets('shows the empty state copy', (tester) async {
    final fakes = Fakes()..listings.listings = []..listings.total = 0;
    await pumpApp(tester, fakes, '/?q=unicorn');
    expect(find.text('Nothing here yet. Be the first to sell something.'), findsOneWidget);
  });

  testWidgets('works at phone width with bottom navigation', (tester) async {
    final fakes = Fakes();
    await pumpApp(tester, fakes, '/', size: const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
