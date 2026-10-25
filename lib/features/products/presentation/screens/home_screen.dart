import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/product_catalog.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/sort_options_sheet.dart';

/// The first screen of the app: category filters above a product grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final ProductsRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// How many products to load. Only the first page for now: Phase 5 loads
  /// more while the user scrolls.
  static const _pageSize = 30;

  /// The request for the first page of the catalog. Started once in
  /// [initState], not in build(), so rebuilding the screen doesn't send the
  /// request again.
  late Future<ProductsPage> _page;

  /// The selected category, or `null` when "All" is selected.
  String? _selectedCategory;

  /// The order the grid is shown in.
  ProductSort _sort = ProductSort.featured;

  @override
  void initState() {
    super.initState();
    _page = _loadFirstPage();
  }

  Future<ProductsPage> _loadFirstPage() {
    return widget.repository.getProducts(skip: 0, limit: _pageSize);
  }

  void _retry() {
    setState(() {
      _page = _loadFirstPage();
    });
  }

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
      body: FutureBuilder<ProductsPage>(
        future: _page,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }

          final error = snapshot.error;
          if (error != null) {
            return ErrorView(
              // The repository promises AppExceptions only; anything else is
              // a bug, but the user still gets a way to retry.
              error: error is AppException ? error : const UnknownException(),
              onRetry: _retry,
            );
          }

          return _buildCatalog(snapshot.requireData.products);
        },
      ),
    );
  }

  /// The chips and the grid for the [loaded] products, filtered by the
  /// selected category and ordered by the selected sort.
  Widget _buildCatalog(List<Product> loaded) {
    // A local copy, so Dart can tell it is non-null after the check below.
    final selectedCategory = _selectedCategory;
    final filtered = selectedCategory == null
        ? loaded
        : productsInCategory(loaded, selectedCategory);
    final products = sortProducts(filtered, _sort);

    return Column(
      // Full width for every child, so the chip row starts at the left
      // edge even when the chips don't fill the screen.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryChips(
          categories: categoriesOf(loaded),
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
    );
  }
}
