// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cryptocompare.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Calls _$CallsFromJson(Map<String, dynamic> json) {
  return Calls(
      histo: json['Histo'] as int,
      price: json['Price'] as int,
      news: json['News'] as int,
      strict: json['Strict'] as int);
}

Map<String, dynamic> _$CallsToJson(Calls instance) => <String, dynamic>{
      'Histo': instance.histo,
      'Price': instance.price,
      'News': instance.news,
      'Strict': instance.strict
    };

RateLimit _$RateLimitFromJson(Map<String, dynamic> json) {
  return RateLimit(
      callsMade: json['CallsMade'] == null
          ? null
          : Calls.fromJson(json['CallsMade'] as Map<String, dynamic>),
      callsLeft: json['CallsLeft'] == null
          ? null
          : Calls.fromJson(json['CallsLeft'] as Map<String, dynamic>));
}

Map<String, dynamic> _$RateLimitToJson(RateLimit instance) => <String, dynamic>{
      'CallsMade': instance.callsMade,
      'CallsLeft': instance.callsLeft
    };

RateLimits _$RateLimitsFromJson(Map<String, dynamic> json) {
  return RateLimits(
      hour: json['Hour'] == null
          ? null
          : RateLimit.fromJson(json['Hour'] as Map<String, dynamic>),
      minute: json['Minute'] == null
          ? null
          : RateLimit.fromJson(json['Minute'] as Map<String, dynamic>),
      second: json['Second'] == null
          ? null
          : RateLimit.fromJson(json['Second'] as Map<String, dynamic>));
}

Map<String, dynamic> _$RateLimitsToJson(RateLimits instance) =>
    <String, dynamic>{
      'Hour': instance.hour,
      'Minute': instance.minute,
      'Second': instance.second
    };

Coin _$CoinFromJson(Map<String, dynamic> json) {
  return Coin(
      id: json['Id'] == null ? null : CryptoCompare.toInt(json['Id']),
      url: json['Url'] as String,
      imageUrl: json['ImageUrl'] as String,
      name: json['Name'] as String,
      symbol: json['Symbol'] as String,
      coinName: json['CoinName'] as String,
      fullName: json['FullName'] as String,
      algorithm: json['Algorithm'] as String,
      proofType: json['ProofType'] as String,
      sortOrder: json['SortOrder'] == null
          ? null
          : CryptoCompare.toInt(json['SortOrder']));
}

Map<String, dynamic> _$CoinToJson(Coin instance) => <String, dynamic>{
      'Id': instance.id == null ? null : CryptoCompare.fromInt(instance.id),
      'Url': instance.url,
      'ImageUrl': instance.imageUrl,
      'Name': instance.name,
      'Symbol': instance.symbol,
      'CoinName': instance.coinName,
      'FullName': instance.fullName,
      'Algorithm': instance.algorithm,
      'ProofType': instance.proofType,
      'SortOrder': instance.sortOrder == null
          ? null
          : CryptoCompare.fromInt(instance.sortOrder)
    };

Coins _$CoinsFromJson(Map<String, dynamic> json) {
  return Coins(
      data: json['Data'] == null
          ? null
          : Coins._dataFromJson(json['Data'] as Map<String, dynamic>),
      baseImageUrl: json['BaseImageUrl'] as String,
      baseLinkUrl: json['BaseLinkUrl'] as String);
}

Map<String, dynamic> _$CoinsToJson(Coins instance) => <String, dynamic>{
      'Data': instance.data == null ? null : Coins._dataToJson(instance.data),
      'BaseImageUrl': instance.baseImageUrl,
      'BaseLinkUrl': instance.baseLinkUrl
    };

NewsArticle _$NewsArticleFromJson(Map<String, dynamic> json) {
  return NewsArticle(
      id: json['id'] == null ? null : CryptoCompare.toInt(json['id']),
      guid: json['guid'] as String,
      publishedOn: json['published_on'] == null
          ? null
          : CryptoCompare.fromPosixTime(json['published_on'] as int),
      imageUrl: json['imageurl'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      source: json['source'] as String,
      body: json['body'] as String,
      tags: json['tags'] == null
          ? null
          : CryptoCompare.toTags(json['tags'] as String),
      categories: json['categories'] == null
          ? null
          : CryptoCompare.toTags(json['categories'] as String),
      language: json['lang'] as String);
}

Map<String, dynamic> _$NewsArticleToJson(NewsArticle instance) =>
    <String, dynamic>{
      'id': instance.id == null ? null : CryptoCompare.fromInt(instance.id),
      'guid': instance.guid,
      'published_on': instance.publishedOn == null
          ? null
          : CryptoCompare.toPosixTime(instance.publishedOn),
      'imageurl': instance.imageUrl,
      'title': instance.title,
      'url': instance.url,
      'source': instance.source,
      'body': instance.body,
      'tags':
          instance.tags == null ? null : CryptoCompare.fromTags(instance.tags),
      'categories': instance.categories == null
          ? null
          : CryptoCompare.fromTags(instance.categories),
      'lang': instance.language
    };

News _$NewsFromJson(Map<String, dynamic> json) {
  return News(
      promoted: json['Promoted'] == null
          ? null
          : News._dataFromJson(json['Promoted'] as List),
      data: json['Data'] == null
          ? null
          : News._dataFromJson(json['Data'] as List));
}

Map<String, dynamic> _$NewsToJson(News instance) => <String, dynamic>{
      'Promoted': instance.promoted == null
          ? null
          : News._dataToJson(instance.promoted),
      'Data': instance.data == null ? null : News._dataToJson(instance.data)
    };

NewsFeed _$NewsFeedFromJson(Map<String, dynamic> json) {
  return NewsFeed(
      key: json['key'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      imageUrl: json['img'] as String);
}

Map<String, dynamic> _$NewsFeedToJson(NewsFeed instance) => <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'language': instance.language,
      'img': instance.imageUrl
    };

NewsCategory _$NewsCategoryFromJson(Map<String, dynamic> json) {
  return NewsCategory(
      name: json['categoryName'] as String,
      associatedWords: (json['wordsAssociatedWithCategory'] as List)
          ?.map((e) => e as String)
          ?.toList());
}

Map<String, dynamic> _$NewsCategoryToJson(NewsCategory instance) =>
    <String, dynamic>{
      'categoryName': instance.name,
      'wordsAssociatedWithCategory': instance.associatedWords
    };

Ohlcv _$OhlcvFromJson(Map<String, dynamic> json) {
  return Ohlcv(
      time: json['time'] == null
          ? null
          : CryptoCompare.fromPosixTime(json['time'] as int),
      open: json['open'] as num,
      high: json['high'] as num,
      low: json['low'] as num,
      close: json['close'] as num,
      volumeFrom: json['volumefrom'] as num,
      volumeTo: json['volumeto'] as num);
}

Map<String, dynamic> _$OhlcvToJson(Ohlcv instance) => <String, dynamic>{
      'time': instance.time == null
          ? null
          : CryptoCompare.toPosixTime(instance.time),
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'close': instance.close,
      'volumefrom': instance.volumeFrom,
      'volumeto': instance.volumeTo
    };
