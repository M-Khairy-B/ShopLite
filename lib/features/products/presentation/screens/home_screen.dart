import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/sort_options_sheet.dart';

/// The first screen of the app: category filters above a product grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The selected category, or `null` when "All" is selected.
  String? _selectedCategory;

  /// The order the grid is shown in.
  ProductSort _sort = ProductSort.featured;

  /// Shows the "Sort by" sheet, applies the choice, and offers an Undo.
  Future<void> _chooseSort() async {
    final previous = _sort;

    // The sheet is a route on top of this screen. `await` waits until it
    // closes; the result is the tapped option, or null if dismissed.
    final chosen = await showModalBottomSheet<ProductSort>(
      context: context,
      // Open on the app's top-level navigator, above the bottom navigation
      // bar, so the sheet covers the whole app instead of only this tab.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SortOptionsSheet(selected: _sort),
    );

    // Nothing to do if the sheet was dismissed or the same sort was picked.
    // `mounted` guards against this screen having been removed while the
    // sheet was open; `context` must not be used after that.
    if (chosen == null || chosen == previous || !mounted) {
      return;
    }

    setState(() {
      _sort = chosen;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Showing: ${sortLabel(chosen)}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (mounted) {
                setState(() {
                  _sort = previous;
                });
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // A local copy, so Dart can tell it is non-null after the check below.
    final selectedCategory = _selectedCategory;
    final filtered = selectedCategory == null
        ? mockProducts
        : findMockProductsByCategory(selectedCategory);
    final products = sortProducts(filtered, _sort);

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
        actions: [
          IconButton(
            tooltip: 'Sort products',
            icon: const Icon(Icons.sort),
            onPressed: _chooseSort,
          ),
        ],
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
