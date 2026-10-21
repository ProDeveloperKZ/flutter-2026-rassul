import 'package:flutter/material.dart';

import 'add_book_screen.dart';
import 'detail_screen.dart';
import 'models/book.dart';
import 'widgets/book_tile.dart';

enum Filter { all, unread, read }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<Book> _books = [...seed];
  Filter _filter = Filter.all;

  List<Book> get _visible => switch (_filter) {
    Filter.all => _books,
    Filter.unread => unread(_books),
    Filter.read => _books.where((book) => book.read).toList(),
  };

  Future<void> _openBook(Book book) async {
    final action = await Navigator.of(context).push<BookAction>(
      MaterialPageRoute(builder: (_) => DetailScreen(book: book)),
    );
    if (!mounted) return;
    switch (action) {
      case null:
        return;
      case BookAction.toggleRead:
        setState(() => book.read = !book.read);
      case BookAction.delete:
        setState(() => _books.remove(book));
    }
  }

  Future<void> _addBook() async {
    final book = await Navigator.of(context)
        .push<Book>(MaterialPageRoute(builder: (_) => const AddBookScreen()));
    if (!mounted) return;
    if (book == null) return;
    setState(() => _books.add(book));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Book added')));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final theme = Theme.of(context);
    Widget statistic(String label, int count) => Expanded(
      child: Column(
        children: [
          Text('$count', style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text('Reading list (${visible.length})')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    statistic('Books', _books.length),
                    statistic('Pages', totalPages(_books)),
                    statistic('Unread', unread(_books).length),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final filter in Filter.values)
                  ChoiceChip(
                    key: ValueKey('filter-${filter.name}'),
                    showCheckmark: false,
                    label: Text(switch (filter) {
                      Filter.all => 'All',
                      Filter.unread => 'Unread',
                      Filter.read => 'Read',
                    }),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No books in this filter',
                            style: theme.textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _filter = Filter.all),
                            child: const Text('Show all books'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final book = visible[index];
                        return BookTile(
                          book: book,
                          onToggle: () =>
                              setState(() => book.read = !book.read),
                          onTap: () => _openBook(book),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        tooltip: 'Add book',
        child: const Icon(Icons.add),
      ),
    );
  }
}
