import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('loading the catalog', () {
    testWidgets('shows a loading view, then the products', (tester) async {
      final gate = Completer<void>();
      final repository = FakeProductsRepository(gate: gate);

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(repository: repository)),
      );
      expect(find.byType(LoadingView), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(LoadingView), findsNothing);
      expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    });

    testWidgets('asks for the first page of the catalog', (tester) async {
      final repository = FakeProductsRepository();

      await pumpHomeScreen(tester, repository: repository);

      expect(repository.requestedPages, [(skip: 0, limit: 30)]);
    });

    testWidgets('a failed load shows the error, and "Try again" reloads', (
      tester,
    ) async {
      final repository = FakeProductsRepository(
        error: const NetworkException(),
      );

      await pumpHomeScreen(tester, repository: repository);
      expect(find.byType(ErrorView), findsOneWidget);

      repository.error = null; // the connection is back
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.getProductsCalls, 2);
      expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    });

    testWidgets('loads only once, even when the screen rebuilds', (
      tester,
    ) async {
      final repository = FakeProductsRepository();

      await pumpHomeScreen(tester, repository: repository);
      await pumpHomeScreen(tester, repository: repository);

      expect(repository.getProductsCalls, 1);
    });

    testWidgets('an empty catalog says so, without chips', (tester) async {
      await pumpHomeScreen(
        tester,
        repository: FakeProductsRepository(products: const []),
      );

      expect(find.text('No products yet'), findsOneWidget);
      expect(find.text('All'), findsNothing);
    });

    testWidgets('the chips come from the loaded products', (tester) async {
      // A catalog with only furniture and groceries in it.
      final repository = FakeProductsRepository(
        products: [
          for (final product in mockProducts.take(2))
            _withCategory(product, 'furniture'),
          _withCategory(mockProducts[2], 'groceries'),
        ],
      );

      await pumpHomeScreen(tester, repository: repository);

      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Beauty'), findsNothing);
    });
  });

  testWidgets('shows an All chip and one chip per category', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);
    expect(find.text('Fragrances'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Smartphones'), findsOneWidget);
  });

  testWidgets('selecting a category shows only its products', (tester) async {
    await pumpHomeScreen(tester);

    await tester.tap(find.text('Laptops'));
    await tester.pump();

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsNothing);
  });

  testWidgets('tapping a product opens its details, back returns home', (
    tester,
  ) async {
    // Navigation needs the app's router, so start the whole app.
    await pumpShopLiteApp(tester);

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('selecting All shows every category again', (tester) async {
    await pumpHomeScreen(tester);

    await tester.tap(find.text('Laptops'));
    await tester.pump();
    await tester.tap(find.text('All'));
    await tester.pump();

    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
  });
}

/// A copy of [product] in a different [category].
Product _withCategory(Product product, String category) {
  return Product(
    id: product.id,
    title: product.title,
    description: product.description,
    priceCents: product.priceCents,
    rating: product.rating,
    category: category,
    thumbnailUrl: product.thumbnailUrl,
  );
}
