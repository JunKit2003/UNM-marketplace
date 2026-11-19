import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unm_marketplace/core/format.dart';
import 'package:unm_marketplace/widgets/price_text.dart';

void main() {
  test('formatPrice follows the RM rules', () {
    expect(formatPrice(1234), 'RM 1,234');
    expect(formatPrice(12.5), 'RM 12.50');
    expect(formatPrice(0), 'RM 0');
    expect(formatPrice(1000000), 'RM 1,000,000');
  });

  test('timeAgo is short and friendly', () {
    final now = DateTime.utc(2026, 11, 20, 12);
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
    expect(timeAgo(now.subtract(const Duration(hours: 2)), now: now), '2h ago');
    expect(timeAgo(now.subtract(const Duration(days: 3)), now: now), '3d ago');
    expect(timeAgo(DateTime.utc(2026, 9, 1), now: now), '1 Sep');
  });

  testWidgets('PriceText renders the formatted price', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PriceText(1234)));
    expect(find.text('RM 1,234'), findsOneWidget);
  });
}
