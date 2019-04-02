import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'currency_details.dart';
import 'database.dart';
import 'either.dart';
import 'ohlcv_graph.dart';
import 'session.dart';
import 'trading_info_cache.dart';

/// Widget for displaying the list of tracked coins in the dashboard
/// This class is stateful because it caches live information
class DashboardCoins extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _DashboardCoinsState();
}

/// State for the dashboard coins widget
class _DashboardCoinsState extends State<DashboardCoins> {
  /// Instance of the application session
  final _session = Session();

  /// Stream for the user profile
  Stream<Profile> _profileStream;

  /// Most recent user profile
  Profile _profile;

  /// Cache of fetched trading information
  var _tradingInfoCache = TradingInfoCache();

  // Live data
  bool _isLoading = true;

  /// Initializes the widget state
  @override
  void initState() {
    super.initState();

    _profileStream = Profile.buildStream(_session.profileRef);
    _profileStream.listen((profile) {
      if (profile == _profile) return;
      setState(() {
        _profile = profile;
        refresh();
      });
    });
  }

  /// Refreshes the live data
  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
      _tradingInfoCache.allSymbols = _profile.trackedSymbols;
      _tradingInfoCache.toSymbol = _profile.displaySymbol;
    });
    final futures = <Future>[
      _tradingInfoCache.refresh(),
    ];
    return Future.wait(futures).then((responses) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => CircularProgressFallbackBuilder(
        isFallback: _isLoading,
        builder: (context) {
          final trackedCoins = _session.coins
              .where((coin) => _profile.trackedSymbols.contains(coin.symbol))
              .toList();
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: _profile.trackedSymbols.length,
              itemBuilder: (context, index) => DashboardCoinTile(
                  tradingInfoCache: _tradingInfoCache,
                  coin: trackedCoins.singleWhere(
                      (coin) => _profile.trackedSymbols[index] == coin.symbol)),
            ),
          );
        },
      );
}

class DashboardCoinTile extends StatefulWidget {
  final TradingInfoCache tradingInfoCache;
  final Coin coin;

  TradingInfo get tradingInfo => tradingInfoCache.infos[coin.symbol];

  DashboardCoinTile({@required this.tradingInfoCache, @required this.coin});

  @override
  createState() => _DashboardCoinTileState();
}

class _DashboardCoinTileState extends State<DashboardCoinTile> {
  static const bool isInitiallyExpanded = false;
  bool isExpanded = isInitiallyExpanded;
  List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final changePct = widget.tradingInfo.changePct24Hour / 100.0;
    final changePctString =
        intl.NumberFormat.percentPattern(intl.Intl.systemLocale)
            .format(changePct.abs());
    Color changePctColor;
    IconData changePctIcon;
    if (changePct < 0) {
      changePctColor = Colors.red;
      changePctIcon = Icons.trending_down;
    } else if (changePct > 0) {
      changePctColor = Colors.green;
      changePctIcon = Icons.trending_up;
    } else {
      changePctColor = Colors.yellow[700];
      changePctIcon = Icons.trending_flat;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(),
        child: ExpansionTile(
          title: Row(
            children: [
              Text('${widget.coin.name}'),
              Expanded(child: Container()),
              Text('${widget.tradingInfo.price}'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(changePctIcon, color: changePctColor),
              ),
              Text(
                '$changePctString',
                style: TextStyle(color: changePctColor),
              ),
            ],
          ),
          children: children,
          initiallyExpanded: isInitiallyExpanded,
          onExpansionChanged: (value) => onExpansionChanged(value),
        ),
      ),
    );
  }

  void onExpansionChanged(bool value) {
    isExpanded = value;
    if (isExpanded && children == null) {
      setState(() {
        children = [
          ListTile(
            title: Center(child: Text('1-hour overview')),
            subtitle: futureWidget(
              future: CryptoCompare().minuteOhlcv(
                  widget.coin.symbol, widget.tradingInfo.toSymbol,
                  limit: 60),
              builder: (context, data) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: 2.0,
                      child: OhlcvGraph(
                        data: data,
                        symbol: widget.tradingInfo.toSymbol,
                        xAxisInterval: Duration(minutes: 10),
                      ),
                    ),
                  ),
            ),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CurrencyDetailsPage(coin: widget.coin))),
          ),
        ];
      });
    }
  }
}
