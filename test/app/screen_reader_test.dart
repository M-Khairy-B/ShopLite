import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/quantity_selector.dart';

/// What a screen reader (TalkBack, VoiceOver) announces for these widgets.
void main() {
  testWidgets('a product card is a button that says "Rated … out of 5"', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final card = tester.getSemantics(find.byType(ProductCard).first);
    expect(card, isSemantics(isButton: true, hasTapAction: true));
    expect(card.label, contains('Rated 2.6 out of 5'));

    semantics.dispose();
  });

  testWidgets('the product title on the details screen is a heading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: ProductDetailsScreen(productId: 1)),
    );

    expect(
      tester.getSemantics(find.text('Essence Mascara Lash Princess')),
      isSemantics(isHeader: true),
    );

    semantics.dispose();
  });

  testWidgets('the quantity selector announces "Quantity" and its value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuantitySelector())),
    );

    final selector = find.byType(QuantitySelector);
    expect(
      tester.getSemantics(selector),
      isSemantics(label: 'Quantity', value: '1'),
    );

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();

    expect(
      tester.getSemantics(selector),
      isSemantics(label: 'Quantity', value: '2'),
    );

    semantics.dispose();
  });
}
