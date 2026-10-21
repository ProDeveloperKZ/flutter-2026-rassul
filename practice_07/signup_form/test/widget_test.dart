import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signup_form/main.dart';
import 'package:signup_form/summary_card.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Agreement gates submission and validators show together', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tapVisible(tester, find.byType(CheckboxListTile));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign up'));
    for (final error in [
      'Name must contain at least 2 characters',
      'Enter a valid email address',
      'Password must contain at least 8 characters',
      'Passwords do not match',
      'Choose a group',
      'Choose your date of birth',
    ]) {
      expect(find.text(error), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Valid account, date cancellation and complete reset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rassul');
    await tester.enterText(fields.at(1), 'rassul@kbtu.kz');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'wrong');
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsOneWidget);
    await tester.enterText(fields.at(3), 'password123');
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match'), findsNothing);
    await tapVisible(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text('IT-2301').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, fields.at(4));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('01.01.2005'), findsOneWidget);
    await tapVisible(tester, fields.at(4));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('01.01.2005'), findsOneWidget);
    await tapVisible(tester, find.byType(CheckboxListTile));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign up'));
    expect(find.byType(SummaryCard), findsOneWidget);
    expect(find.text('rassul@kbtu.kz'), findsOneWidget);
    await tapVisible(tester, find.text('Start over'));
    expect(find.byType(SummaryCard), findsNothing);
    expect(find.text('Rassul'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Summary uses its own width for the tablet grid', (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const summary = SummaryCard(
      name: 'Rassul',
      email: 'rassul@kbtu.kz',
      group: 'IT-2301',
      birthDate: '01.01.2005',
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: summary)));
    expect(find.byType(GridView), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(width: 400, child: summary)),
      ),
    );
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
