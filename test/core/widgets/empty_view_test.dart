import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the title, the message and the action', (tester) async {
    await tester.pumpWidget(
      _host(
        EmptyView(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          message: 'Products you add will appear here.',
          action: FilledButton(
            onPressed: () {},
            child: const Text('Start shopping'),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Products you add will appear here.'), findsOneWidget);
    expect(find.text('Start shopping'), findsOneWidget);
  });

  testWidgets('leaves out the message and the action when not given', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EmptyView(icon: Icons.inbox_outlined, title: 'Nothing here')),
    );

    expect(find.byType(Text), findsOneWidget); // only the title
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('the action can be tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(
        EmptyView(
          icon: Icons.inbox_outlined,
          title: 'Nothing here',
          action: FilledButton(
            onPressed: () => tapped = true,
            child: const Text('Go'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));

    expect(tapped, isTrue);
  });

  testWidgets('has no overflow on a short screen with the largest text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1080); // landscape phone
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _host(
        EmptyView(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
          message: 'Products you add to your cart will appear here.',
          action: FilledButton(
            onPressed: () {},
            child: const Text('Start shopping'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
