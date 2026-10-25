import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';

/// The Cart tab. Always empty until the cart is built in Phase 6.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: EmptyView(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        message: 'Products you add to your cart will appear here.',
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Start shopping'),
        ),
      ),
    );
  }
}
