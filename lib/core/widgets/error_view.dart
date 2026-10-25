import 'package:flutter/material.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';

/// Shows what went wrong while loading data, with a "Try again" button.
///
/// The icon and title depend on the kind of [error]; the explanation is the
/// error's own user-facing [AppException.message].
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final AppException error;

  /// Called when the user taps "Try again", usually to repeat the request.
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    // Exhaustive: AppException is sealed, so if a new kind of error is ever
    // added, this switch stops compiling until it is handled here.
    final (icon, title) = switch (error) {
      NetworkException() => (Icons.wifi_off, "You're offline"),
      RequestTimeoutException() => (
        Icons.timer_off_outlined,
        'That took too long',
      ),
      NotFoundException() => (Icons.search_off, 'Not found'),
      ServerException() => (Icons.cloud_off_outlined, 'Server problem'),
      UnexpectedResponseException() ||
      UnknownException() => (Icons.error_outline, 'Something went wrong'),
    };

    // Same layout as every empty state, so all "nothing to show" screens
    // look alike.
    return EmptyView(
      icon: icon,
      title: title,
      message: error.message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Try again'),
      ),
    );
  }
}
