import 'package:flutter/material.dart';

/// The brand color that the whole color scheme is generated from.
///
/// Change this one value to re-color the entire app.
const Color _brandSeedColor = Colors.deepPurple;

/// The color of rating stars.
///
/// Stars are conventionally gold, which is not part of the generated color
/// scheme, so it is defined here instead of being hard-coded in widgets.
const Color ratingStarColor = Colors.amber;

/// Builds the app's theme: colors, text styles, and component defaults.
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _brandSeedColor),
    // Declared in pubspec.yaml; every text style in the app uses it.
    fontFamily: 'Poppins',
    chipTheme: const ChipThemeData(
      // Without the checkmark, selecting a chip no longer changes its width,
      // so the chips next to it don't shift sideways.
      showCheckmark: false,
    ),
  );
}
