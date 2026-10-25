import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/app_shell.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/categories_screen.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/category_products_screen.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/profile/presentation/screens/profile_screen.dart';

/// Creates the app's router: the map from URL-style paths to screens.
///
/// Create it once for the app's lifetime (see `ShopLiteApp`), never inside a
/// `build` method. Screens that load products get [productsRepository];
/// [initialLocation] lets tests start on any page.
GoRouter createAppRouter({
  required ProductsRepository productsRepository,
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // The bottom-navigation shell. Each branch is one tab with its own
      // navigator, so every tab keeps its own stack and scroll position.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    HomeScreen(repository: productsRepository),
                // Nested under '/', so opening '/product/78' directly
                // still puts the home screen underneath it.
                routes: [_productDetailsRoute(productsRepository)],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
                routes: [
                  GoRoute(
                    path: ':category',
                    builder: (context, state) => CategoryProductsScreen(
                      category: state.pathParameters['category']!,
                    ),
                    // '/categories/laptops/product/78' keeps the product
                    // inside the Categories tab.
                    routes: [_productDetailsRoute(productsRepository)],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _PageNotFoundScreen(),
  );
}

/// The `product/:id` route. Used in more than one tab, so that a product
/// opens inside whichever tab you are in.
GoRoute _productDetailsRoute(ProductsRepository productsRepository) {
  return GoRoute(
    path: 'product/:id',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id']!);
      if (id == null) {
        return const _PageNotFoundScreen();
      }
      return ProductDetailsScreen(
        productId: id,
        repository: productsRepository,
      );
    },
  );
}

/// Shown for any path the router doesn't know, such as '/nope'.
class _PageNotFoundScreen extends StatelessWidget {
  const _PageNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message: "This page doesn't exist.",
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to home'),
        ),
      ),
    );
  }
}
