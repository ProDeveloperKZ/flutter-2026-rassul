import 'package:flutter/material.dart';

import 'models/book.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});
  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _pages = TextEditingController();
  final _year = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_title, _author, _pages, _year]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        Book(
          title: _title.text.trim(),
          author: _author.text.trim(),
          pages: int.parse(_pages.text.trim()),
          year: int.tryParse(_year.text.trim()),
        ),
      );
    }
  }

  void _dismissKeyboard(PointerDownEvent event) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add book')),
    body: Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onTapOutside: _dismissKeyboard,
              validator: (v) => (v ?? '').trim().length < 2
                  ? 'Title must contain at least 2 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('author'),
              controller: _author,
              decoration: const InputDecoration(labelText: 'Author'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onTapOutside: _dismissKeyboard,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter an author' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('pages'),
              controller: _pages,
              decoration: const InputDecoration(labelText: 'Pages'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onTapOutside: _dismissKeyboard,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'A whole number above 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('year'),
              controller: _year,
              decoration: const InputDecoration(
                labelText: 'Year (optional)',
                helperText: 'Leave empty if unknown',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              onTapOutside: _dismissKeyboard,
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return null;
                final year = int.tryParse(text);
                if (year == null || year < 1450 || year > DateTime.now().year) {
                  return 'Enter a year from 1450 to ${DateTime.now().year}';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    ),
  );
}
