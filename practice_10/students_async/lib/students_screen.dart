import 'dart:async';

import 'package:flutter/material.dart';

import 'api/fake_api.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/loading_view.dart';
import 'widgets/student_list.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key, required this.api});
  final FakeApi api;
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student>? _students;
  Object? _error;
  late final FakeApi _api;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    // _load catches failures itself; initState cannot await.
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _students = null;
      _error = null;
    });
    try {
      final list = await _api.fetchStudents();
      if (!mounted) return;
      setState(() => _students = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _students;
    final loading = students == null && _error == null;
    final Widget body = switch ((students, _error)) {
      (_, final Object error) => ErrorView(
        onRetry: () => unawaited(_load()),
        key: ValueKey(error),
      ),
      (null, null) => const LoadingView(),
      (final List<Student> list, null) when list.isEmpty => const EmptyView(),
      (final List<Student> list, null) => StudentList(list),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('By hand'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: loading || _saving ? null : () => unawaited(_load()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: students == null || _saving
            ? null
            : () async {
                setState(() => _saving = true);
                try {
                  await _api.save(students.length);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } on StateError catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
        icon: _saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Saving…' : 'Save'),
      ),
    );
  }
}
