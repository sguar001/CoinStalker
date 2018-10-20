import 'dart:async';
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;

part 'coinapi.g.dart';

int _intFromBool(bool x) => x ? 1 : 0;
bool _boolFromInt(int x) => x == 0 ? false : true;

class CoinApi {
  final String _authority = 'rest.coinapi.io';
  final String key;
  Map<String, String> headers;

  CoinApi({this.key}) {
    if (key != null) {
      headers['X-CoinAPI-Key'] = key;
    }
  }

  _apiUri(path, [parameters]) => Uri.https(_authority, path, parameters);
  _endpointPath(endpoint) => 'v1/$endpoint';
  _endpointUri(endpoint, [parameters]) =>
      _apiUri(_endpointPath(endpoint), parameters);
  _getUri(uri) async => http.get(uri, headers: headers);
  _getEndpoint(endpoint, [parameters]) async =>
      _getUri(_endpointUri(endpoint, parameters));

  Future<dynamic> _getJson(endpoint, [parameters]) async {
    final response = await _getEndpoint(endpoint, parameters);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    else {
      throw Exception('Unable to load $endpoint');
    }
  }

  Future<List<Exchange>> listAllExchanges() async =>
    (await _getJson('exchanges') as List)
        .map((x) => Exchange.fromJson(x)).toList();
  Future<List<Asset>> listAllAssets() async =>
    (await _getJson('assets') as List)
        .map((x) => Asset.fromJson(x)).toList();
}

@JsonSerializable()
class Exchange {
  @JsonKey(name: 'exchange_id')
  final String id;
  final String website;
  final String name;

  Exchange({this.id, this.website, this.name});

  factory Exchange.fromJson(Map<String, dynamic> json) =>
      _$ExchangeFromJson(json);
  Map<String, dynamic> toJson() => _$ExchangeToJson(this);
}

@JsonSerializable()
class Asset {
  @JsonKey(name: 'asset_id')
  final String id;
  final String name;
  @JsonKey(
    name: 'type_is_crypto',
    fromJson: _boolFromInt,
    toJson: _intFromBool,
  )
  final bool isCrypto;

  Asset({this.id, this.name, this.isCrypto});

  factory Asset.fromJson(Map<String, dynamic> json) =>
      _$AssetFromJson(json);
  Map<String, dynamic> toJson() => _$AssetToJson(this);
}
