import 'package:flutter/material.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

class ShopLiteApp extends StatelessWidget {
  const ShopLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopLite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('ShopLite')),
        // TEMPORARY (Phase 1, Task 2): previews one ProductCard.
        // Replaced by HomeScreen in Task 3.
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Welcome to ShopLite'),
              const SizedBox(height: 16),
              SizedBox(
                width: 180,
                height: 280,
                child: ProductCard(product: mockProducts.first),
              ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
