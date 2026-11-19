import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:unm_marketplace/router.dart';

import 'fakes.dart';

void main() {
  testWidgets('signed-out visitors are sent to login with a return path', (tester) async {
    final fakes = Fakes();
    final container = ProviderContainer(overrides: fakes.overrides());
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    router.go('/saved');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/login?from=%2Fsaved');
  });

  testWidgets('signed-in users reach protected pages', (tester) async {
    final fakes = Fakes()..auth.user = fakeUser();
    final container = ProviderContainer(overrides: fakes.overrides());
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    router.go('/saved');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/saved');
    expect(GoRouter.of(tester.element(find.byType(Scaffold).first)), isNotNull);
  });
}
