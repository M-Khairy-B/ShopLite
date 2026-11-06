import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

import '../helpers/mock_products.dart';
import '../helpers/pump_app.dart';

/// Every screen of the app, by its location.
const _screens = {
  'home': '/',
  'product details': '/product/1',
  'search': '/search',
  'categories': '/categories',
  'category products': '/categories/laptops',
  'cart': '/cart',
  'profile': '/profile',
  'wishlist': '/profile/wishlist',
  'page not found': '/nope',
};

/// Starts the real app (router + theme) at [location], in light or dark mode,
/// with [cart] and [wishlist] (empty ones by default).
Future<void> _pumpAt(
  WidgetTester tester,
  String location, {
  Brightness brightness = Brightness.light,
  CartCubit? cart,
  WishlistCubit? wishlist,
}) async {
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    withAppProviders(
      MaterialApp.router(
        theme: buildAppTheme(brightness: brightness),
        routerConfig: router,
      ),
      cart: cart,
      wishlist: wishlist,
    ),
  );
  await tester.pumpAndSettle();
}

/// Checks Flutter's built-in accessibility guidelines on what is on screen.
Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: location) in _screens.entries) {
      testWidgets('$name meets the accessibility guidelines '
          '(${brightness.name} mode)', (tester) async {
        final semantics = tester.ensureSemantics();

        await _pumpAt(tester, location, brightness: brightness);
        await _expectAccessible(tester);

        semantics.dispose();
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('a cart with products meets the accessibility guidelines '
        '(${brightness.name} mode)', (tester) async {
      final semantics = tester.ensureSemantics();
      final cart = CartCubit()
        ..add(mockProducts[0])
        ..add(mockProducts[1], quantity: 10);
      addTearDown(cart.close);

      await _pumpAt(tester, '/cart', brightness: brightness, cart: cart);
      await _expectAccessible(tester);

      semantics.dispose();
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('a wishlist with products meets the accessibility guidelines '
        '(${brightness.name} mode)', (tester) async {
      final semantics = tester.ensureSemantics();
      final wishlist = WishlistCubit()
        ..toggle(mockProducts[0])
        ..toggle(mockProducts[1]);
      addTearDown(wishlist.close);

      await _pumpAt(
        tester,
        '/profile/wishlist',
        brightness: brightness,
        wishlist: wishlist,
      );
      await _expectAccessible(tester);

      semantics.dispose();
    });
  }

  // Hearts over photos: the guideline checks their contrast and size too.
  for (final brightness in Brightness.values) {
    testWidgets('saved hearts on Home meet the accessibility guidelines '
        '(${brightness.name} mode)', (tester) async {
      final semantics = tester.ensureSemantics();
      final wishlist = WishlistCubit()..toggle(mockProducts[0]);
      addTearDown(wishlist.close);

      await _pumpAt(tester, '/', brightness: brightness, wishlist: wishlist);
      await _expectAccessible(tester);

      semantics.dispose();
    });
  }

  testWidgets('the sort sheet meets the accessibility guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpAt(tester, '/');
    await tester.tap(find.byTooltip('Sort products'));
    await tester.pumpAndSettle();
    await _expectAccessible(tester);

    semantics.dispose();
  });
}
