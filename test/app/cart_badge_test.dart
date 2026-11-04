import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app_shell.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/cart/presentation/widgets/cart_tab_icon.dart';

import '../helpers/mock_products.dart';
import '../helpers/pump_app.dart';

/// A new cart cubit, closed after the test.
CartCubit _cart() {
  final cart = CartCubit();
  addTearDown(cart.close);
  return cart;
}

/// The text the Cart tab's badge shows, or `null` when it is hidden.
String? _badgeText(WidgetTester tester) {
  final badge = tester.widget<Badge>(
    find.descendant(of: find.byType(CartTabIcon), matching: find.byType(Badge)),
  );
  if (!badge.isLabelVisible) {
    return null;
  }
  return (badge.label! as Text).data;
}

/// Lets the screen catch up with a change made straight on the cubit.
///
/// The cubit's stream delivers a new state in a microtask, after `pump()`
/// has already checked for work, so one `pump()` would draw nothing new.
Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

/// What a screen reader announces for the Cart tab.
String _cartTabLabel(WidgetTester tester) {
  return tester
      .getSemantics(
        find.ancestor(
          of: find.byType(CartTabIcon),
          matching: find.byType(NavigationDestination),
        ),
      )
      .label;
}

void main() {
  testWidgets('an empty cart shows no badge', (tester) async {
    await pumpAppAt(tester, '/', cart: _cart());

    expect(_badgeText(tester), isNull);
  });

  testWidgets('the badge counts items, not lines, and follows the cart', (
    tester,
  ) async {
    final cart = _cart();
    await pumpAppAt(tester, '/', cart: cart);

    cart
      ..add(mockProducts[0], quantity: 2)
      ..add(mockProducts[1]);
    await _settle(tester);
    expect(_badgeText(tester), '3');

    cart.remove(mockProducts[0].id);
    await _settle(tester);
    expect(_badgeText(tester), '1');

    cart.clear();
    await _settle(tester);
    expect(_badgeText(tester), isNull);
  });

  testWidgets('more than 9 shows "9+"', (tester) async {
    final cart = _cart()
      ..add(mockProducts[0], quantity: maxQuantityPerItem)
      ..add(mockProducts[1], quantity: 2);
    await pumpAppAt(tester, '/', cart: cart);

    expect(_badgeText(tester), '9+');
  });

  testWidgets('a screen reader hears the exact number, not "9+"', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final cart = _cart()
      ..add(mockProducts[0], quantity: maxQuantityPerItem)
      ..add(mockProducts[1], quantity: 2);
    await pumpAppAt(tester, '/', cart: cart);

    final label = _cartTabLabel(tester);
    expect(label, contains('Cart'));
    expect(label, contains('12 items'));
    expect(label, isNot(contains('9+')));

    semantics.dispose();
  });

  testWidgets('a screen reader hears "1 item", not "1 items"', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpAppAt(tester, '/', cart: _cart()..add(mockProducts[0]));

    final label = _cartTabLabel(tester);
    expect(label, contains('1 item'));
    expect(label, isNot(contains('1 items')));

    semantics.dispose();
  });

  testWidgets('a cart change rebuilds the badge, not the whole shell', (
    tester,
  ) async {
    final cart = _cart();
    await pumpAppAt(tester, '/', cart: cart);

    // Flutter calls this (in debug builds) for every widget it rebuilds.
    final rebuilt = <Type>[];
    debugOnRebuildDirtyWidget = (element, _) {
      rebuilt.add(element.widget.runtimeType);
    };
    cart.add(mockProducts[0]);
    await _settle(tester);
    debugOnRebuildDirtyWidget = null;

    expect(rebuilt, contains(CartTabIcon));
    expect(rebuilt, isNot(contains(AppShell)));
  });
}
