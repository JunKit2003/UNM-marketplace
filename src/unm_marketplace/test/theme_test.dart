import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/theme/app_theme.dart';

/// Every label must use a bundled font. A style without a family falls back to
/// Roboto from Google's CDN, which renders blank when that request fails.
void main() {
  for (final brightness in Brightness.values) {
    testWidgets('labels use bundled fonts ($brightness)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness),
          home: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: 0,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('RailA'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.add),
                      label: Text('RailB'),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Filled'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Outlined'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('TextBtn'),
                      ),
                      const Chip(label: Text('ChipLabel')),
                      FilterChip(
                        label: const Text('FilterLabel'),
                        onSelected: (_) {},
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('Seg')),
                        ],
                        selected: const {1},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'BarA'),
                NavigationDestination(icon: Icon(Icons.add), label: 'BarB'),
              ],
            ),
          ),
        ),
      );
      for (final label in [
        'RailA',
        'RailB',
        'Filled',
        'Outlined',
        'TextBtn',
        'ChipLabel',
        'FilterLabel',
        'Seg',
        'BarA',
        'BarB',
      ]) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label).first,
        );
        final family = paragraph.text.style?.fontFamily;
        expect(
          ['Inter', 'SpaceGrotesk'],
          contains(family),
          reason: '$label uses $family',
        );
      }
    });
  }
}
