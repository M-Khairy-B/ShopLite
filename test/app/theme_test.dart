import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';

import '../helpers/pump_app.dart';

/// The brightness of the theme the home screen is actually drawn with.
Brightness _homeBrightness(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(HomeScreen))).brightness;
}

void main() {
  test('buildAppTheme is light by default', () {
    expect(buildAppTheme().brightness, Brightness.light);
  });

  test('buildAppTheme can build a dark theme from the same seed', () {
    final dark = buildAppTheme(brightness: Brightness.dark);

    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.brightness, Brightness.dark);
  });

  testWidgets('the app is light when the phone is in light mode', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpShopLiteApp(tester);

    expect(_homeBrightness(tester), Brightness.light);
  });

  testWidgets('the app follows the phone into dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpShopLiteApp(tester);

    expect(_homeBrightness(tester), Brightness.dark);
  });
}
