import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/category_products_screen.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';

import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/pump_app.dart';

/// The products screen of [category], getting products from [repository].
Widget _categoryScreen(
  FakeProductsRepository repository, {
  String category = 'laptops',
}) {
  return withProductsRepository(
    MaterialApp(home: CategoryProductsScreen(category: category)),
    repository: repository,
  );
}

void main() {
  testWidgets('shows a loading view, then the products of the category', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeProductsRepository(gate: gate);

    await tester.pumpWidget(_categoryScreen(repository));
    expect(find.byType(LoadingView), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsNothing);
    expect(repository.requestedPages, [
      (skip: 0, limit: 30, category: 'laptops', sort: ProductSort.featured),
    ]);
  });

  testWidgets('a failed load shows the error, and "Try again" reloads', (
    tester,
  ) async {
    final repository = FakeProductsRepository(error: const NetworkException());

    await tester.pumpWidget(_categoryScreen(repository));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    repository.error = null; // the connection is back
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
  });

  testWidgets('a category without products says so', (tester) async {
    await tester.pumpWidget(
      _categoryScreen(FakeProductsRepository(), category: 'furniture'),
    );
    await tester.pumpAndSettle();

    expect(find.text('No products here'), findsOneWidget);
    expect(find.text('See all categories'), findsOneWidget);
  });
}
