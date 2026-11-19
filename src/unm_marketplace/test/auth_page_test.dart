import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/api/api_error.dart';

import 'fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('logging in returns to where the visitor came from', (
    tester,
  ) async {
    final fakes = Fakes();
    final h = await pumpApp(tester, fakes, '/login?from=%2Fsaved');
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'amy1@nottingham.edu.my',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'correct-horse-1',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(fakes.auth.calls, ['login']);
    expect(h.location, '/saved');
  });

  testWidgets('wrong login shows the API message', (tester) async {
    final fakes = Fakes()
      ..auth.loginError = ApiError(
        status: 401,
        code: 'unauthenticated',
        message: 'Email or password is wrong.',
      );
    await pumpApp(tester, fakes, '/login');
    await tester.enterText(find.byKey(const Key('login-email')), 'a@b.c');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'nope-nope',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await settle(tester);
    expect(find.text('Email or password is wrong.'), findsOneWidget);
  });

  testWidgets('sign-up shows a taken email under the email field', (
    tester,
  ) async {
    const msg = 'That email is already registered.';
    final fakes = Fakes()
      ..auth.signupError = ApiError(
        status: 409,
        code: 'conflict',
        message: msg,
        fields: {'email': msg},
      );
    await pumpApp(tester, fakes, '/login');
    await tester.tap(find.text('Sign up'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('signup-firstName')), 'Amy');
    await tester.enterText(find.byKey(const Key('signup-username')), 'amy1');
    await tester.enterText(
      find.byKey(const Key('signup-email')),
      'amy1@nottingham.edu.my',
    );
    await tester.enterText(
      find.byKey(const Key('signup-password')),
      'correct-horse-1',
    );
    await tester.ensureVisible(find.byKey(const Key('signup-submit')));
    await tester.tap(find.byKey(const Key('signup-submit')));
    await settle(tester);
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('signup-email')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.decoration?.errorText, msg);
  });

  testWidgets('Try the demo logs in as a guest', (tester) async {
    final fakes = Fakes();
    final h = await pumpApp(tester, fakes, '/login?from=%2Fmessages');
    await tester.tap(find.text('Try the demo'));
    await settle(tester);
    expect(fakes.auth.calls, ['demo']);
    expect(h.location, '/messages');
  });
}
