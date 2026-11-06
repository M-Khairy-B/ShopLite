import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';

import '../helpers/mock_products.dart';
import '../helpers/pump_app.dart';

/// The [CartCubit] that the widget of type [T] finds above it.
CartCubit _cartFrom<T extends Widget>(WidgetTester tester) {
  return tester.element(find.byType(T)).read<CartCubit>();
}

void main() {
  testWidgets('every tab and pushed screen finds the same cart', (
    tester,
  ) async {
    await pumpShopLiteApp(tester);
    final fromHome = _cartFrom<HomeScreen>(tester);

    await tester.tap(find.text('Essence Mascara Lash Princess'));
    await tester.pumpAndSettle();
    expect(_cartFrom<ProductDetailsScreen>(tester), same(fromHome));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cart'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_cartFrom<CartScreen>(tester), same(fromHome));
  });

  testWidgets('a product added on one screen is in the cart on another', (
    tester,
  ) async {
    await pumpShopLiteApp(tester);

    _cartFrom<HomeScreen>(tester).add(mockProducts.first);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Cart'),
      ),
    );
    await tester.pumpAndSettle();

    expect(_cartFrom<CartScreen>(tester).state.quantityOf(1), 1);
  });

  testWidgets('the cart is closed when the app goes away', (tester) async {
    await pumpShopLiteApp(tester);
    final cart = _cartFrom<HomeScreen>(tester);

    await tester.pumpWidget(const SizedBox());

    expect(cart.isClosed, isTrue);
  });
}
