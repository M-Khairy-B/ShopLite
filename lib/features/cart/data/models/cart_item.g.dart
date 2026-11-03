// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CartItem', json, ($checkedConvert) {
      final val = CartItem(
        productId: $checkedConvert('productId', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        thumbnailUrl: $checkedConvert('thumbnailUrl', (v) => v as String),
        unitPriceCents: $checkedConvert(
          'unitPriceCents',
          (v) => (v as num).toInt(),
        ),
        quantity: $checkedConvert('quantity', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'title': instance.title,
  'thumbnailUrl': instance.thumbnailUrl,
  'unitPriceCents': instance.unitPriceCents,
  'quantity': instance.quantity,
};
