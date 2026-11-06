import 'package:intl/intl.dart';

/// US dollars, written the US way: `$1,999.99`. Made once and reused.
///
/// Fixed, not taken from the phone's language: every price in the app is in
/// dollars, so a German phone still shows dollars (`$`, not `€`). If the app
/// is translated later, this is the one place to give a locale.
final _usDollars = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');

/// Formats a price in cents as a dollar string, e.g. `199999` ->
/// `'$1,999.99'`.
///
/// Prices are stored and added up as int cents. Only here, to be shown, do
/// they become dollars: a double, rounded to whole cents as it's formatted,
/// so a value like 19.98999… still shows as `$19.99`.
String formatPrice(int cents) {
  assert(cents >= 0, 'Price cannot be negative: $cents');

  return _usDollars.format(cents / 100);
}
