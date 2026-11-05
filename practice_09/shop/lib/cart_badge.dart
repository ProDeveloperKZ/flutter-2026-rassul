import 'package:flutter/material.dart';

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.count, required this.total});
  final int count, total;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('$total ₸'),
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
