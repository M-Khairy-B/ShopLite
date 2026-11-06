import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/cart/presentation/screens/cart_screen.dart';

import '../../../../helpers/mock_products.dart';
import '../../../../helpers/pump_app.dart';

final _mascara = mockProducts[0]; // id 1, $9.99
final _palette = mockProducts[1]; // id 2, $19.99
final _perfume = mockProducts[2]; // id 6, $49.99

/// A cart cubit with 2 mascaras, 1 palette and 1 perfume, in that order.
CartCubit _threeLines() {
  return CartCubit()
    ..add(_mascara, quantity: 2)
    ..add(_palette)
    ..add(_perfume);
}

/// Shows the cart screen with [cart], and closes the cubit after the test.
Future<void> _pumpCart(WidgetTester tester, CartCubit cart) async {
  addTearDown(cart.close);
  await tester.pumpWidget(
    withAppProviders(const MaterialApp(home: CartScreen()), cart: cart),
  );
  await tester.pumpAndSettle();
}

/// The row of the product with [productId].
Finder _line(int productId) => find.byKey(ValueKey(productId));

/// The widget matching [finder] inside the row of [productId].
Finder _inLine(int productId, Finder finder) {
  return find.descendant(of: _line(productId), matching: finder);
}

/// The product ids of the rows on screen, top to bottom, with quantities.
List<(int, int)> _lines(CartCubit cart) {
  return [for (final item in cart.state.items) (item.productId, item.quantity)];
}

/// Swipes the row of [productId] away, from right to left.
Future<void> _swipeAway(WidgetTester tester, int productId) async {
  await tester.drag(_line(productId), const Offset(-1000, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty cart shows the empty state', (tester) async {
    await _pumpCart(tester, CartCubit());

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Proceed to checkout'), findsNothing);
  });

  testWidgets('each line shows its title, quantity, price and total', (
    tester,
  ) async {
    await _pumpCart(tester, _threeLines());

    expect(_inLine(1, find.text('Essence Mascara Lash Princess')), findsOne);
    expect(_inLine(1, find.text('\$9.99 each')), findsOne);
    expect(_inLine(1, find.text('2')), findsOne);
    // 2 × $9.99
    expect(_inLine(1, find.widgetWithText(PriceText, '\$19.98')), findsOne);
    expect(_line(2), findsOne);
    expect(_line(6), findsOne);
  });

  testWidgets('the footer shows the subtotal and the number of items', (
    tester,
  ) async {
    await _pumpCart(tester, _threeLines());

    expect(find.text('Subtotal (4 items)'), findsOne);
    // 19.98 + 19.99 + 49.99
    expect(find.widgetWithText(PriceText, '\$89.96'), findsOne);
  });

  testWidgets('one item is "1 item", not "1 items"', (tester) async {
    await _pumpCart(tester, CartCubit()..add(_mascara));

    expect(find.text('Subtotal (1 item)'), findsOne);
  });

  testWidgets('+ adds one, and the totals follow', (tester) async {
    final cart = _threeLines();
    await _pumpCart(tester, cart);

    await tester.tap(_inLine(1, find.byTooltip('Increase quantity')));
    await tester.pump();

    expect(cart.state.quantityOf(1), 3);
    expect(_inLine(1, find.widgetWithText(PriceText, '\$29.97')), findsOne);
    expect(find.text('Subtotal (5 items)'), findsOne);
  });

  testWidgets('− takes one away', (tester) async {
    final cart = _threeLines();
    await _pumpCart(tester, cart);

    await tester.tap(_inLine(1, find.byTooltip('Decrease quantity')));
    await tester.pump();

    expect(cart.state.quantityOf(1), 1);
  });

  testWidgets('− is disabled at 1, and + at the limit', (tester) async {
    final cart = CartCubit()
      ..add(_mascara)
      ..add(_palette, quantity: maxQuantityPerItem);
    await _pumpCart(tester, cart);

    IconButton button(int productId, String tooltip) {
      return tester.widget<IconButton>(
        find.ancestor(
          of: _inLine(productId, find.byTooltip(tooltip)),
          matching: find.byType(IconButton),
        ),
      );
    }

    expect(button(1, 'Decrease quantity').onPressed, isNull);
    expect(button(1, 'Increase quantity').onPressed, isNotNull);
    expect(button(2, 'Increase quantity').onPressed, isNull);
    expect(button(2, 'Decrease quantity').onPressed, isNotNull);
  });

  group('removing a line', () {
    testWidgets('a swipe removes it and offers Undo', (tester) async {
      final cart = _threeLines();
      await _pumpCart(tester, cart);

      await _swipeAway(tester, 2);

      expect(_lines(cart), [(1, 2), (6, 1)]);
      expect(_line(2), findsNothing);
      expect(find.text('Removed Eyeshadow Palette with Mirror'), findsOne);
      expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOne);
    });

    testWidgets('the delete button does the same, without swiping', (
      tester,
    ) async {
      final cart = _threeLines();
      await _pumpCart(tester, cart);

      await tester.tap(_inLine(2, find.byTooltip('Remove from cart')));
      await tester.pumpAndSettle();

      expect(_lines(cart), [(1, 2), (6, 1)]);
      expect(find.text('Removed Eyeshadow Palette with Mirror'), findsOne);
    });

    testWidgets('Undo puts it back in its place, with its quantity', (
      tester,
    ) async {
      final cart = _threeLines();
      await _pumpCart(tester, cart);
      final before = cart.state;

      await _swipeAway(tester, 1); // the 2 mascaras, at the top
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(cart.state, before);
      expect(_inLine(1, find.text('2')), findsOne);
    });

    testWidgets('Undo keeps changes made to other lines since', (tester) async {
      final cart = _threeLines();
      await _pumpCart(tester, cart);

      await _swipeAway(tester, 2);
      await tester.tap(_inLine(1, find.byTooltip('Increase quantity')));
      await tester.pump();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(_lines(cart), [(1, 3), (2, 1), (6, 1)]);
    });

    testWidgets('removing the last line shows the empty state', (tester) async {
      await _pumpCart(tester, CartCubit()..add(_mascara));

      await _swipeAway(tester, 1);

      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    // The list leaves the tree when the cart is empty, so Undo must not
    // depend on anything found from inside the list at the time of the tap.
    testWidgets('Undo works even after the last line, from the empty state', (
      tester,
    ) async {
      final cart = CartCubit()..add(_mascara, quantity: 2);
      await _pumpCart(tester, cart);

      await _swipeAway(tester, 1);
      expect(find.text('Your cart is empty'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_lines(cart), [(1, 2)]);
      expect(_line(1), findsOne);
    });

    testWidgets('a second removal replaces the first snackbar', (tester) async {
      await _pumpCart(tester, _threeLines());

      await _swipeAway(tester, 1);
      await _swipeAway(tester, 2);

      expect(find.byType(SnackBar), findsOne);
      expect(find.text('Removed Eyeshadow Palette with Mirror'), findsOne);
    });
  });

  testWidgets('checkout is not built yet, and says so', (tester) async {
    await _pumpCart(tester, _threeLines());

    await tester.tap(find.text('Proceed to checkout'));
    await tester.pump();

    expect(find.text('Checkout is coming soon.'), findsOne);
  });

  testWidgets('fits a small phone with the largest text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpCart(
      tester,
      CartCubit()..add(_palette, quantity: maxQuantityPerItem),
    );

    // An overflow is reported as an exception: none means everything fits.
    expect(tester.takeException(), isNull);
    expect(find.text('Proceed to checkout'), findsOne);
  });
}
