// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wishlist _$WishlistFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Wishlist', json, ($checkedConvert) {
      final val = Wishlist(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WishlistToJson(Wishlist instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
