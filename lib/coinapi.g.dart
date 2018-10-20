// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coinapi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exchange _$ExchangeFromJson(Map<String, dynamic> json) {
  return Exchange(
      id: json['exchange_id'] as String,
      website: json['website'] as String,
      name: json['name'] as String);
}

Map<String, dynamic> _$ExchangeToJson(Exchange instance) => <String, dynamic>{
      'exchange_id': instance.id,
      'website': instance.website,
      'name': instance.name
    };

Asset _$AssetFromJson(Map<String, dynamic> json) {
  return Asset(
      id: json['asset_id'] as String,
      name: json['name'] as String,
      isCrypto: json['type_is_crypto'] == null
          ? null
          : _boolFromInt(json['type_is_crypto'] as int));
}

Map<String, dynamic> _$AssetToJson(Asset instance) => <String, dynamic>{
      'asset_id': instance.id,
      'name': instance.name,
      'type_is_crypto':
          instance.isCrypto == null ? null : _intFromBool(instance.isCrypto)
    };
