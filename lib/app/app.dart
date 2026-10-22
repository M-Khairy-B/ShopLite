import 'package:flutter/material.dart';

class ShopLiteApp extends StatelessWidget {
  const ShopLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopLite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('ShopLite')),
        body: const Center(child: Text('Welcome to ShopLite')),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
