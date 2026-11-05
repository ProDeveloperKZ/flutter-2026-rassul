import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_badge.dart';
import 'models/cart.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final matches = books
        .where(
          (b) => '${b.title} ${b.author}'.toLowerCase().contains(
            _query.trim().toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: const [CartBadge()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by title or author',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: matches.isEmpty
          ? const Center(child: Text('No books found'))
          : ListView.separated(
              itemCount: matches.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _BookRow(matches[i]),
            ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow(this.book);
  final Book book;
  @override
  Widget build(BuildContext context) {
    final added = context.select<Cart, bool>((c) => c.qtyOf(book) > 0);
    return ListTile(
      title: Text(book.title),
      subtitle: Text('${book.author}\n${book.price} ₸'),
      isThreeLine: true,
      trailing: added
          ? const Text('Added')
          : OutlinedButton(
              onPressed: () {
                final ok = context.read<Cart>().add(book);
                if (ok) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Added')));
                }
              },
              child: const Text('Add'),
            ),
    );
  }
}
