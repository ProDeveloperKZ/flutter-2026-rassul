import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop/main.dart';
import 'package:shop/models/cart.dart';

void main() {
  test('Cart owns mutations and counts titles separately from copies', () {
    final c = Cart();
    var changes = 0;
    c.addListener(() => changes++);
    expect(c.add(books[0]), true);
    expect(c.add(books[1]), true);
    expect(c.add(books[0]), false);
    expect(changes, 2);
    expect(() => c.items.add(books[0]), throwsUnsupportedError);
    c.remove(books[0]);
    expect(c.count, 1);
    expect(c.total, 3100);
    c.increment(books[1]);
    expect(c.count, 1);
    expect(c.total, 6200);
    c.clear();
    expect(c.total, 0);
    expect(changes, 5);
    c.dispose();
  });
  testWidgets('Quantity changes, routes, and clear confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => Cart(), child: const Shell()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cart'));
    await tester.pumpAndSettle();
    debugPrint('BEGIN three increments');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Increase quantity').first);
      await tester.pumpAndSettle();
    }
    debugPrint('END three increments');
    expect(find.text('19900 ₸'), findsOneWidget);
    debugPrint('BEGIN remove');
    await tester.tap(find.byTooltip('Remove book').first);
    await tester.pumpAndSettle();
    debugPrint('END remove');
    await tester.tap(find.byTooltip('Clear cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(books[1].title), findsOneWidget);
    await tester.tap(find.byTooltip('Clear cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
  });
}
