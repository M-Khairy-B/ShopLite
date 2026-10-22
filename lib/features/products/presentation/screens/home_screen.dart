import 'dart:math';

import 'package:flutter/material.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

/// The grid gets one column for every this many dp of width...
const int _widthPerColumn = 200;

/// ...but never fewer than this many columns.
const int _minColumns = 2;

/// The first screen of the app: category filters above a product grid
/// whose number of columns follows the available width.
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
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              semanticLabel: 'ShopLite logo',
            ),
            const SizedBox(width: 12),
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
            categories: _categories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // One column per 200 dp of width, but never fewer than 2.
                // The minimum also keeps the grid valid when Android lays
                // out the very first frame with a width of 0.
                final columns = max(
                  _minColumns,
                  constraints.maxWidth ~/ _widthPerColumn,
                );

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
