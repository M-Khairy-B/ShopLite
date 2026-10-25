import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

class ShopLiteApp extends StatefulWidget {
  const ShopLiteApp({super.key, required this.productsRepository});

  /// Where products come from: the real API (see main.dart), or a fake in
  /// tests.
  final ProductsRepository productsRepository;

  @override
  State<ShopLiteApp> createState() => _ShopLiteAppState();
}

class _ShopLiteAppState extends State<ShopLiteApp> {
  // Created once, when the app starts. Creating it in build() would throw
  // away the navigation history on every rebuild. It's set in initState
  // because it needs `widget`, which field initializers can't use.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(productsRepository: widget.productsRepository);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ShopLite',
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      // Follow the phone's light/dark setting.
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
