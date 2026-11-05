import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _expanded = true;

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('Remove all books from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    context.read<Cart>().clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cart'),
      actions: [
        IconButton(
          tooltip: 'Clear cart',
          icon: const Icon(Icons.delete_outline),
          onPressed: _confirmClear,
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Consumer<Cart>(
              builder: (context, cart, _) {
                final items = cart.items;
                if (items.isEmpty) {
                  return const Center(child: Text('Your cart is empty'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = items[i];
                    return ListTile(
                      title: Text(b.title),
                      subtitle: Text('${b.price} ₸  ×${cart.qtyOf(b)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Increase quantity',
                            onPressed: () => cart.increment(b),
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            tooltip: 'Remove book',
                            onPressed: () => cart.remove(b),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Consumer<Cart>(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined),
                SizedBox(width: 8),
                Text('Total'),
              ],
            ),
            builder: (context, cart, child) => ListTile(
              title: child!,
              subtitle: _expanded ? Text('${cart.total} ₸') : null,
              trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          ),
        ],
      ),
    ),
  );
}
