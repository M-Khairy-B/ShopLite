import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/core/config/env.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';
import 'package:e_commerce_learn/features/products/data/dummy_json_products_repository.dart';

void main() {
  // The composition root: the one place that decides which real
  // implementations the app runs with. Tests build ShopLiteApp with fakes.
  final apiClient = ApiClient(baseUrl: Env.apiBaseUrl);
  final productsRepository = DummyJsonProductsRepository(apiClient);

  runApp(ShopLiteApp(productsRepository: productsRepository));
}
