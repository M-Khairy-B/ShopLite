import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/category_products_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_cubit.dart';

import '../../../helpers/mock_products.dart';
import '../../../helpers/pump_app.dart';

final _mascara = mockProducts[0]; // id 1
const _mascaraTitle = 'Essence Mascara Lash Princess';

/// A new cart cubit, closed after the test.
CartCubit _cart() {
  final cart = CartCubit();
  addTearDown(cart.close);
  return cart;
}

/// The details screen's "Add to cart" button.
final _addButton = find.widgetWithText(FilledButton, 'Add to cart');

/// Taps the details screen's "+" [plusTaps] times, then "Add to cart".
Future<void> _addFromDetails(WidgetTester tester, {int plusTaps = 0}) async {
  for (var i = 0; i < plusTaps; i++) {
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
  }
  await tester.ensureVisible(_addButton);
  await tester.tap(_addButton);
  await tester.pump();
}

/// The "Add to cart" button on the card of [productTitle].
Finder _cardButton(String productTitle) {
  return find.descendant(
    of: find.widgetWithText(ProductCard, productTitle),
    matching: find.byTooltip('Add to cart'),
  );
}

void main() {
  group('on the details screen', () {
    testWidgets('adds the quantity chosen in the selector', (tester) async {
      final cart = _cart();
      await pumpAppAt(tester, '/product/1', cart: cart);

      await _addFromDetails(tester, plusTaps: 2);

      expect(cart.state.quantityOf(1), 3);
      expect(find.text('Added 3 × $_mascaraTitle'), findsOne);
      expect(find.widgetWithText(SnackBarAction, 'View cart'), findsOne);
    });

    testWidgets('adds 1 when the selector is left alone', (tester) async {
      final cart = _cart();
      await pumpAppAt(tester, '/product/1', cart: cart);

      await _addFromDetails(tester);

      expect(cart.state.quantityOf(1), 1);
      expect(find.text('Added 1 × $_mascaraTitle'), findsOne);
    });

    testWidgets('the selector goes up to the limit per product', (
      tester,
    ) async {
      await pumpAppAt(tester, '/product/1', cart: _cart());

      for (var i = 1; i < maxQuantityPerItem; i++) {
        await tester.tap(find.byTooltip('Increase quantity'));
        await tester.pump();
      }

      final plus = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Increase quantity'),
          matching: find.byType(IconButton),
        ),
      );
      expect(plus.onPressed, isNull);
    });

    testWidgets('near the limit, it says how many it could add', (
      tester,
    ) async {
      final cart = _cart()..add(_mascara, quantity: 8);
      await pumpAppAt(tester, '/product/1', cart: cart);

      await _addFromDetails(tester, plusTaps: 3); // asks for 4

      expect(cart.state.quantityOf(1), maxQuantityPerItem);
      expect(
        find.text(
          'Added 2 × $_mascaraTitle. You now have 10, the limit per product.',
        ),
        findsOne,
      );
    });

    // Found on the emulator: a 3-line snackbar covered the button, so the
    // next tap landed on the snackbar instead.
    testWidgets('the snackbar shows above the "Add to cart" button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400); // a phone
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final cart = _cart()..add(_mascara, quantity: 8);
      await pumpAppAt(tester, '/product/1', cart: cart);

      await _addFromDetails(tester, plusTaps: 3); // the long message
      await tester.pumpAndSettle(); // until the snackbar has slid in

      final snackBar = tester.getRect(find.byType(SnackBar));
      final button = tester.getRect(_addButton);
      // Entirely above it: then no scroll position and no message length
      // can put the snackbar over the button.
      expect(snackBar.bottom, lessThanOrEqualTo(button.top));
    });

    testWidgets('at the limit, it adds nothing and says why', (tester) async {
      final cart = _cart()..add(_mascara, quantity: maxQuantityPerItem);
      await pumpAppAt(tester, '/product/1', cart: cart);
      final before = cart.state;

      await _addFromDetails(tester);

      expect(cart.state, before);
      expect(
        find.text(
          'Your cart already has 10 × $_mascaraTitle, the limit per product.',
        ),
        findsOne,
      );
    });

    testWidgets('"View cart" opens the Cart tab', (tester) async {
      await pumpAppAt(tester, '/product/1', cart: _cart());

      await _addFromDetails(tester);
      await tester.pumpAndSettle(); // until the snackbar has slid in
      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();

      expect(find.byType(CartScreen), findsOne);
      expect(find.text(_mascaraTitle), findsOne); // its line in the cart
    });

    testWidgets('the snackbar goes away with the screen', (tester) async {
      await pumpAppAt(tester, '/product/1', cart: _cart());

      await _addFromDetails(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a second add replaces the first snackbar', (tester) async {
      await pumpAppAt(tester, '/product/1', cart: _cart());

      await _addFromDetails(tester);
      await _addFromDetails(tester);

      expect(find.byType(SnackBar), findsOne);
    });
  });

  group('on a product card', () {
    // A card's snackbar is the app's, so it outlives the screen it was shown
    // from: "View cart" must not depend on that screen when it's tapped.
    testWidgets('"View cart" still works after leaving the screen', (
      tester,
    ) async {
      await pumpAppAt(tester, '/categories/beauty', cart: _cart());

      await tester.tap(_cardButton(_mascaraTitle));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CategoryProductsScreen), findsNothing);
      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CartScreen), findsOne);
    });

    testWidgets('on Home, adds 1 without opening the product', (tester) async {
      final cart = _cart();
      await pumpAppAt(tester, '/', cart: cart);

      await tester.tap(_cardButton(_mascaraTitle));
      await tester.pump();

      expect(cart.state.quantityOf(1), 1);
      expect(find.text('Added 1 × $_mascaraTitle'), findsOne);
      expect(find.byType(ProductDetailsScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOne);
    });

    testWidgets('a tap on the rest of the card still opens the product', (
      tester,
    ) async {
      final cart = _cart();
      await pumpAppAt(tester, '/', cart: cart);

      await tester.tap(find.text(_mascaraTitle));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailsScreen), findsOne);
      expect(cart.state.isEmpty, isTrue);
    });

    testWidgets('in a category, adds the product', (tester) async {
      final cart = _cart();
      await pumpAppAt(tester, '/categories/beauty', cart: cart);

      await tester.tap(_cardButton(_mascaraTitle));
      await tester.pump();

      expect(cart.state.quantityOf(1), 1);
    });

    testWidgets('in search results, adds the product', (tester) async {
      final cart = _cart();
      await pumpAppAt(tester, '/search', cart: cart);

      await tester.enterText(find.byType(TextField), 'mascara');
      await tester.pump(SearchCubit.debounce);
      await tester.pumpAndSettle();
      await tester.tap(_cardButton(_mascaraTitle));
      await tester.pump();

      expect(cart.state.quantityOf(1), 1);
    });
  });
}
