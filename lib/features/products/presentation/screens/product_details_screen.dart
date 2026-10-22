import 'package:flutter/material.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';

/// Shows everything we know about one product.
///
/// Opened from the home screen when a product card is tapped.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProductImage(url: product.thumbnailUrl, fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  formatPrice(product.priceCents),
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(product.description, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
