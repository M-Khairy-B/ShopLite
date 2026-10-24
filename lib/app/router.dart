import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/app_shell.dart';
import 'package:e_commerce_learn/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/categories_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/profile/presentation/screens/profile_screen.dart';

/// Creates the app's router: the map from URL-style paths to screens.
///
/// Create it once for the app's lifetime (see `ShopLiteApp`), never inside a
/// `build` method. [initialLocation] lets tests start on any page.
GoRouter createAppRouter({String initialLocation = '/'}) {
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
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // Nested under '/', so opening '/product/78' directly
                  // still puts the home screen underneath it.
                  GoRoute(
                    path: 'product/:id',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id']!);
                      if (id == null) {
                        return const _PageNotFoundScreen();
                      }
                      return ProductDetailsScreen(productId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
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

/// Shown for any path the router doesn't know, such as '/nope'.
class _PageNotFoundScreen extends StatelessWidget {
  const _PageNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text("This page doesn't exist.")),
    );
  }
}
