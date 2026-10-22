import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

void main() {
  testWidgets('shows an All chip and one chip per category', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);
    expect(find.text('Fragrances'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Smartphones'), findsOneWidget);
  });

  testWidgets('selecting a category shows only its products', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text('Laptops'));
    await tester.pump();

    expect(find.text('Apple MacBook Pro 14 Inch Space Grey'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsNothing);
  });

  testWidgets('tapping a product opens its details, back returns home', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('selecting All shows every category again', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text('Laptops'));
    await tester.pump();
    await tester.tap(find.text('All'));
    await tester.pump();

    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
  });
}
