import 'package:flutter/material.dart';

import 'main.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.items, required this.onRemove});
  final List<Book> items;
  final void Function(Book) onRemove;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cart')),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final b in items)
                ListTile(
                  title: Text(b.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemove(b),
                  ),
                ),
            ],
          ),
        ),
        Text('Total: ${items.fold<int>(0, (sum, b) => sum + b.price)} ₸'),
      ],
    ),
  );
}
