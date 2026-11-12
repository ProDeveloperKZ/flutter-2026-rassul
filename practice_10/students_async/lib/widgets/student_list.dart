import 'package:flutter/material.dart';

import '../api/fake_api.dart';

class StudentList extends StatelessWidget {
  const StudentList(this.students, {super.key, this.compact = false});
  final List<Student> students;
  final bool compact;
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(bottom: 96),
    itemCount: students.length,
    itemBuilder: (_, i) {
      final student = students[i];
      return ListTile(
        dense: compact,
        leading: CircleAvatar(child: Text(student.name.substring(0, 1))),
        title: Text(student.name),
        subtitle: Text(student.group),
        trailing: Text('GPA ${student.gpa?.toStringAsFixed(1) ?? '—'}'),
      );
    },
  );
}
