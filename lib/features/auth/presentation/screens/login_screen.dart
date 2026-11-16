import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/utils/validators.dart';

/// Signs in: completes when signed in, and throws an [AppException] when
/// not (the same rule as the repositories).
typedef SignIn = Future<void> Function(String username, String password);

/// The sign-in form: username, password and "Sign in".
///
/// What signing in *does* comes from outside, through [onSubmit], so tests
/// can pass a fake that succeeds, fails or waits.
///
/// Waiting and the error message are this screen's own state, in a
/// `StatefulWidget` (Phase 4's rule for local UI state): no other screen
/// needs to know that a sign-in is running.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSubmit});

  final SignIn onSubmit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Owned by this State: created with it, disposed with it.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  var _passwordHidden = true;

  /// After the first try, messages update as the user types. Before it,
  /// they'd shout "Enter your username" at someone who has only just begun.
  var _triedOnce = false;

  /// True while [LoginScreen.onSubmit] is running: the form is locked.
  var _submitting = false;

  /// What went wrong the last time, shown above the button.
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // The button is disabled while signing in, but only from the next
    // frame: a second tap in the same frame would still get here. This
    // flag is set at once. (A second keyboard "done" can't happen: "done"
    // closes the keyboard.)
    if (_submitting) {
      return;
    }
    setState(() {
      _triedOnce = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      // The username without stray spaces; the password exactly as typed.
      await widget.onSubmit(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } on AppException catch (error) {
      // Expected failures only: a bug in our code still shows as a bug.
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      // Also after a bug, so the form isn't locked for good. `mounted`:
      // the screen may have closed while waiting.
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        // Scrollable, so large text or the keyboard can't cause overflow.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            // Not too wide on a tablet.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // Tells password managers these two fields belong together.
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _triedOnce
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        autofillHints: const [AutofillHints.username],
                        autocorrect: false,
                        // "Next" moves to the password field: Flutter does
                        // that by itself for TextInputAction.next.
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            validateRequired(value, 'username'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_submitting,
                        obscureText: _passwordHidden,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _passwordHidden
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: _submitting
                                ? null
                                : () => setState(
                                    () => _passwordHidden = !_passwordHidden,
                                  ),
                            icon: Icon(
                              _passwordHidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        // Only "is it there?": an account made before
                        // today's password rules must still sign in.
                        validator: (value) =>
                            validateRequired(value, 'password'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (error != null) ...[
                        _ErrorMessage(error),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Signing in',
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Why signing in failed, in the error color.
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // A live region: a screen reader reads it out as soon as it appears,
    // without the user having to find it.
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
