import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/router.dart';

import 'fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('signed-out visitors are sent to login with a return path', (tester) async {
    final h = await pumpApp(tester, Fakes(), '/saved');
    expect(h.location, '/login?from=%2Fsaved');
  });

  testWidgets('signed-in users reach protected pages', (tester) async {
    final h = await pumpApp(tester, Fakes()..auth.user = fakeUser(), '/saved');
    expect(h.location, '/saved');
  });

  test('authRedirect only follows same-site return paths', () {
    expect(authRedirect(location: '/login?from=%2Fsell', signedIn: true, loading: false), '/sell');
    expect(authRedirect(location: '/login?from=https%3A%2F%2Fevil.example', signedIn: true, loading: false), '/');
    expect(authRedirect(location: '/login?from=%2F%2Fevil.example', signedIn: true, loading: false), '/');
    expect(authRedirect(location: '/listing/1/edit', signedIn: false, loading: false), '/login?from=%2Flisting%2F1%2Fedit');
    expect(authRedirect(location: '/saved', signedIn: false, loading: true), isNull);
  });
}
