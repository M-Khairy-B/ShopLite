// Checks for form fields. Each returns the message to show under the field,
// or `null` when the value is fine: the shape `TextFormField.validator`
// expects.
//
// These checks only help the user. A server must check everything again,
// because anyone can send it a request without using this app.

/// Something must be typed: `'Enter your username'` when [value] is empty
/// or only spaces. [fieldName] is how the message names the field.
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter your $fieldName';
  }
  return null;
}

/// Shaped like an email: something, `@`, something, a dot, something, with
/// no spaces. Spaces around it are ignored: the form sends it trimmed.
///
/// Only the shape. Whether the address exists, only sending it an email can
/// tell, and that's the server's job.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Enter your email';
  }
  if (!_emailShape.hasMatch(email)) {
    return 'Enter a valid email, like name@example.com';
  }
  return null;
}

final _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// The second password field must be exactly [password].
///
/// Not trimmed: a space is part of a password, so `'abc12345 '` is a
/// different one.
String? validatePasswordConfirmation(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Confirm your password';
  }
  if (value != password) {
    return "Passwords don't match";
  }
  return null;
}

/// The rules for a **new** password, on the registration form. Returns the
/// message of the **first** rule that fails, in this order:
///
/// 1. `null` or empty → `'Enter a password'`
/// 2. Starts or ends with a space → `'Remove the spaces at the start or end'`
/// 3. Fewer than [minPasswordLength] characters → `'Use at least 8 characters'`
/// 4. More than [maxPasswordLength] characters → `'Use at most 64 characters'`
/// 5. No letter, of any alphabet (`a`, `Z`, `é`, `ب`) →
///    `'Include at least one letter'`
/// 6. No digit 0–9 → `'Include at least one number'`
///
/// Never trimmed: trimming would quietly change the password the user chose.
/// Spaces inside are allowed (`'correct horse 42'`).
///
/// Not for the login form: an account made before these rules (like
/// DummyJSON's demo account, whose password has no digit) must still be
/// able to sign in. Login only checks that something was typed
/// ([validateRequired]).
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter a password';
  }
  if (value.startsWith(' ') || value.endsWith(' ')) {
    return 'Remove the spaces at the start or end';
  }
  if (value.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters';
  }
  if (value.length > maxPasswordLength) {
    return 'Use at most $maxPasswordLength characters';
  }
  if (!_anyLetter.hasMatch(value)) {
    return 'Include at least one letter';
  }
  if (!_digit.hasMatch(value)) {
    return 'Include at least one number';
  }
  return null;
}

const minPasswordLength = 8;
const maxPasswordLength = 64;

/// A letter of any alphabet. `\p{L}` is Unicode's "letter" category, and
/// it only works with `unicode: true`.
final _anyLetter = RegExp(r'\p{L}', unicode: true);

final _digit = RegExp(r'[0-9]');
