import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_list/main.dart';
import 'package:reading_list/models/book.dart';

void main() {
  test('Book parsing, nullable year and collection helpers', () {
    final books = seed;
    expect(totalPages(books), 1220);
    expect(unread(books).length, 4);
    expect(
      Book.fromMap({'title': 'X', 'author': 'Y', 'pages': 10}).toString(),
      'X — Y, 10 pp.',
    );
    expect(
      Book.fromMap({'title': 'X', 'author': 'Y', 'pages': 10}).read,
      isFalse,
    );
    expect(
      books[1].toString(),
      'Null Safety for Humans — B. Seitkali, 196 pp. (2022)',
    );
    expect(authors([books[0], books[1], books[0]]), [
      'A. Nurmagambetova',
      'B. Seitkali',
    ]);
    books[1].read = true;
    expect(unread(seed).length, 4);
  });

  testWidgets('Unread filter reacts to toggles, details return an action', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.widgetWithText(ChoiceChip, 'Unread'));
    await tester.pumpAndSettle();
    expect(find.text('Reading list (4)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(find.text('Reading list (3)'), findsOneWidget);
    await tester.tap(find.text('Constraints Go Down, Sizes Go Up'));
    await tester.pumpAndSettle();
    expect(find.text('Year unknown'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Book details'), findsOneWidget);
    await tester.tap(find.text('Mark as read'));
    await tester.pumpAndSettle();
    expect(find.text('Reading list (2)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty form has three errors and unknown year can be saved', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Title must contain at least 2 characters'),
      findsOneWidget,
    );
    expect(find.text('Enter an author'), findsOneWidget);
    expect(find.text('A whole number above 0'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'New book');
    await tester.enterText(fields.at(1), 'New author');
    await tester.enterText(fields.at(2), 'abc');
    await tester.pumpAndSettle();
    expect(find.text('A whole number above 0'), findsOneWidget);
    await tester.enterText(fields.at(2), '100');
    await tester.enterText(fields.at(3), '1449');
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a year from 1450 to ${DateTime.now().year}'),
      findsOneWidget,
    );
    await tester.enterText(fields.at(3), '');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Reading list (6)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('New book'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('New book'));
    await tester.pumpAndSettle();
    expect(find.text('Year unknown'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Reading list (5)'), findsOneWidget);
    expect(find.text('New book'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Long titles fit narrow portrait and landscape layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(320, 720), const Size(720, 320)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(seed.last.title),
        160,
        scrollable: find.byType(Scrollable),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
