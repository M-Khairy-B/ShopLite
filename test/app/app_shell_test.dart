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
