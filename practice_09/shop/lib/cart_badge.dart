import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/cart.dart';

class CartBadge extends StatelessWidget {
  const CartBadge({super.key});
  @override
  Widget build(BuildContext context) {
    debugPrint('badge build');
    final count = context.select<Cart, int>((c) => c.count);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BadgeTotal(),
        IconButton(
          tooltip: 'Cart',
          onPressed: () => Navigator.pushNamed(context, '/cart'),
          icon: Badge(
            label: Text('$count'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        ),
      ],
    );
  }
}

class _BadgeTotal extends StatelessWidget {
  const _BadgeTotal();
  @override
  Widget build(BuildContext context) {
    final total = context.select<Cart, int>((c) => c.total);
    return Text('$total ₸');
  }
}
