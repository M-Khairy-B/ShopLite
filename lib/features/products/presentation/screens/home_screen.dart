import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';

/// The first screen of the app: category filters above a product grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The selected category, or `null` when "All" is selected.
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    // A local copy, so Dart can tell it is non-null after the check below.
    final selectedCategory = _selectedCategory;
    final products = selectedCategory == null
        ? mockProducts
        : findMockProductsByCategory(selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              semanticLabel: 'ShopLite logo',
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('ShopLite'),
          ],
        ),
      ),
      body: Column(
        // Full width for every child, so the chip row starts at the left
        // edge even when the chips don't fill the screen.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryChips(
            categories: mockCategories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          Expanded(
            child: ProductGrid(
              products: products,
              onProductTap: (product) => context.push('/product/${product.id}'),
            ),
          ),
        ],
      ),
    );
  }
}
