import 'package:flutter/material.dart';

/// The Cart tab. A placeholder until the cart is built in Phase 6.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: const Center(child: Text('Your cart is empty.')),
    );
  }
}
