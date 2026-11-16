import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/utils/validators.dart';

void main() {
  group('validateRequired', () {
    test('accepts any text', () {
      expect(validateRequired('emilys', 'username'), isNull);
    });

    test('asks for the field when it is empty', () {
      expect(validateRequired('', 'username'), 'Enter your username');
      expect(validateRequired(null, 'username'), 'Enter your username');
    });

    test('treats only spaces as empty', () {
      expect(validateRequired('   ', 'first name'), 'Enter your first name');
    });
  });

  group('validateEmail', () {
    test('accepts a normal address', () {
      expect(validateEmail('emily.johnson@x.dummyjson.com'), isNull);
    });

    test('ignores spaces around it, as the form sends it trimmed', () {
      expect(validateEmail('  name@example.com '), isNull);
    });

    test('asks for an email when it is empty', () {
      expect(validateEmail(''), 'Enter your email');
      expect(validateEmail(null), 'Enter your email');
      expect(validateEmail('   '), 'Enter your email');
    });

    test('rejects text that is not shaped like an email', () {
      const message = 'Enter a valid email, like name@example.com';
      for (final email in [
        'name',
        'name@',
        '@example.com',
        'name@example',
        'name@exa mple.com',
        'na me@example.com',
        'name@@example.com',
      ]) {
        expect(validateEmail(email), message, reason: email);
      }
    });
  });

  group('validatePasswordConfirmation', () {
    test('accepts the same password', () {
      expect(validatePasswordConfirmation('abc12345', 'abc12345'), isNull);
    });

    test('asks for it when it is empty', () {
      expect(
        validatePasswordConfirmation('', 'abc12345'),
        'Confirm your password',
      );
      expect(
        validatePasswordConfirmation(null, 'abc12345'),
        'Confirm your password',
      );
    });

    test('rejects a different password', () {
      expect(
        validatePasswordConfirmation('abc12346', 'abc12345'),
        "Passwords don't match",
      );
    });

    // A space is part of a password: "abc12345 " is a different password.
    test('does not ignore spaces', () {
      expect(
        validatePasswordConfirmation('abc12345 ', 'abc12345'),
        "Passwords don't match",
      );
    });
  });
}
