import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';

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
}
