import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

import 'helpers/fake_products_repository.dart';

void main() {
  testWidgets('App starts on the home screen with a product grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ShopLiteApp(productsRepository: FakeProductsRepository()),
    );

    expect(find.text('ShopLite'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/logo.png')),
      findsOneWidget,
    );
    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });
}
