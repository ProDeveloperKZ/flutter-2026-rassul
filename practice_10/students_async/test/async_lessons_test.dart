import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:students_async/api/fake_api.dart';
import 'package:students_async/api/countdown.dart';

class _Probe extends StatefulWidget {
  const _Probe({super.key});
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  void lateUpdate() => setState(() {});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('Event order: synchronous work and first frame precede timers', (
    t,
  ) async {
    final events = <String>[];
    final api = FakeApi();
    events.add('A');
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () => events.add('B')),
    );
    events.add('C');
    unawaited(
      api.fetchStudents().then((list) => events.add('${list.length} students')),
    );
    await t.pumpWidget(const SizedBox());
    events.add('first frame');
    expect(events, ['A', 'C', 'first frame']);
    await t.pump(const Duration(seconds: 2));
    expect(events, ['A', 'C', 'first frame', 'B', '6 students']);
    debugPrint('Observed order: ${events.join(', ')}');
  });

  testWidgets('Unsafe late callback reports the actual disposed State error', (
    t,
  ) async {
    final key = GlobalKey<_ProbeState>();
    await t.pumpWidget(_Probe(key: key));
    final oldState = key.currentState!;
    await t.pumpWidget(const SizedBox());
    try {
      oldState.lateUpdate();
      fail('Expected a disposed-state error');
    } on FlutterError catch (e) {
      expect(e.toString(), contains('setState() called after dispose()'));
      debugPrint('Observed lifecycle error: ${e.toString().split('\n').first}');
    }
  });

  testWidgets(
    'Not cancelling keeps events arriving after a screen would leave',
    (t) async {
      final received = <int>[];
      final sub = countdown(10).listen(received.add);
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(received.last, 7);
      final afterLeaving = received.length;
      // Simulate leaving without cancelling; do not leave a real broken widget running.
      for (var i = 0; i < 7; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(received.skip(afterLeaving).toList(), [6, 5, 4, 3, 2, 1, 0]);
      unawaited(sub.cancel());
      await t.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('Unawaited save failure reaches its zone instead of its caller', (
    t,
  ) async {
    final errors = <Object>[];
    final api = FakeApi();
    final first = api.save(6);
    await t.pump(const Duration(seconds: 1));
    await first;
    runZonedGuarded(
      () {
        // Deliberately wrong for the exercise; the enclosing zone contains the failure.
        unawaited(api.save(6));
      },
      (error, stack) {
        errors.add(error);
      },
    );
    await t.pump(const Duration(seconds: 1));
    expect(errors.single, isA<StateError>());
    expect(errors.single.toString(), 'Bad state: server rejected 6');
    debugPrint('Observed unhandled-zone error: ${errors.single}');
  });
}
