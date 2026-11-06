import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';

/// The Profile tab: the way to the wishlist, and a placeholder for login
/// and the profile itself, until Phases 7 and 8.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Wishlist'),
            trailing: const Icon(Icons.chevron_right),
            // `go`, not `push`: '/profile/wishlist' is under '/profile', so
            // go_router still puts this screen below it, and back works.
            onTap: () => context.go('/profile/wishlist'),
          ),
          const Divider(height: 1),
          // Expanded: EmptyView centers itself in the space that is left.
          const Expanded(
            child: EmptyView(
              icon: Icons.person_outline,
              title: "You're not signed in",
              message: 'Sign in to see your profile and orders.',
            ),
          ),
        ],
      ),
    );
  }
}
