import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

/// The style the price is really drawn with, after the theme's default
/// text style was merged in.
TextStyle _drawnStyle(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(
    find.descendant(
      of: find.byType(PriceText),
      matching: find.byType(RichText),
    ),
  );
  expect(richText.text.toPlainText(), text);
  return richText.text.style!;
}

void main() {
  testWidgets('shows the price in cents as dollars', (tester) async {
    await tester.pumpWidget(_host(const PriceText(199999)));

    expect(find.text('\$1,999.99'), findsOneWidget);
  });

  testWidgets('draws the price with the given style', (tester) async {
    await tester.pumpWidget(
      _host(
        const PriceText(
          1999,
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
      ),
    );

    final style = _drawnStyle(tester, '\$19.99');
    expect(style.color, Colors.teal);
    expect(style.fontWeight, FontWeight.bold);
  });

  // Equal-width digits: a total that changes ($9.99 → $19.98) doesn't
  // make the text around it shift by a pixel or two.
  testWidgets('draws every digit the same width', (tester) async {
    await tester.pumpWidget(_host(const PriceText(1999)));
    expect(
      _drawnStyle(tester, '\$19.99').fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );

    // Also when a style is given: it's added to that style.
    await tester.pumpWidget(
      _host(const PriceText(1999, style: TextStyle(color: Colors.teal))),
    );
    final style = _drawnStyle(tester, '\$19.99');
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(style.color, Colors.teal);
  });
}
