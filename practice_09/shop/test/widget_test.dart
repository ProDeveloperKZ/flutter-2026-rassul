import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop/main.dart';

void main() {
  testWidgets('Both routes share the lifted cart', (tester) async {
    await tester.pumpWidget(const Shell());
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Add').first);
      await tester.pumpAndSettle();
    }
    expect(find.text('Added'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Total: 7300 ₸'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
