import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/quantity_selector.dart';

void main() {
  Widget buildSelector({int maxQuantity = 10}) {
    return MaterialApp(
      home: Scaffold(body: QuantitySelector(maxQuantity: maxQuantity)),
    );
  }

  testWidgets('starts at 1 and the + and − buttons change the quantity', (
    tester,
  ) async {
    await tester.pumpWidget(buildSelector());
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('reports every new quantity to onChanged', (tester) async {
    final reported = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuantitySelector(onChanged: reported.add)),
      ),
    );

    // A pump after each tap: "−" is only enabled once 2 is on screen.
    for (final tooltip in ['Increase', 'Increase', 'Decrease']) {
      await tester.tap(find.byTooltip('$tooltip quantity'));
      await tester.pump();
    }

    expect(reported, [2, 3, 2]);
  });

  testWidgets('cannot go below 1', (tester) async {
    await tester.pumpWidget(buildSelector());

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('cannot go above the maximum', (tester) async {
    await tester.pumpWidget(buildSelector(maxQuantity: 2));

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
  });
}
