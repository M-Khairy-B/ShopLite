import 'package:flutter/material.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';

/// The Profile tab. A placeholder until login and profile arrive in
/// Phases 7 and 8.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const EmptyView(
        icon: Icons.person_outline,
        title: "You're not signed in",
        message: 'Sign in to see your profile and orders.',
      ),
    );
  }
}
