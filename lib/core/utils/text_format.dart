/// Returns [text] with its first letter in upper case, e.g. `'laptops'` ->
/// `'Laptops'`. An empty string is returned unchanged.
String capitalize(String text) {
  if (text.isEmpty) {
    return text;
  }
  return text[0].toUpperCase() + text.substring(1);
}
