import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/features/cart/presentation/screens/cart_screen.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/categories_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';
import 'package:e_commerce_learn/features/profile/presentation/screens/profile_screen.dart';

/// Taps a bottom-navigation tab by its label and waits for the transition.
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows four tabs and starts on Home', (tester) async {
    await tester.pumpWidget(const ShopLiteApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('each tab shows its own screen', (tester) async {
    await tester.pumpWidget(const ShopLiteApp());

    await _tapTab(tester, 'Categories');
    expect(find.byType(CategoriesScreen), findsOneWidget);

    await _tapTab(tester, 'Cart');
    expect(find.byType(CartScreen), findsOneWidget);

    await _tapTab(tester, 'Profile');
    expect(find.byType(ProfileScreen), findsOneWidget);

    await _tapTab(tester, 'Home');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a tab keeps its own stack while you visit another tab', (
    tester,
  ) async {
    await tester.pumpWidget(const ShopLiteApp());

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await _tapTab(tester, 'Cart');
    await _tapTab(tester, 'Home');

    // Still on the product we opened, not back at the catalog.
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
  });

  testWidgets('tapping the active tab again returns to its first screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ShopLiteApp());

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();

    await _tapTab(tester, 'Home');

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the sort sheet covers the navigation bar', (tester) async {
    await tester.pumpWidget(const ShopLiteApp());

    await tester.tap(find.byTooltip('Sort products'));
    await tester.pumpAndSettle();

    // Tap where the Cart tab is. A modal sheet should cover the whole app,
    // so this tap must only close the sheet, not switch tabs.
    final cartTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cart'),
    );
    await tester.tapAt(tester.getCenter(cartTab));
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 0); // still on Home
    expect(find.text('Sort by'), findsNothing); // the sheet closed
  });

  testWidgets('the empty cart leads back to shopping', (tester) async {
    await tester.pumpWidget(const ShopLiteApp());

    await _tapTab(tester, 'Cart');
    expect(find.text('Your cart is empty'), findsOneWidget);

    await tester.tap(find.text('Start shopping'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 0); // the Home tab
  });

  testWidgets('Home keeps its selected category while you visit another tab', (
    tester,
  ) async {
    await tester.pumpWidget(const ShopLiteApp());

    await tester.tap(find.text('Laptops'));
    await tester.pump();

    await _tapTab(tester, 'Profile');
    await _tapTab(tester, 'Home');

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsNothing);
  });
}
