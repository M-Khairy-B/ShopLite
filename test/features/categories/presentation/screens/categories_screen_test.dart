import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/categories_screen.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';

import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/pump_app.dart';

/// The Categories tab, getting its categories from [repository].
Widget _categoriesScreen(FakeProductsRepository repository) {
  return withProductsRepository(
    const MaterialApp(home: CategoriesScreen()),
    repository: repository,
  );
}

void main() {
  testWidgets('shows a loading view, then the name of every category', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeProductsRepository(
      categories: const [
        ProductCategory(slug: 'beauty', name: 'Beauty'),
        ProductCategory(slug: 'home-decoration', name: 'Home Decoration'),
      ],
      gate: gate,
    );

    await tester.pumpWidget(_categoriesScreen(repository));
    expect(find.byType(LoadingView), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Beauty'), findsOneWidget);
    // The API's own name, not the slug.
    expect(find.text('Home Decoration'), findsOneWidget);
  });

  testWidgets('a failed load shows the error, and "Try again" reloads', (
    tester,
  ) async {
    final repository = FakeProductsRepository(error: const NetworkException());

    await tester.pumpWidget(_categoriesScreen(repository));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    repository.error = null; // the connection is back
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.getCategoriesCalls, 2);
    expect(find.text('Laptops'), findsOneWidget);
  });

  testWidgets('no categories says so', (tester) async {
    await tester.pumpWidget(
      _categoriesScreen(FakeProductsRepository(categories: const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('No categories yet'), findsOneWidget);
  });
}
