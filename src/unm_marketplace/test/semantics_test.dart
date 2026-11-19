import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'harness.dart';

/// Screen readers must hear message text and descriptions, not just "text field, 08:00".
void main() {
  testWidgets('chat bubbles read as who said what', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, Fakes()..auth.user = fakeUser(), '/messages/5');
    expect(find.bySemanticsLabel(RegExp(r'^Priya Nair: Hi!')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('listing description is readable text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, Fakes(), '/listing/1');
    expect(find.bySemanticsLabel('Three colour temperatures.'), findsOneWidget);
    handle.dispose();
  });
}
