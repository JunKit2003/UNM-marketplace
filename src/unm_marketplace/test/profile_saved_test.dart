import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('guests see no change-password option', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser(isGuest: true);
    await pumpApp(tester, fakes, '/me');
    expect(find.text('Guest 4821'), findsWidgets);
    expect(find.text('Change password'), findsNothing);
    expect(find.text("Guest accounts can't set a password."), findsOneWidget);
  });

  testWidgets('members can change password and see their listings', (
    tester,
  ) async {
    final fakes = Fakes()..auth.user = fakeUser();
    await pumpApp(tester, fakes, '/me');
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('LED desk lamp'), findsWidgets);
  });

  testWidgets('logging out returns to browse', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser();
    final h = await pumpApp(tester, fakes, '/me');
    await tester.ensureVisible(find.text('Log out'));
    await tester.tap(find.text('Log out'));
    await settle(tester);
    expect(fakes.auth.user, isNull);
    expect(h.location, '/');
  });

  testWidgets('saved page shows the empty copy', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser();
    await pumpApp(tester, fakes, '/saved');
    expect(
      find.text('No saved listings yet. Tap the heart on anything you like.'),
      findsOneWidget,
    );
  });
}
