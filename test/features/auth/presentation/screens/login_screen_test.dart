import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/auth/presentation/screens/login_screen.dart';

/// Stands in for signing in: remembers every call, and finishes only when
/// the test says so, with [succeed] or [fail].
class _FakeSignIn {
  final calls = <(String, String)>[];
  final _pending = <Completer<void>>[];

  Future<void> call(String username, String password) {
    calls.add((username, password));
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void succeed() => _pending.removeAt(0).complete();

  void fail(Object error) => _pending.removeAt(0).completeError(error);
}

final _username = find.widgetWithText(TextFormField, 'Username');
final _password = find.widgetWithText(TextFormField, 'Password');
final _submitButton = find.byType(FilledButton);

Future<_FakeSignIn> _pumpLogin(WidgetTester tester) async {
  final signIn = _FakeSignIn();
  await tester.pumpWidget(
    MaterialApp(home: LoginScreen(onSubmit: signIn.call)),
  );
  return signIn;
}

/// The text field inside a [TextFormField], which holds what's shown.
TextField _textField(WidgetTester tester, Finder field) {
  return tester.widget<TextField>(
    find.descendant(of: field, matching: find.byType(TextField)),
  );
}

bool _hasFocus(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .focusNode
      .hasFocus;
}

Future<void> _fillIn(
  WidgetTester tester, {
  String username = 'emilys',
  String password = 'secret',
}) async {
  await tester.enterText(_username, username);
  await tester.enterText(_password, password);
}

Future<void> _tapSignIn(WidgetTester tester) async {
  await tester.tap(_submitButton);
  await tester.pump();
}

void main() {
  testWidgets('shows a username field, a password field and "Sign in"', (
    tester,
  ) async {
    await _pumpLogin(tester);

    expect(find.widgetWithText(AppBar, 'Sign in'), findsOne);
    expect(_username, findsOne);
    expect(_password, findsOne);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOne);
  });

  group('checking the fields', () {
    testWidgets('empty fields show what is missing, and nothing is sent', (
      tester,
    ) async {
      final signIn = await _pumpLogin(tester);

      await _tapSignIn(tester);

      expect(find.text('Enter your username'), findsOne);
      expect(find.text('Enter your password'), findsOne);
      expect(signIn.calls, isEmpty);
    });

    testWidgets('a username of only spaces is empty', (tester) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester, username: '   ');
      await _tapSignIn(tester);

      expect(find.text('Enter your username'), findsOne);
      expect(signIn.calls, isEmpty);
    });

    // Accounts made before today's rules must still sign in.
    testWidgets('the password only has to be there, not follow new rules', (
      tester,
    ) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester, password: 'abc');
      await _tapSignIn(tester);

      expect(signIn.calls, [('emilys', 'abc')]);
    });

    testWidgets('after a first try, messages follow the typing', (
      tester,
    ) async {
      await _pumpLogin(tester);
      await _tapSignIn(tester);
      expect(find.text('Enter your username'), findsOne);

      await tester.enterText(_username, 'e');
      await tester.pump();

      expect(find.text('Enter your username'), findsNothing);
    });

    testWidgets('before a first try, typing shows no messages', (tester) async {
      await _pumpLogin(tester);

      await tester.enterText(_username, 'e');
      await tester.enterText(_username, '');
      await tester.pump();

      expect(find.text('Enter your username'), findsNothing);
    });
  });

  group('sending', () {
    testWidgets('sends the username trimmed, and the password exactly', (
      tester,
    ) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester, username: '  emilys ', password: ' my pass ');
      await _tapSignIn(tester);

      expect(signIn.calls, [('emilys', ' my pass ')]);
    });

    testWidgets('while waiting: a spinner, and everything is locked', (
      tester,
    ) async {
      await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);

      expect(find.byType(CircularProgressIndicator), findsOne);
      expect(tester.widget<FilledButton>(_submitButton).onPressed, isNull);
      expect(_textField(tester, _username).enabled, isFalse);
      expect(_textField(tester, _password).enabled, isFalse);
    });

    testWidgets('a second tap while waiting sends nothing more', (
      tester,
    ) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);
      await tester.tap(_submitButton, warnIfMissed: false);
      await tester.pump();

      expect(signIn.calls, hasLength(1));
    });

    // The button is disabled only from the next frame: two taps before
    // that both reach the screen.
    testWidgets('two taps in the same frame send once', (tester) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await tester.tap(_submitButton);
      await tester.tap(_submitButton);
      await tester.pump();

      expect(signIn.calls, hasLength(1));
    });

    testWidgets('after signing in, the form is unlocked again', (tester) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);
      signIn.succeed();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<FilledButton>(_submitButton).onPressed, isNotNull);
    });
  });

  group('when signing in fails', () {
    testWidgets('shows the message, and the form can be sent again', (
      tester,
    ) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);
      signIn.fail(const NetworkException());
      await tester.pump();

      expect(find.text(const NetworkException().message), findsOne);
      expect(_textField(tester, _username).enabled, isTrue);

      await _tapSignIn(tester);
      expect(signIn.calls, hasLength(2));
    });

    testWidgets('a new try hides the old message', (tester) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);
      signIn.fail(const NetworkException());
      await tester.pump();
      await _tapSignIn(tester);

      expect(find.text(const NetworkException().message), findsNothing);
    });

    // Only expected failures (AppException) become a message. A bug must
    // still be reported, but must not leave the form locked.
    testWidgets('a bug is not hidden, and the form is unlocked again', (
      tester,
    ) async {
      final signIn = await _pumpLogin(tester);
      await _fillIn(tester);

      // An error nobody catches goes to the zone the tap ran in. In the
      // app, that's where Phase 10's error reporting will see it; here, a
      // zone of our own records it.
      final uncaught = <Object>[];
      await runZonedGuarded(
        () => _tapSignIn(tester),
        (error, _) => uncaught.add(error),
      );
      signIn.fail(StateError('a bug'));
      await tester.pump();

      expect(uncaught, [isStateError]);
      expect(find.text('a bug'), findsNothing);
      expect(tester.widget<FilledButton>(_submitButton).onPressed, isNotNull);
    });

    testWidgets('closing the screen while waiting is fine', (tester) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);
      await tester.pumpWidget(const SizedBox());
      signIn.fail(const NetworkException());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a screen reader announces the message', (tester) async {
      final semantics = tester.ensureSemantics();
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await _tapSignIn(tester);
      signIn.fail(const NetworkException());
      await tester.pump();

      expect(
        tester.getSemantics(find.text(const NetworkException().message)),
        isSemantics(isLiveRegion: true),
      );
      semantics.dispose();
    });
  });

  group('the keyboard', () {
    testWidgets('"next" on the username moves to the password', (tester) async {
      await _pumpLogin(tester);

      await tester.showKeyboard(_username);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(_hasFocus(tester, _password), isTrue);
    });

    testWidgets('"done" on the password signs in', (tester) async {
      final signIn = await _pumpLogin(tester);

      await _fillIn(tester);
      await tester.showKeyboard(_password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(signIn.calls, [('emilys', 'secret')]);
    });

    testWidgets('each field asks for the right keyboard button', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(
        _textField(tester, _username).textInputAction,
        TextInputAction.next,
      );
      expect(
        _textField(tester, _password).textInputAction,
        TextInputAction.done,
      );
    });
  });

  testWidgets('password managers can fill both fields', (tester) async {
    await _pumpLogin(tester);

    expect(
      _textField(tester, _username).autofillHints,
      contains(AutofillHints.username),
    );
    expect(
      _textField(tester, _password).autofillHints,
      contains(AutofillHints.password),
    );
    expect(find.byType(AutofillGroup), findsOne);
  });

  group('show or hide the password', () {
    testWidgets('it is hidden at first', (tester) async {
      await _pumpLogin(tester);

      expect(_textField(tester, _password).obscureText, isTrue);
      expect(find.byTooltip('Show password'), findsOne);
    });

    testWidgets('the button shows it, then hides it again', (tester) async {
      await _pumpLogin(tester);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(_textField(tester, _password).obscureText, isFalse);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(_textField(tester, _password).obscureText, isTrue);
    });
  });

  testWidgets('fits a small phone with the largest text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final signIn = await _pumpLogin(tester);

    await _fillIn(tester);
    await _tapSignIn(tester);
    signIn.fail(const NetworkException());
    await tester.pump();

    // An overflow is reported as an exception: none means everything fits.
    expect(tester.takeException(), isNull);
  });
}
