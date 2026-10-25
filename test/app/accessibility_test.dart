import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/router.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';

/// Every screen of the app, by its location.
const _screens = {
  'home': '/',
  'product details': '/product/1',
  'categories': '/categories',
  'category products': '/categories/laptops',
  'cart': '/cart',
  'profile': '/profile',
  'page not found': '/nope',
};

/// Starts the real app (router + theme) at [location], in light or dark mode.
Future<void> _pumpAt(
  WidgetTester tester,
  String location, {
  Brightness brightness = Brightness.light,
}) async {
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildAppTheme(brightness: brightness),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

/// Checks Flutter's built-in accessibility guidelines on what is on screen.
Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: location) in _screens.entries) {
      testWidgets('$name meets the accessibility guidelines '
          '(${brightness.name} mode)', (tester) async {
        final semantics = tester.ensureSemantics();

        await _pumpAt(tester, location, brightness: brightness);
        await _expectAccessible(tester);

        semantics.dispose();
      });
    }
  }

  testWidgets('the sort sheet meets the accessibility guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpAt(tester, '/');
    await tester.tap(find.byTooltip('Sort products'));
    await tester.pumpAndSettle();
    await _expectAccessible(tester);

    semantics.dispose();
  });
}
