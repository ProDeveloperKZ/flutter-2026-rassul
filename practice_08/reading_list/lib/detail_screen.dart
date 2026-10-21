import 'package:flutter/material.dart';

import 'models/book.dart';

enum BookAction { toggleRead, delete }

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.book});
  final Book book;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Delete '${book.title}'?"),
        content: const Text('This removes the book from your reading list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed == true) Navigator.of(context).pop(BookAction.delete);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Book details')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Author'),
                  subtitle: Text(book.author),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: const Text('Pages'),
                  subtitle: Text('${book.pages}'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Year'),
                  subtitle: Text(
                    book.year == null ? 'Year unknown' : '${book.year}',
                  ),
                ),
                ListTile(
                  leading: Icon(
                    book.read
                        ? Icons.check_circle_outline
                        : Icons.circle_outlined,
                  ),
                  title: const Text('Status'),
                  subtitle: Text(book.read ? 'Read' : 'Unread'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(BookAction.toggleRead),
            icon: Icon(book.read ? Icons.undo : Icons.check),
            label: Text(book.read ? 'Mark as unread' : 'Mark as read'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    ),
  );
}
