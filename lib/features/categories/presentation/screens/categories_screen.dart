import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';

/// The Categories tab: every category, with how many products it has.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView(
        children: [
          for (final category in mockCategories)
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(capitalize(category)),
              subtitle: Text(_productCountLabel(category)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/categories/$category'),
            ),
        ],
      ),
    );
  }

  /// '1 product' or 'N products'.
  String _productCountLabel(String category) {
    final count = findMockProductsByCategory(category).length;
    return count == 1 ? '1 product' : '$count products';
  }
}
