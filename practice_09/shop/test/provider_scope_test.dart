import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shop/models/cart.dart';

void main() {
  testWidgets('watch in a tap fails; read in build silently misses changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => Cart(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text('Count: ${context.read<Cart>().count}'),
                    TextButton(
                      onPressed: () => context.watch<Cart>().add(books.first),
                      child: const Text('Watch'),
                    ),
                    TextButton(
                      onPressed: () => context.read<Cart>().add(books.first),
                      child: const Text('Read'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Watch'));
    expect(
      tester.takeException().toString(),
      contains('Tried to listen to a value exposed with provider'),
    );
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    expect(find.text('Count: 0'), findsOneWidget);
    expect(tester.element(find.text('Read')).read<Cart>().count, 1);
  });
}
