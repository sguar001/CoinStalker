import 'dart:async';

import 'cryptocompare.dart';
import 'price.dart';

class PriceCache {
  final _cryptoCompare = CryptoCompare();

  List<List<String>> _symbolGroups = [];
  List<Future<Map<String, Price>>> _groupFutures = [];

  List<String> _allSymbols = [];
  List<String> get allSymbols => _allSymbols;
  set allSymbols(List<String> value) {
    clear();
    _allSymbols = value;
    _symbolGroups = groupSymbols(value).toList();
  }

  String _toSymbol;
  String get toSymbol => _toSymbol;
  set toSymbol(String value) {
    clear();
    _toSymbol = value;
  }

  Map<String, Price> _prices = {};
  Map<String, Price> get prices => _prices;

  static Iterable<List<String>> groupSymbols(List<String> symbols) sync* {
    var i = 0;
    while (i < symbols.length) {
      var group = <String>[];
      var length = 0;
      while (i < symbols.length &&
          length + CryptoCompare.listSeparator.length + symbols[i].length <
              CryptoCompare.maxPriceMultiFromSymbolsLength) {
        group.add(symbols[i]);
        length += CryptoCompare.listSeparator.length + symbols[i].length;
        i++;
      }
      yield group;
    }
  }

  void clear() {
    _groupFutures.clear();
    _prices.clear();
  }

  Future<void> refresh() {
    clear();
    return _symbolGroups.fold(Future.value(<String, Price>{}),
        (Future<Map<String, Price>> future, List<String> group) {
      Future<Map<String, Price>> groupFuture = future.then(
          (_) => _priceGroup(group).then((Map<String, Price> groupPrices) {
                _prices.addAll(groupPrices);
                return groupPrices;
              }));
      _groupFutures.add(groupFuture);
      return groupFuture;
    }).then((_) {});
  }

  Future<Price> priceFor(String symbol) =>
      _groupFutures[_symbolGroups.indexWhere((list) => list.contains(symbol))]
          .then((prices) => prices[symbol]);

  Future<Map<String, Price>> _priceGroup(List<String> group) =>
      _cryptoCompare.priceMulti(group, [_toSymbol]).then(
          (prices) => prices.map((k, v) => MapEntry(k, v.single)));
}
