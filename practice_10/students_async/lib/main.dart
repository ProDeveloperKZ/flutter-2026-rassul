import 'dart:async';

import 'package:flutter/material.dart';

import 'api/fake_api.dart';
import 'students_screen.dart';
import 'students_future_screen.dart';
import 'countdown_screen.dart';

void main() => runApp(const StudentsApp());

class StudentsApp extends StatelessWidget {
  const StudentsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Students Async',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Keep call counters when a successful save pops the route.
  final _api = FakeApi();
  final _emptyApi = FakeApi(empty: true);
  bool _empty = false;
  void _open(Widget screen) => unawaited(
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('The data arrives later')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Students Async',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'A two-second fake API. Every third load fails; every second save is rejected.',
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Empty response'),
          subtitle: const Text('Use a server with no students'),
          value: _empty,
          onChanged: (v) => setState(() => _empty = v),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () =>
              _open(StudentsScreen(api: _empty ? _emptyApi : _api)),
          icon: const Icon(Icons.touch_app_outlined),
          label: const Text('By hand'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              _open(StudentsFutureScreen(api: _empty ? _emptyApi : _api)),
          icon: const Icon(Icons.hourglass_bottom),
          label: const Text('FutureBuilder'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _open(const CountdownScreen()),
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Countdown'),
        ),
      ],
    ),
  );
}
