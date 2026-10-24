import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/categories/presentation/screens/categories_screen.dart';

void main() {
  testWidgets('lists every category with its number of products', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CategoriesScreen()));

    expect(find.text('Beauty'), findsOneWidget);
    expect(find.text('Fragrances'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('Smartphones'), findsOneWidget);
    expect(find.text('2 products'), findsNWidgets(4));
  });
}
