import 'package:flutter/material.dart';

/// A centered progress indicator, shown while data is on its way.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      // Screen readers announce "Loading" instead of an unlabeled spinner.
      child: CircularProgressIndicator(semanticsLabel: 'Loading'),
    );
  }
}
