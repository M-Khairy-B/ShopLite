/// Returns [text] with its first letter in upper case, e.g. `'laptops'` ->
/// `'Laptops'`. An empty string is returned unchanged.
String capitalize(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text[0].toUpperCase() + text.substring(1);
}

/// How a screen reader should say a star rating, e.g. `'Rated 2.6 out of 5'`.
///
/// On screen we show a star icon next to "2.6"; read aloud, "2.6" alone
/// would mean nothing.
String ratingSemanticsLabel(double rating) {
  return 'Rated ${rating.toStringAsFixed(1)} out of 5';
}
