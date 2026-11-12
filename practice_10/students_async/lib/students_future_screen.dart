import 'package:flutter/material.dart';

import 'api/fake_api.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/loading_view.dart';
import 'widgets/student_list.dart';

class StudentsFutureScreen extends StatefulWidget {
  const StudentsFutureScreen({super.key, required this.api});
  final FakeApi api;
  @override
  State<StudentsFutureScreen> createState() => _StudentsFutureScreenState();
}

class _StudentsFutureScreenState extends State<StudentsFutureScreen> {
  late final FakeApi _api;
  // Not final: only an explicit retry/reload replaces this Future.
  late Future<List<Student>> _future;
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _future = _api.fetchStudents();
  }

  void _retry() {
    final next = _api.fetchStudents();
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Student>>(
    future: _future,
    builder: (context, snapshot) {
      final done = snapshot.connectionState == ConnectionState.done;
      final Widget body;
      if (snapshot.hasError) {
        body = ErrorView(onRetry: _retry);
      } else if (!done) {
        body = const LoadingView();
      } else {
        final list = snapshot.data ?? const [];
        body = list.isEmpty
            ? const EmptyView()
            : StudentList(list, compact: _compact);
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('FutureBuilder'),
          actions: [
            Tooltip(
              message: 'Compact rows',
              child: Switch(
                value: _compact,
                onChanged: (v) => setState(() => _compact = v),
              ),
            ),
            IconButton(
              tooltip: 'Reload',
              onPressed: done ? _retry : null,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: body,
      );
    },
  );
}
