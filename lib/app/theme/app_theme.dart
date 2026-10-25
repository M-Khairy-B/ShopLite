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
///
/// The light and dark themes come from the same seed color, so both feel
/// like the same brand. Widgets use color roles (`colorScheme.primary`...),
/// which is why they need no changes to work in dark mode.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _brandSeedColor,
      brightness: brightness,
    ),
    // Declared in pubspec.yaml; every text style in the app uses it.
    fontFamily: 'Poppins',
    chipTheme: const ChipThemeData(
      // Without the checkmark, selecting a chip no longer changes its width,
      // so the chips next to it don't shift sideways.
      showCheckmark: false,
    ),
  );
}
