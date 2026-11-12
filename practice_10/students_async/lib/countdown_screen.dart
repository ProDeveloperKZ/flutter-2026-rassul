import 'dart:async';

import 'package:flutter/material.dart';

import 'api/countdown.dart';

enum CountdownMode { builder, subscription }

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});
  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  CountdownMode _mode = CountdownMode.builder;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Countdown')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SegmentedButton<CountdownMode>(
            segments: const [
              ButtonSegment(
                value: CountdownMode.builder,
                label: Text('A · Builder'),
              ),
              ButtonSegment(
                value: CountdownMode.subscription,
                label: Text('B · Listen'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (v) => setState(() => _mode = v.single),
          ),
          const SizedBox(height: 16),
          const Text(
            'Each version starts at 10. Leaving stops its stream.',
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: _mode == CountdownMode.builder
                ? const _BuilderCountdown()
                : const _ListenCountdown(),
          ),
        ],
      ),
    ),
  );
}

class _BuilderCountdown extends StatefulWidget {
  const _BuilderCountdown();
  @override
  State<_BuilderCountdown> createState() => _BuilderCountdownState();
}

class _BuilderCountdownState extends State<_BuilderCountdown> {
  late final Stream<int> _stream = countdown(10);
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: _stream,
    builder: (context, snapshot) => _Counter(snapshot.data ?? 10),
  );
}

class _ListenCountdown extends StatefulWidget {
  const _ListenCountdown();
  @override
  State<_ListenCountdown> createState() => _ListenCountdownState();
}

class _ListenCountdownState extends State<_ListenCountdown> {
  int _left = 10;
  late final StreamSubscription<int> _sub;
  @override
  void initState() {
    super.initState();
    _sub = countdown(10).listen((i) => setState(() => _left = i));
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Counter(_left);
}

class _Counter extends StatelessWidget {
  const _Counter(this.left);
  final int left;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$left', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(left == 0 ? 'Finished' : 'seconds'),
      ],
    ),
  );
}
