import 'package:flutter/material.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

/// The first screen of the app: category filters above a two-column
/// product grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Every category in the catalog, in the order it first appears.
  final List<String> _categories = mockProducts
      .map((product) => product.category)
      .toSet()
      .toList();

  /// The selected category, or `null` when "All" is selected.
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final products = _selectedCategory == null
        ? mockProducts
        : mockProducts
              .where((product) => product.category == _selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('ShopLite')),
      body: Column(
        children: [
          CategoryChips(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
