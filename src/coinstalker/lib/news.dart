import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'currency_details.dart';
import 'database.dart';
import 'ohlcv_graph.dart';
import 'price_widget.dart';
import 'session.dart';

class DashboardNews extends StatelessWidget {
  final Session _session = Session();

  @override
  Widget build(BuildContext context) {
    return streamWidget<Profile>(
      stream: Profile.buildStream(_session.profileRef),
      builder: (context, profile) => ListView(
        children: _session.coins
            .where((coin) => profile.trackedSymbols.contains(coin.symbol))
            .map((coin) => _coinTile(context, profile, coin))
            .toList(),
      ),
    );
  }

  Widget _coinTile(BuildContext context, Profile profile, Coin coin) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
    child: Container(
      decoration: BoxDecoration(),
      child: ExpansionTile(
        title: Row(
          children: [
            Text('${coin.name}'),
            Expanded(child: Container()),
            futureWidget(
              future:
              CryptoCompare().price(coin.symbol, profile.displaySymbol),
              waitBuilder: emptyWaitBuilder,
              builder: (context, price) =>
                  priceWidget(profile.displaySymbol, price),
            ),
            futureWidget<double>(
              future: CryptoCompare()
                  .price(coin.symbol, profile.displaySymbol)
                  .then((price) => CryptoCompare()
                  .hourOhlcv(coin.symbol, profile.displaySymbol,
                  limit: 24)
                  .then((data) => data.first.close)
                  .then((close) => (price - close) / close)),
              waitBuilder: emptyWaitBuilder,
              builder: (context, change) {
                final percentage =
                intl.NumberFormat.percentPattern(intl.Intl.systemLocale)
                    .format(change.abs());
                return Text(
                  ' ($percentage)',
                  style: TextStyle(
                      color: change < 0 ? Colors.blue : Colors.green),
                );
              },
            ),
          ],
        ),

      ),
    ),
  );
}
