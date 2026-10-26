import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';

import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/pump_app.dart';

/// The details screen for [productId], getting products from [repository].
Widget _details(FakeProductsRepository repository, {int productId = 1}) {
  return withProductsRepository(
    MaterialApp(home: ProductDetailsScreen(productId: productId)),
    repository: repository,
  );
}

void main() {
  testWidgets('shows a loading view, then the product', (tester) async {
    // Use a phone-sized screen (like our emulator), so all text is built.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final gate = Completer<void>();
    final repository = FakeProductsRepository(gate: gate);

    await tester.pumpWidget(_details(repository));
    expect(find.byType(LoadingView), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(LoadingView), findsNothing);
    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(find.text('\$9.99'), findsOneWidget);
    expect(find.text('2.6'), findsOneWidget);
  });

  testWidgets('a product that does not exist shows "Product not found"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _details(FakeProductsRepository(), productId: 999999),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product not found'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('a failed load shows the error, and "Try again" reloads', (
    tester,
  ) async {
    final repository = FakeProductsRepository(error: const NetworkException());

    await tester.pumpWidget(_details(repository));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text("You're offline"), findsOneWidget);

    repository.error = null; // the connection is back
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.getProductCalls, 2);
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
  });

  testWidgets('loads only once, even when the screen rebuilds', (tester) async {
    final repository = FakeProductsRepository();

    await tester.pumpWidget(_details(repository));
    await tester.pumpAndSettle();
    // Build the same screen again, as happens when a parent rebuilds.
    await tester.pumpWidget(_details(repository));
    await tester.pumpAndSettle();

    expect(repository.getProductCalls, 1);
  });

  testWidgets('loads the new product when the id changes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final repository = FakeProductsRepository();

    await tester.pumpWidget(_details(repository));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_details(repository, productId: 78));
    await tester.pumpAndSettle();

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
    expect(repository.getProductCalls, 2);
  });
}
