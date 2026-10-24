import 'package:flutter/material.dart';

/// The Profile tab. A placeholder until login and profile arrive in
/// Phases 7 and 8.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Sign in to see your profile.')),
    );
  }
}
