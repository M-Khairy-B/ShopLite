import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/app/app_preferences.dart';
import 'package:e_commerce_learn/core/config/env.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';
import 'package:e_commerce_learn/features/cart/data/cart_local_store.dart';
import 'package:e_commerce_learn/features/products/data/dummy_json_products_repository.dart';
import 'package:e_commerce_learn/features/wishlist/data/wishlist_local_store.dart';

Future<void> main() async {
  // Device storage talks to Android through a plugin, and plugins need
  // Flutter's engine to be running first. runApp would start it, but we
  // read the storage before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // The composition root: the one place that decides which real
  // implementations the app runs with. Tests build ShopLiteApp with fakes.
  final apiClient = ApiClient(baseUrl: Env.apiBaseUrl);
  final productsRepository = DummyJsonProductsRepository(apiClient);

  // Read before the first frame (a few milliseconds), so the first screen
  // already shows the saved cart: no flash of an empty badge.
  final preferences = await openAppPreferences();

  runApp(
    ShopLiteApp(
      productsRepository: productsRepository,
      cartStore: CartLocalStore(preferences),
      wishlistStore: WishlistLocalStore(preferences),
    ),
  );
}
