import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:students_async/api/fake_api.dart';
import 'package:students_async/main.dart';
import 'package:students_async/students_screen.dart';
import 'package:students_async/students_future_screen.dart';
import 'package:students_async/countdown_screen.dart';

Future<void> finishLoad(WidgetTester t) async {
  await t.pump(const Duration(seconds: 2));
  await t.pumpAndSettle();
}

Widget routeTo(Widget child) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () =>
            Navigator.of(context)
                .push<void>(MaterialPageRoute(builder: (_) => child)),
        child: const Text('Open'),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'Manual screen has loading, data, error, retry and empty states',
    (t) async {
      final api = FakeApi();
      await t.pumpWidget(MaterialApp(home: StudentsScreen(api: api)));
      expect(find.text('Loading students…'), findsOneWidget);
      await finishLoad(t);
      expect(find.text('Aida Nurlanova'), findsOneWidget);
      expect(find.text('GPA —'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await t.tap(find.byTooltip('Reload'));
        await t.pump();
        await finishLoad(t);
      }
      expect(find.text('Could not load students'), findsOneWidget);
      await t.tap(find.text('Retry'));
      await t.pump();
      await finishLoad(t);
      expect(api.calls, 4);
      expect(find.text('Aida Nurlanova'), findsOneWidget);
      await t.pumpWidget(
        MaterialApp(
          home: StudentsScreen(
            key: const ValueKey('empty'),
            api: FakeApi(empty: true),
          ),
        ),
      );
      await finishLoad(t);
      expect(find.text('No students yet'), findsOneWidget);
    },
  );

  testWidgets('Future field survives ten compact switches', (t) async {
    final api = FakeApi();
    await t.pumpWidget(MaterialApp(home: StudentsFutureScreen(api: api)));
    await finishLoad(t);
    for (var i = 0; i < 10; i++) {
      await t.tap(find.byType(Switch));
      await t.pumpAndSettle();
      expect(find.text('Loading students…'), findsNothing);
    }
    expect(api.calls, 1);
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byTooltip('Reload'));
      await t.pump();
      await finishLoad(t);
    }
    expect(find.text('Could not load students'), findsOneWidget);
    await t.tap(find.text('Retry'));
    await t.pump();
    await finishLoad(t);
    expect(find.text('Aida Nurlanova'), findsOneWidget);
  });

  testWidgets('Save succeeds once, rejects second, and ignores double taps', (
    t,
  ) async {
    await t.pumpWidget(const StudentsApp());
    await t.tap(find.text('By hand'));
    await t.pump();
    await finishLoad(t);
    await t.tap(find.text('Save'));
    await t.pump();
    expect(
      t
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNull,
    );
    await t.tap(find.text('Saving…'));
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('Students Async'), findsOneWidget);
    await t.tap(find.text('By hand'));
    await t.pump();
    await finishLoad(t);
    await t.tap(find.text('Save'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('server rejected 6'), findsOneWidget);
    expect(find.text('Aida Nurlanova'), findsOneWidget);
    expect(
      t
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Back before load or save completes is safe', (t) async {
    await t.pumpWidget(routeTo(StudentsScreen(api: FakeApi())));
    await t.tap(find.text('Open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pageBack();
    await finishLoad(t);
    expect(t.takeException(), isNull);
    await t.tap(find.text('Open'));
    await t.pump();
    await finishLoad(t);
    await t.tap(find.text('Save'));
    await t.pump();
    await t.pageBack();
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('Both countdowns stop logging after leaving at seven', (t) async {
    final previous = debugPrint;
    final ticks = <String>[];
    debugPrint = (String? msg, {int? wrapWidth}) {
      if (msg != null && msg.startsWith('tick')) ticks.add(msg);
    };
    addTearDown(() => debugPrint = previous);
    for (final manual in [false, true]) {
      await t.pumpWidget(routeTo(const CountdownScreen()));
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      if (manual) {
        await t.tap(find.text('B · Listen'));
        await t.pump();
      }
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(seconds: 1));
        await t.pump();
      }
      expect(find.text('7'), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      final before = ticks.length;
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(ticks.length, before);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    }
    debugPrint = previous;
  });
}
