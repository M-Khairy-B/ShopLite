// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCategory _$ProductCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProductCategory', json, ($checkedConvert) {
      final val = ProductCategory(
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });
