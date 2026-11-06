// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cart _$CartFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Cart', json, ($checkedConvert) {
      final val = Cart(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CartToJson(Cart instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
