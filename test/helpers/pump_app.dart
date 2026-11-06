import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

import 'fake_products_repository.dart';

/// Puts what `ShopLiteApp` provides above [child], so screens below can
/// read it: [repository] (a fake catalog by default), [cart] and
/// [wishlist] (new, empty ones by default).
///
/// Pass your own [cart] or [wishlist] to fill it before the test, or to
/// check it after.
Widget withAppProviders(
  Widget child, {
  ProductsRepository? repository,
  CartCubit? cart,
  WishlistCubit? wishlist,
}) {
  return RepositoryProvider<ProductsRepository>.value(
    value: repository ?? FakeProductsRepository(),
    child: MultiBlocProvider(
      providers: [
        cart == null
            ? BlocProvider(create: (_) => CartCubit())
            : BlocProvider.value(value: cart),
        wishlist == null
            ? BlocProvider(create: (_) => WishlistCubit())
            : BlocProvider.value(value: wishlist),
      ],
      child: child,
    ),
  );
}

/// Starts the whole app with [repository] (a fake catalog by default), and
/// waits until the first screen has finished loading.
///
/// Waiting matters: a test that checks a screen while it is still loading
/// may pass without testing anything.
Future<void> pumpShopLiteApp(
  WidgetTester tester, {
  ProductsRepository? repository,
}) async {
  await tester.pumpWidget(
    ShopLiteApp(productsRepository: repository ?? FakeProductsRepository()),
  );
  await tester.pumpAndSettle();
}

/// Starts the app's router at [location], with what `ShopLiteApp` provides
/// above it ([cart] and [wishlist]: new, empty ones by default), and waits
/// until the screen has finished loading.
///
/// Like [pumpShopLiteApp], but on any page, and with a cart and a wishlist
/// the test can fill before and check after. A test that passes one closes
/// it.
Future<void> pumpAppAt(
  WidgetTester tester,
  String location, {
  CartCubit? cart,
  WishlistCubit? wishlist,
}) async {
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    withAppProviders(
      MaterialApp.router(routerConfig: router),
      cart: cart,
      wishlist: wishlist,
    ),
  );
  await tester.pumpAndSettle();
}

/// Drags the product grid as far down as it goes, like a user scrolling to
/// the end, and waits until everything that started has finished.
Future<void> scrollProductGridToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(ProductGrid), const Offset(0, -100000));
  await tester.pumpAndSettle();
}

/// Shows only the home screen with [repository] (a fake catalog by default),
/// and waits until it has finished loading.
Future<void> pumpHomeScreen(
  WidgetTester tester, {
  ProductsRepository? repository,
}) async {
  await tester.pumpWidget(
    withAppProviders(
      const MaterialApp(home: HomeScreen()),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}
