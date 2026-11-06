import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

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
    _router = createAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, so every screen (and every dialog or sheet) can find
    // the repository with `context.read<ProductsRepository>()`. `.value`
    // because main.dart created it: this provider shares it, but doesn't own
    // it.
    return RepositoryProvider<ProductsRepository>.value(
      value: widget.productsRepository,
      // The cart and the wishlist are app state: one of each, shared by
      // every screen, living as long as the app. So they're provided here,
      // above the router, and not inside a route (each route would get its
      // own). `create`, not `.value`: these providers own the cubits and
      // close them.
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => WishlistCubit()),
        ],
        child: MaterialApp.router(
          title: 'ShopLite',
          theme: buildAppTheme(),
          darkTheme: buildAppTheme(brightness: Brightness.dark),
          // Follow the phone's light/dark setting.
          themeMode: ThemeMode.system,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
