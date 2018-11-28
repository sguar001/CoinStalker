import 'dart:async';

import 'cryptocompare.dart';

class TradingInfoCache {
  final _cryptoCompare = CryptoCompare();

  List<List<String>> _symbolGroups = [];
  List<Future<Map<String, TradingInfo>>> _groupFutures = [];

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

  Map<String, TradingInfo> _infos = {};
  Map<String, TradingInfo> get infos => _infos;

  static Iterable<List<String>> groupSymbols(List<String> symbols) sync* {
    var i = 0;
    while (i < symbols.length) {
      var group = <String>[];
      var length = 0;
      while (i < symbols.length &&
          length + CryptoCompare.listSeparator.length + symbols[i].length <
              CryptoCompare.maxTradingInfoFromSymbolsLength) {
        group.add(symbols[i]);
        length += CryptoCompare.listSeparator.length + symbols[i].length;
        i++;
      }
      yield group;
    }
  }

  void clear() {
    _groupFutures.clear();
    _infos.clear();
  }

  Future<void> refresh() {
    clear();
    return _symbolGroups.fold(Future.value(<String, TradingInfo>{}),
        (Future<Map<String, TradingInfo>> future, List<String> group) {
      Future<Map<String, TradingInfo>> groupFuture = future.then(
          (_) => _fetchGroup(group).then((Map<String, TradingInfo> groupInfos) {
                _infos.addAll(groupInfos);
                return groupInfos;
              }));
      _groupFutures.add(groupFuture);
      return groupFuture;
    }).then((_) {});
  }

  Future<TradingInfo> infoFor(String symbol) =>
      _groupFutures[_symbolGroups.indexWhere((list) => list.contains(symbol))]
          .then((infos) => infos[symbol]);

  Future<Map<String, TradingInfo>> _fetchGroup(List<String> group) =>
      _cryptoCompare.tradingInfo(group, [_toSymbol]).then(
          (infos) => infos.map((k, v) => MapEntry(k, v[_toSymbol])));
}
