import 'package:flutter/material.dart';

/// The Categories tab. A placeholder until the category list is built.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: const Center(child: Text('Browse products by category.')),
    );
  }
}
