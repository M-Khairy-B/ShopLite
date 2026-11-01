// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Product',
  json,
  ($checkedConvert) {
    final val = Product(
      id: $checkedConvert('id', (v) => (v as num).toInt()),
      title: $checkedConvert('title', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String),
      priceCents: $checkedConvert('price', (v) => _centsFromDollars(v as num)),
      rating: $checkedConvert('rating', (v) => (v as num).toDouble()),
      category: $checkedConvert('category', (v) => v as String),
      thumbnailUrl: $checkedConvert('thumbnail', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'priceCents': 'price', 'thumbnailUrl': 'thumbnail'},
);
