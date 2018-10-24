import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

part 'cryptocompare.g.dart';

// Based on the API documented at https://min-api.cryptocompare.com/

// CryptoCompare returns some strange JSON at times.  These wrapper functions
// are necessary to get the (de)serialization correct for some calls.

int _ccFromInt(dynamic x) {
  if (x is int) {
    return x;
  }

  final y = x as String;
  return y == "N/A" ? null : int.parse(y);
}

String _ccToInt(int x) => x == null ? "N/A" : x.toString();

List<String> _ccFromTags(String x) => x.split('|');
String _ccToTags(List<String> x) => x.join('|');

List<String> _ccFromList(String x) => x.split(',');
String _ccToList(List<String> x) => x.join(',');

DateTime _ccFromPosixTime(int x) => DateTime.fromMillisecondsSinceEpoch(x);
int _ccToPosixTime(DateTime x) => x.millisecondsSinceEpoch;

enum NewsSortOrder {
  latest,
  popular,
}

class CryptoCompare {
  final String _authority = 'min-api.cryptocompare.com';

  Future<RateLimit> hourRateLimit() async {
    final object = await _fetchJson('stats/rate/hour/limit');
    return RateLimit.fromJson(object);
  }

  Future<RateLimit> minuteRateLimit() async {
    final object = await _fetchJson('stats/rate/minute/limit');
    return RateLimit.fromJson(object);
  }

  Future<RateLimit> secondRateLimit() async {
    final object = await _fetchJson('stats/rate/second/limit');
    return RateLimit.fromJson(object);
  }

  Future<RateLimits> rateLimits() async {
    final object = await _fetchJson('stats/rate/limit');
    return RateLimits.fromJson(object);
  }

  Future<Coins> coins() async {
    final object = await _fetchJson('data/all/coinlist');
    return Coins.fromJson(object);
  }

  Future<News> latestNews(
      {List<String> feeds,
      List<String> categories,
      List<String> excludedCategories,
      String language = 'EN',
      NewsSortOrder sortOrder = NewsSortOrder.latest}) async {
    var params = Map<String, String>();
    if (feeds != null) {
      params['feeds'] = _ccToList(feeds);
      if (params['feeds'].length > 400) {
        throw ArgumentError('feeds length must not exceed 400');
      }
    }

    if (categories != null) {
      params['categories'] = _ccToList(categories);
      if (params['categories'].length > 400) {
        throw ArgumentError('categories length must not exceed 400');
      }
    }

    if (excludedCategories != null) {
      params['excludeCategories'] = _ccToList(excludedCategories);
      if (params['excludeCategories'].length > 400) {
        throw ArgumentError('excludeCategories length must not exceed 400');
      }
    }

    if (language != null) {
      params['lang'] = language.toUpperCase();
      if (params['lang'].length > 4) {
        throw ArgumentError('lang length must not exceed 4');
      }
    }

    if (sortOrder != null) {
      params['sortOrder'] =
          sortOrder.toString().replaceAll('NewsSortOrder.', '');
    }

    final object = await _fetchJson('data/v2/news/', params: params);
    return News.fromJson(object);
  }

  Future<List<NewsFeed>> newsFeeds() async {
    final object = await _fetchJson('data/news/feeds') as List;
    return object.map((x) => NewsFeed.fromJson(x)).toList();
  }

  Future<List<NewsCategory>> newsCategories() async {
    final object = await _fetchJson('data/news/categories') as List;
    return object.map((x) => NewsCategory.fromJson(x)).toList();
  }

  Future<Map<String, Map<String, num>>> priceMulti(
      List<String> fromSymbols, List<String> toSymbols) async {
    final params = <String, String>{
      'fsyms': _ccToList(fromSymbols),
      'tsyms': _ccToList(toSymbols),
    };

    if (params['fsyms'].length > 300) {
      throw ArgumentError('fsyms length must not exceed 300');
    }
    if (params['tsyms'].length > 100) {
      throw ArgumentError('tsyms length must not exceed 100');
    }

    final object = await _fetchJson('data/pricemulti', params: params) as Map;
    return object.map((k, v) => MapEntry(k as String,
        (v as Map).map((k, v) => MapEntry(k as String, v as num))));
  }

  Future<Map<String, num>> prices(
      String fromSymbol, List<String> toSymbols) async {
    final params = <String, String>{
      'fsym': fromSymbol,
      'tsyms': _ccToList(toSymbols),
    };

    if (params['fsym'].length > 10) {
      throw ArgumentError('fsym length must not exceed 10');
    }
    if (params['tsyms'].length > 500) {
      throw ArgumentError('tsyms length must not exceed 500');
    }

    final object = await _fetchJson('data/price', params: params) as Map;
    return object.map((k, v) => MapEntry(k as String, v as num));
  }

  Future<double> price(String fromSymbol, String toSymbol) async =>
      (await prices(fromSymbol, [toSymbol]))[toSymbol];

  Future<List<Ohlcv>> _ohlcv(
      String endpoint, String fromSymbol, String toSymbol,
      {int limit}) async {
    var params = <String, String>{
      'fsym': fromSymbol,
      'tsym': toSymbol,
    };

    if (params['fsym'].length > 10) {
      throw ArgumentError('fsym length must not exceed 10');
    }
    if (params['tsym'].length > 10) {
      throw ArgumentError('tsym length must not exceed 10');
    }

    if (limit != null) {
      params['limit'] = limit.toString();
    }

    final object = await _fetchJson(endpoint, params: params) as Map;
    return (object['Data'] as List).map((x) => Ohlcv.fromJson(x)).toList();
  }

  Future<List<Ohlcv>> minuteOhlcv(String fromSymbol, String toSymbol,
          {int limit}) async =>
      await _ohlcv('data/histominute', fromSymbol, toSymbol, limit: limit);

  Future<List<Ohlcv>> hourOhlcv(String fromSymbol, String toSymbol,
          {int limit}) async =>
      await _ohlcv('data/histohour', fromSymbol, toSymbol, limit: limit);

  Future<List<Ohlcv>> dayOhlcv(String fromSymbol, String toSymbol,
          {int limit}) async =>
      await _ohlcv('data/histoday', fromSymbol, toSymbol, limit: limit);

  Uri _uri(String path, {Map<String, String> params}) =>
      Uri.https(_authority, path, params);
  Future<http.Response> _fetchRaw(String path,
          {Map<String, String> params}) async =>
      http.get(_uri(path, params: params));

  Future<dynamic> _fetchJson(path, {Map<String, String> params}) async {
    final response = await _fetchRaw(path, params: params);
    if (response.statusCode != 200) {
      throw Exception(
          'Unable to load $path: ${response.statusCode} ${response.reasonPhrase}');
    }
    final object = json.decode(response.body);
    if (object is Map<String, dynamic> &&
        object['Response'] != null &&
        object['Response'] != 'Success') {
      throw Exception('Unable to load $path: ${object['Message']}');
    }
    return object;
  }
}

@JsonSerializable()
class Calls {
  @JsonKey(name: 'Histo')
  final int histo;
  @JsonKey(name: 'Price')
  final int price;
  @JsonKey(name: 'News')
  final int news;
  @JsonKey(name: 'Strict')
  final int strict;

  Calls({this.histo, this.price, this.news, this.strict});

  factory Calls.fromJson(Map<String, dynamic> json) => _$CallsFromJson(json);
  Map<String, dynamic> toJson() => _$CallsToJson(this);
}

@JsonSerializable()
class RateLimit {
  @JsonKey(name: 'CallsMade')
  final Calls callsMade;
  @JsonKey(name: 'CallsLeft')
  final Calls callsLeft;

  RateLimit({this.callsMade, this.callsLeft});

  factory RateLimit.fromJson(Map<String, dynamic> json) =>
      _$RateLimitFromJson(json);
  Map<String, dynamic> toJson() => _$RateLimitToJson(this);
}

@JsonSerializable()
class RateLimits {
  @JsonKey(name: 'Hour')
  final RateLimit hour;
  @JsonKey(name: 'Minute')
  final RateLimit minute;
  @JsonKey(name: 'Second')
  final RateLimit second;

  RateLimits({this.hour, this.minute, this.second});

  factory RateLimits.fromJson(Map<String, dynamic> json) =>
      _$RateLimitsFromJson(json);
  Map<String, dynamic> toJson() => _$RateLimitsToJson(this);
}

@JsonSerializable()
class Coin {
  @JsonKey(name: 'Id', fromJson: _ccFromInt, toJson: _ccToInt)
  final int id;
  @JsonKey(name: 'Url')
  final String url;
  @JsonKey(name: 'ImageUrl')
  final String imageUrl;
  @JsonKey(name: 'Name')
  final String name;
  @JsonKey(name: 'Symbol')
  final String symbol;
  @JsonKey(name: 'CoinName')
  final String coinName;
  @JsonKey(name: 'FullName')
  final String fullName;
  @JsonKey(name: 'Algorithm')
  final String algorithm;
  @JsonKey(name: 'ProofType')
  final String proofType;
  @JsonKey(name: 'SortOrder', fromJson: _ccFromInt, toJson: _ccToInt)
  final int sortOrder;

  Coin(
      {this.id,
      this.url,
      this.imageUrl,
      this.name,
      this.symbol,
      this.coinName,
      this.fullName,
      this.algorithm,
      this.proofType,
      this.sortOrder});

  factory Coin.fromJson(Map<String, dynamic> json) => _$CoinFromJson(json);
  Map<String, dynamic> toJson() => _$CoinToJson(this);
}

@JsonSerializable()
class Coins {
  @JsonKey(
    name: 'Data',
    fromJson: _dataFromJson,
    toJson: _dataToJson,
  )
  final List<Coin> data;
  @JsonKey(name: 'BaseImageUrl')
  final String baseImageUrl;
  @JsonKey(name: 'BaseLinkUrl')
  final String baseLinkUrl;

  Coins({this.data, this.baseImageUrl, this.baseLinkUrl});

  factory Coins.fromJson(Map<String, dynamic> json) => _$CoinsFromJson(json);
  Map<String, dynamic> toJson() => _$CoinsToJson(this);

  static List<Coin> _dataFromJson(Map<String, dynamic> object) =>
      object.values.map((x) => Coin.fromJson(x)).toList();
  static Map<String, dynamic> _dataToJson(List<Coin> data) {
    final entries =
        data.map((x) => MapEntry<String, dynamic>(x.symbol, x.toJson()));
    return Map<String, dynamic>.fromEntries(entries);
  }
}

@JsonSerializable()
class NewsArticle {
  @JsonKey(fromJson: _ccFromInt, toJson: _ccToInt)
  final int id;
  final String guid;
  @JsonKey(
      name: 'published_on', fromJson: _ccFromPosixTime, toJson: _ccToPosixTime)
  final DateTime publishedOn;
  @JsonKey(name: 'imageurl')
  final String imageUrl;
  final String title;
  final String url;
  final String source;
  final String body;
  @JsonKey(fromJson: _ccFromTags, toJson: _ccToTags)
  final List<String> tags;
  @JsonKey(fromJson: _ccFromTags, toJson: _ccToTags)
  final List<String> categories;
  @JsonKey(name: 'lang')
  final String language;

  NewsArticle(
      {this.id,
      this.guid,
      this.publishedOn,
      this.imageUrl,
      this.title,
      this.url,
      this.source,
      this.body,
      this.tags,
      this.categories,
      this.language});

  factory NewsArticle.fromJson(Map<String, dynamic> json) =>
      _$NewsArticleFromJson(json);
  Map<String, dynamic> toJson() => _$NewsArticleToJson(this);
}

@JsonSerializable()
class News {
  @JsonKey(
    name: 'Promoted',
    fromJson: _dataFromJson,
    toJson: _dataToJson,
  )
  final List<NewsArticle> promoted;
  @JsonKey(
    name: 'Data',
    fromJson: _dataFromJson,
    toJson: _dataToJson,
  )
  final List<NewsArticle> data;

  News({this.promoted, this.data});

  factory News.fromJson(Map<String, dynamic> json) => _$NewsFromJson(json);
  Map<String, dynamic> toJson() => _$NewsToJson(this);

  static List<NewsArticle> _dataFromJson(List<dynamic> object) =>
      object.map((x) => NewsArticle.fromJson(x)).toList();
  static List<dynamic> _dataToJson(List<NewsArticle> data) =>
      data.map((x) => x.toJson()).toList();
}

@JsonSerializable()
class NewsFeed {
  final String key;
  final String name;
  @JsonKey(name: 'language')
  final String language;
  @JsonKey(name: 'img')
  final String imageUrl;

  NewsFeed({this.key, this.name, this.language, this.imageUrl});

  factory NewsFeed.fromJson(Map<String, dynamic> json) =>
      _$NewsFeedFromJson(json);
  Map<String, dynamic> toJson() => _$NewsFeedToJson(this);
}

@JsonSerializable()
class NewsCategory {
  @JsonKey(name: 'categoryName')
  final String name;
  @JsonKey(name: 'wordsAssociatedWithCategory')
  final List<String> associatedWords;

  NewsCategory({this.name, this.associatedWords});

  factory NewsCategory.fromJson(Map<String, dynamic> json) =>
      _$NewsCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$NewsCategoryToJson(this);
}

@JsonSerializable()
class Ohlcv {
  @JsonKey(fromJson: _ccFromPosixTime, toJson: _ccToPosixTime)
  final DateTime time;
  final num open;
  final num high;
  final num low;
  final num close;
  @JsonKey(name: 'volumefrom')
  final num volumeFrom;
  @JsonKey(name: 'volumeto')
  final num volumeTo;

  Ohlcv(
      {this.time,
      this.open,
      this.high,
      this.low,
      this.close,
      this.volumeFrom,
      this.volumeTo});

  factory Ohlcv.fromJson(Map<String, dynamic> json) => _$OhlcvFromJson(json);
  Map<String, dynamic> toJson() => _$OhlcvToJson(this);
}
