import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';

/// Creates the app's router: the map from URL-style paths to screens.
///
/// Create it once for the app's lifetime (see `ShopLiteApp`), never inside a
/// `build` method. [initialLocation] lets tests start on any page.
GoRouter createAppRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Nested under '/', so opening '/product/78' directly still puts
          // the home screen underneath it to go back to.
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
