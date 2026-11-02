import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';

import 'fake_products_repository.dart';

/// Puts [repository] (a fake catalog by default) above [child], the way
/// `ShopLiteApp` does for the real app, so screens below can read it.
Widget withProductsRepository(Widget child, {ProductsRepository? repository}) {
  return RepositoryProvider<ProductsRepository>.value(
    value: repository ?? FakeProductsRepository(),
    child: child,
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
    withProductsRepository(
      const MaterialApp(home: HomeScreen()),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}
