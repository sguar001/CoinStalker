import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

part 'cryptocompare.g.dart';

// Based on the API documented at https://min-api.cryptocompare.com/

enum NewsSortOrder {
  latest,
  popular,
}

class CryptoCompare {
  static const _fiatSymbols = <String>[
    'AED',
    'AFN',
    'ALL',
    'AMD',
    'ANG',
    'AOA',
    'ARS',
    'AUD',
    'AWG',
    'AZN',
    'BAM',
    'BBD',
    'BDT',
    'BGN',
    'BHD',
    'BIF',
    'BMD',
    'BND',
    'BOB',
    'BOV',
    'BRL',
    'BSD',
    'BTN',
    'BWP',
    'BYR',
    'BZD',
    'CAD',
    'CDF',
    'CHE',
    'CHF',
    'CHW',
    'CLF',
    'CLP',
    'CNY',
    'COP',
    'COU',
    'CRC',
    'CUC',
    'CUP',
    'CVE',
    'CZK',
    'DJF',
    'DKK',
    'DOP',
    'DZD',
    'EGP',
    'ERN',
    'ETB',
    'EUR',
    'FJD',
    'FKP',
    'GBP',
    'GEL',
    'GHS',
    'GIP',
    'GMD',
    'GNF',
    'GTQ',
    'GYD',
    'HKD',
    'HNL',
    'HRK',
    'HTG',
    'HUF',
    'IDR',
    'ILS',
    'INR',
    'IQD',
    'IRR',
    'ISK',
    'JMD',
    'JOD',
    'JPY',
    'KES',
    'KGS',
    'KHR',
    'KMF',
    'KPW',
    'KRW',
    'KWD',
    'KYD',
    'KZT',
    'LAK',
    'LBP',
    'LKR',
    'LRD',
    'LSL',
    'LTL',
    'LVL',
    'LYD',
    'MAD',
    'MDL',
    'MGA',
    'MKD',
    'MMK',
    'MNT',
    'MOP',
    'MRO',
    'MUR',
    'MVR',
    'MWK',
    'MXN',
    'MXV',
    'MYR',
    'MZN',
    'NAD',
    'NGN',
    'NIO',
    'NOK',
    'NPR',
    'NZD',
    'OMR',
    'PAB',
    'PEN',
    'PGK',
    'PHP',
    'PKR',
    'PLN',
    'PYG',
    'QAR',
    'RON',
    'RSD',
    'RUB',
    'RWF',
    'SAR',
    'SBD',
    'SCR',
    'SDG',
    'SEK',
    'SGD',
    'SHP',
    'SLL',
    'SOS',
    'SRD',
    'SSP',
    'STD',
    'SVC',
    'SYP',
    'SZL',
    'THB',
    'TJS',
    'TMT',
    'TND',
    'TOP',
    'TRY',
    'TTD',
    'TWD',
    'TZS',
    'UAH',
    'UGX',
    'USD',
    'USN',
    'USS',
    'UYI',
    'UYU',
    'UZS',
    'VEF',
    'VND',
    'VUV',
    'WST',
    'XAF',
    'XAG',
    'XAU',
    'XBA',
    'XBB',
    'XBC',
    'XBD',
    'XCD',
    'XDR',
    'XFU',
    'XOF',
    'XPD',
    'XPF',
    'XPT',
    'XSU',
    'XTS',
    'XUA',
    'XXX',
    'YER',
    'ZAR',
    'ZMW',
    'ZWL',
  ];

  static const _authority = 'min-api.cryptocompare.com';

  static const maxLatestNewsFeedsLength = 400;
  static const maxLatestNewsCategoriesLength = 400;
  static const maxLatestNewsExcludedCategoriesLength = 400;
  static const maxLatestNewsLanguageLength = 4;
  static const maxPriceMultiFromSymbolsLength = 300;
  static const maxPriceMultiToSymbolsLength = 100;
  static const maxPricesFromSymbolLength = 10;
  static const maxPricesToSymbolsLength = 500;
  static const maxOhlcvFromSymbolLength = 10;
  static const maxOhlcvToSymbolLength = 10;

  // CryptoCompare returns some strange JSON at times.  These wrapper functions
  // are necessary to get the (de)serialization correct for some calls.

  static int toInt(dynamic x) {
    if (x is int) return x;
    final y = x as String;
    return y == "N/A" ? null : int.parse(y);
  }

  static String fromInt(int x) => x == null ? "N/A" : x.toString();

  static const tagSeparator = '|';
  static List<String> toTags(String x) => x.split(tagSeparator);
  static String fromTags(List<String> x) => x.join(tagSeparator);
  static String appendTag(String tags, String x) =>
      tags.isEmpty ? x : (tags + tagSeparator + x);

  static const listSeparator = ',';
  static List<String> toList(String x) => x.split(listSeparator);
  static String fromList(List<String> x) => x.join(listSeparator);
  static String appendList(String list, String x) =>
      list.isEmpty ? x : (list + listSeparator + x);

  static DateTime fromPosixTime(int x) =>
      DateTime.fromMillisecondsSinceEpoch(x);
  static int toPosixTime(DateTime x) => x.millisecondsSinceEpoch;

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

  Future<Map<String, Map<String, List<String>>>> exchangePairs() async =>
      (await _fetchJson('data/all/exchanges') as Map).cast<String, Map>().map(
          (k, v) => MapEntry(
              k,
              v
                  .cast<String, List>()
                  .map((k, v) => MapEntry(k, v.cast<String>()))));

  Future<Set<String>> fiatSymbols() async => (await exchangePairs())
      .values
      .map((m) => m.keys.toSet().union(m.values
          .map((x) => x.toSet())
          .fold(Set<String>(), (x, y) => x.union(y))))
      .fold(Set<String>(), (x, y) => x.union(y))
      .intersection(_fiatSymbols.toSet());

  Future<News> latestNews(
      {List<String> feeds,
      List<String> categories,
      List<String> excludedCategories,
      String language = 'EN',
      NewsSortOrder sortOrder = NewsSortOrder.latest}) async {
    var params = Map<String, String>();
    if (feeds != null) {
      params['feeds'] = fromList(feeds);
      if (params['feeds'].length > maxLatestNewsFeedsLength) {
        throw ArgumentError(
            'feeds length must not exceed $maxLatestNewsFeedsLength');
      }
    }

    if (categories != null) {
      params['categories'] = fromList(categories);
      if (params['categories'].length > maxLatestNewsCategoriesLength) {
        throw ArgumentError(
            'categories length must not exceed $maxLatestNewsCategoriesLength');
      }
    }

    if (excludedCategories != null) {
      params['excludeCategories'] = fromList(excludedCategories);
      if (params['excludeCategories'].length >
          maxLatestNewsExcludedCategoriesLength) {
        throw ArgumentError(
            'excludeCategories length must not exceed $maxLatestNewsExcludedCategoriesLength');
      }
    }

    if (language != null) {
      params['lang'] = language.toUpperCase();
      if (params['lang'].length > maxLatestNewsLanguageLength) {
        throw ArgumentError(
            'lang length must not exceed $maxLatestNewsLanguageLength');
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
      'fsyms': fromList(fromSymbols),
      'tsyms': fromList(toSymbols),
    };

    if (params['fsyms'].length > maxPriceMultiFromSymbolsLength) {
      throw ArgumentError(
          'fsyms length must not exceed $maxPriceMultiFromSymbolsLength');
    }
    if (params['tsyms'].length > maxPriceMultiToSymbolsLength) {
      throw ArgumentError(
          'tsyms length must not exceed $maxPriceMultiToSymbolsLength');
    }

    final object = await _fetchJson('data/pricemulti', params: params) as Map;
    return object.map((k, v) => MapEntry(k as String,
        (v as Map).map((k, v) => MapEntry(k as String, v as num))));
  }

  Future<Map<String, num>> prices(
      String fromSymbol, List<String> toSymbols) async {
    final params = <String, String>{
      'fsym': fromSymbol,
      'tsyms': fromList(toSymbols),
    };

    if (params['fsym'].length > maxPricesFromSymbolLength) {
      throw ArgumentError(
          'fsym length must not exceed $maxPricesFromSymbolLength');
    }
    if (params['tsyms'].length > maxPricesToSymbolsLength) {
      throw ArgumentError(
          'tsyms length must not exceed $maxPricesToSymbolsLength');
    }

    final object = await _fetchJson('data/price', params: params) as Map;
    return object.map((k, v) => MapEntry(k as String, v as num));
  }

  Future<num> price(String fromSymbol, String toSymbol) async =>
      (await prices(fromSymbol, [toSymbol]))[toSymbol];

  Future<List<Ohlcv>> _ohlcv(
      String endpoint, String fromSymbol, String toSymbol,
      {int limit}) async {
    var params = <String, String>{
      'fsym': fromSymbol,
      'tsym': toSymbol,
    };

    if (params['fsym'].length > maxOhlcvFromSymbolLength) {
      throw ArgumentError(
          'fsym length must not exceed $maxOhlcvFromSymbolLength');
    }
    if (params['tsym'].length > maxOhlcvToSymbolLength) {
      throw ArgumentError(
          'tsym length must not exceed $maxOhlcvToSymbolLength');
    }

    if (limit != null) {
      params['limit'] = limit.toString();
    }

    final object = await _fetchJson(endpoint, params: params) as Map;
    return (object['Data'] as List).map((x) => Ohlcv.fromJson(x)).toList();
  }

  Future<List<Ohlcv>> minuteOhlcv(String fromSymbol, String toSymbol,
          {int limit = 30}) async =>
      await _ohlcv('data/histominute', fromSymbol, toSymbol, limit: limit);

  Future<List<Ohlcv>> hourOhlcv(String fromSymbol, String toSymbol,
          {int limit = 24}) async =>
      await _ohlcv('data/histohour', fromSymbol, toSymbol, limit: limit);

  Future<List<Ohlcv>> dayOhlcv(String fromSymbol, String toSymbol,
          {int limit = 14}) async =>
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
  @JsonKey(
      name: 'Id', fromJson: CryptoCompare.toInt, toJson: CryptoCompare.fromInt)
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
  @JsonKey(
      name: 'SortOrder',
      fromJson: CryptoCompare.toInt,
      toJson: CryptoCompare.fromInt)
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

  List<Coin> complete() => data
      .map((x) => Coin(
            id: x.id,
            url: '$baseLinkUrl${x.url}',
            imageUrl: '$baseImageUrl${x.imageUrl}',
            name: x.name,
            symbol: x.symbol,
            coinName: x.coinName,
            fullName: x.fullName,
            algorithm: x.algorithm,
            proofType: x.proofType,
            sortOrder: x.sortOrder,
          ))
      .toList();

  static List<Coin> _dataFromJson(Map<String, dynamic> object) => object.values
      .cast<Map<String, dynamic>>()
      .where((x) => x['IsTrading'] == true)
      .map((x) => Coin.fromJson(x))
      .toList();
  static Map<String, dynamic> _dataToJson(List<Coin> data) {
    final entries =
        data.map((x) => MapEntry<String, dynamic>(x.symbol, x.toJson()));
    return Map<String, dynamic>.fromEntries(entries);
  }
}

@JsonSerializable()
class NewsArticle {
  @JsonKey(fromJson: CryptoCompare.toInt, toJson: CryptoCompare.fromInt)
  final int id;
  final String guid;
  @JsonKey(
      name: 'published_on',
      fromJson: CryptoCompare.fromPosixTime,
      toJson: CryptoCompare.toPosixTime)
  final DateTime publishedOn;
  @JsonKey(name: 'imageurl')
  final String imageUrl;
  final String title;
  final String url;
  final String source;
  final String body;
  @JsonKey(fromJson: CryptoCompare.toTags, toJson: CryptoCompare.fromTags)
  final List<String> tags;
  @JsonKey(fromJson: CryptoCompare.toTags, toJson: CryptoCompare.fromTags)
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
  @JsonKey(
      fromJson: CryptoCompare.fromPosixTime, toJson: CryptoCompare.toPosixTime)
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
