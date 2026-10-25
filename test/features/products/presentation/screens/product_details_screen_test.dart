import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';

void main() {
  testWidgets('shows the product title, price, rating and description', (
    tester,
  ) async {
    // Use a phone-sized screen (like our emulator) instead of the default
    // 800x600 test screen.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final product = mockProducts.first;

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(productId: product.id)),
    );

    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(find.text('\$9.99'), findsOneWidget);
    expect(find.text('2.6'), findsOneWidget);
    expect(find.text(product.description), findsOneWidget);
  });

  testWidgets('shows a message for an id that does not exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProductDetailsScreen(productId: 999999)),
    );

    expect(find.text('Product not found'), findsOneWidget);
  });
}
