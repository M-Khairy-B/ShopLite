// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductsPage _$ProductsPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductsPage', json, ($checkedConvert) {
      final val = ProductsPage(
        products: $checkedConvert(
          'products',
          (v) => (v as List<dynamic>)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        total: $checkedConvert('total', (v) => (v as num).toInt()),
        skip: $checkedConvert('skip', (v) => (v as num).toInt()),
        limit: $checkedConvert('limit', (v) => (v as num).toInt()),
      );
      return val;
    });
