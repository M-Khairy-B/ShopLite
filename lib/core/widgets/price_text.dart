import 'package:flutter/material.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';

/// A price on screen: [cents] shown as dollars, e.g. `$1,999.99`.
///
/// Every digit is drawn the same width, so a total that changes (from
/// `$9.99` to `$19.98`) doesn't shift the text next to it. [style] sets the
/// rest: size, color, weight.
///
/// For a price inside a sentence ("$9.99 each", a snackbar), use
/// [formatPrice] instead: it gives the same text as a `String`.
class PriceText extends StatelessWidget {
  const PriceText(this.cents, {super.key, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPrice(cents),
      style: (style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
