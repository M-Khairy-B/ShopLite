import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';

/// Shows the products of one category. Opened at `/categories/:category`.
class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    // Temporary: read from the mock list. In Phase 5 this becomes an API call.
    final products = findMockProductsByCategory(category);

    return Scaffold(
      appBar: AppBar(title: Text(capitalize(category))),
      body: products.isEmpty
          ? EmptyView(
              icon: Icons.category_outlined,
              title: 'No products here',
              message: 'There are no products in this category yet.',
              action: FilledButton(
                onPressed: () => context.go('/categories'),
                child: const Text('See all categories'),
              ),
            )
          : ProductGrid(
              products: products,
              // Stay inside the Categories tab: this product page is nested
              // under the category, not under Home.
              onProductTap: (product) =>
                  context.push('/categories/$category/product/${product.id}'),
            ),
    );
  }
}
