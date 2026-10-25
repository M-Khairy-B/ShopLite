import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/categories_screen.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/category_products_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

/// Starts a router-based app on [location], like opening a link to it.
Future<void> _pumpAt(WidgetTester tester, String location) async {
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('/ shows the home screen', (tester) async {
    await _pumpAt(tester, '/');

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('/product/78 shows that product, and back returns home', (
    tester,
  ) async {
    await _pumpAt(tester, '/product/78');

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('/product/abc (not a number) shows page not found', (
    tester,
  ) async {
    await _pumpAt(tester, '/product/abc');

    expect(find.text("This page doesn't exist."), findsOneWidget);
  });

  testWidgets('an unknown path shows page not found', (tester) async {
    await _pumpAt(tester, '/nope');

    expect(find.text("This page doesn't exist."), findsOneWidget);
  });

  testWidgets('"Back to home" on page not found returns to the catalog', (
    tester,
  ) async {
    await _pumpAt(tester, '/nope');

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  group('Categories tab', () {
    testWidgets('tapping a category shows only its products', (tester) async {
      await _pumpAt(tester, '/categories');

      await tester.tap(find.text('Laptops'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryProductsScreen), findsOneWidget);
      expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
      expect(find.text('Essence Mascara Lash Princess'), findsNothing);
    });

    testWidgets(
      '/categories/laptops opens directly, back returns to the list',
      (tester) async {
        await _pumpAt(tester, '/categories/laptops');

        expect(find.byType(CategoryProductsScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(CategoriesScreen), findsOneWidget);
      },
    );

    testWidgets(
      'a product opened from a category stays in the Categories tab',
      (tester) async {
        await _pumpAt(tester, '/categories/laptops');

        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        expect(find.byType(ProductDetailsScreen), findsOneWidget);
        final navigationBar = tester.widget<NavigationBar>(
          find.byType(NavigationBar),
        );
        expect(navigationBar.selectedIndex, 1); // the Categories tab
      },
    );

    testWidgets('an unknown category shows a message', (tester) async {
      await _pumpAt(tester, '/categories/furniture');

      expect(find.text('No products here'), findsOneWidget);

      await tester.tap(find.text('See all categories'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesScreen), findsOneWidget);
    });
  });
}
