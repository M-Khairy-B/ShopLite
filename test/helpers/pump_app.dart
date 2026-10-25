import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';

import 'fake_products_repository.dart';

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

/// Shows only the home screen with [repository] (a fake catalog by default),
/// and waits until it has finished loading.
Future<void> pumpHomeScreen(
  WidgetTester tester, {
  ProductsRepository? repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(repository: repository ?? FakeProductsRepository()),
    ),
  );
  await tester.pumpAndSettle();
}
