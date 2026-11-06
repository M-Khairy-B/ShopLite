// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WishlistItem _$WishlistItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WishlistItem', json, ($checkedConvert) {
      final val = WishlistItem(
        productId: $checkedConvert('productId', (v) => (v as num).toInt()),
        title: $checkedConvert('title', (v) => v as String),
        thumbnailUrl: $checkedConvert('thumbnailUrl', (v) => v as String),
        priceCents: $checkedConvert('priceCents', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$WishlistItemToJson(WishlistItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'title': instance.title,
      'thumbnailUrl': instance.thumbnailUrl,
      'priceCents': instance.priceCents,
    };
