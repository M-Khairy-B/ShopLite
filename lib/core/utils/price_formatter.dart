/// Formats a price in cents as a dollar string, e.g. `1999` -> `'$19.99'`.
///
/// Uses only integer arithmetic, so no floating-point rounding can occur.
String formatPrice(int cents) {
  assert(cents >= 0, 'Price cannot be negative: $cents');

  final dollars = cents ~/ 100;
  final remainingCents = cents % 100;

  return '\$$dollars.${remainingCents.toString().padLeft(2, '0')}';
}
