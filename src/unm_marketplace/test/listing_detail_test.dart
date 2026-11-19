import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/models.dart';

import 'fakes.dart';
import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('shows the listing details', (tester) async {
    final fakes = Fakes();
    await pumpApp(tester, fakes, '/listing/1');
    expect(find.text('LED desk lamp'), findsWidgets);
    expect(find.text('RM 45'), findsWidgets);
    expect(find.text('Like new'), findsWidgets);
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Message seller'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('owners see Edit, Mark as sold and Delete instead of Message', (tester) async {
    final fakes = Fakes()
      ..auth.user = fakeUser()
      ..listings.listings = [Listing.fromJson(listingJson(isOwner: true))];
    await pumpApp(tester, fakes, '/listing/1');
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Mark as sold'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Message seller'), findsNothing);
  });

  testWidgets('visitors pressing Message seller go to login and back to the chat', (tester) async {
    final fakes = Fakes();
    final h = await pumpApp(tester, fakes, '/listing/1');
    await tester.tap(find.text('Message seller'));
    await settle(tester);
    expect(h.location, '/login?from=%2Flisting%2F1%3Fchat%3D1');
  });

  testWidgets('signed-in buyers pressing Message seller open the conversation', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser();
    final h = await pumpApp(tester, fakes, '/listing/1');
    await tester.tap(find.text('Message seller'));
    await settle(tester);
    expect(h.location, '/messages/5');
  });

  testWidgets('saving toggles the heart and calls the API', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser();
    await pumpApp(tester, fakes, '/listing/1');
    await tester.tap(find.byTooltip('Save').first);
    await settle(tester);
    expect(fakes.listings.saves, [1]);
    expect(find.byTooltip('Remove from saved'), findsWidgets);
  });

  testWidgets('sold listings show a badge and no Message button', (tester) async {
    final fakes = Fakes()..listings.listings = [Listing.fromJson(listingJson(status: 'sold'))];
    await pumpApp(tester, fakes, '/listing/1');
    expect(find.text('Sold'), findsWidgets);
    expect(find.text('Message seller'), findsNothing);
  });

  testWidgets('unknown listing shows the removed copy', (tester) async {
    final fakes = Fakes();
    await pumpApp(tester, fakes, '/listing/999');
    expect(find.text("This listing doesn't exist or was removed."), findsOneWidget);
  });
}
