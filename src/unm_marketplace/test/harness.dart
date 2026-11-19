import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:unm_marketplace/router.dart';
import 'package:unm_marketplace/theme/app_theme.dart';

import 'fakes.dart';

class Harness {
  Harness(this.container, this.router);
  final ProviderContainer container;
  final GoRouter router;
  String get location => router.routerDelegate.currentConfiguration.uri.toString();
}

/// Pump the real app (router, theme, shell) with faked repositories at [location].
Future<Harness> pumpApp(WidgetTester tester, Fakes fakes, String location, {Size size = const Size(1280, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: fakes.overrides(), retry: (_, _) => null);
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(theme: buildTheme(Brightness.dark), routerConfig: router),
  ));
  await tester.pump();
  router.go(location);
  await settle(tester);
  return Harness(container, router);
}

/// Like pumpAndSettle, but tolerates never-ending animations (gradient mesh, shimmer).
Future<void> settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
