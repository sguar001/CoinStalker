import 'package:flutter/material.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'database.dart';
import 'drawer.dart';
import 'ohlcv_graph.dart';
import 'price_widget.dart';
import 'session.dart';
import 'track_button.dart';

/// Widget for displaying the details of an individual currency
/// This class is stateful because it must update as the user toggles tracking
class CurrencyDetailsPage extends StatefulWidget {
  /// The coin to display details for
  final Coin coin;

  /// Constructs the widget instance
  CurrencyDetailsPage({@required this.coin});

  /// Creates the mutable state for this widget
  @override
  createState() => _CurrencyDetailsPageState();
}

/// State for the currency details page
class _CurrencyDetailsPageState extends State<CurrencyDetailsPage> {
  /// Instance of the application session
  final _session = Session();

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.1,
                child: Image.network(widget.coin.imageUrl),
              ),
            ),
            ListView(
              padding: const EdgeInsets.all(32.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: streamWidget(
                    stream: Profile.buildStream(_session.profileRef)
                        .map((profile) => profile.displaySymbol),
                    builder: (context, displaySymbol) => DefaultTabController(
                          length: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                color: Colors.green,
                                child: TabBar(
                                  tabs: [
                                    Tab(text: '14-Day'),
                                    Tab(text: '24-Hour'),
                                    Tab(text: '30-Minute'),
                                  ],
                                ),
                              ),
                              SizedBox(width: 0.0, height: 8.0),
                              AspectRatio(
                                aspectRatio: 2.0,
                                child: TabBarView(
                                  children: [
                                    futureWidget(
                                      future: CryptoCompare().dayOhlcv(
                                          widget.coin.symbol, displaySymbol),
                                      builder: (context, data) => OhlcvGraph(
                                            priceSymbol: displaySymbol,
                                            data: data,
                                          ),
                                    ),
                                    futureWidget(
                                      future: CryptoCompare().hourOhlcv(
                                          widget.coin.symbol, displaySymbol),
                                      builder: (context, data) => OhlcvGraph(
                                            priceSymbol: displaySymbol,
                                            data: data,
                                          ),
                                    ),
                                    futureWidget(
                                      future: CryptoCompare().minuteOhlcv(
                                          widget.coin.symbol, displaySymbol),
                                      builder: (context, data) => OhlcvGraph(
                                            priceSymbol: displaySymbol,
                                            data: data,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
                _buildPropertyRow(
                    name: 'Symbol', value: Text(widget.coin.symbol)),
                _buildPropertyRow(
                    name: 'Price',
                    value: currentPriceWidget(widget.coin.symbol, exact: true)),
                _buildPropertyRow(
                    name: 'Algorithm', value: Text(widget.coin.algorithm)),
                _buildPropertyRow(
                    name: 'Proof type', value: Text(widget.coin.proofType)),
              ],
            ),
          ],
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.coin.coinName),
          actions: [
            buildTrackButton(widget.coin, _session.profileRef),
          ],
        ),
        drawer: UserDrawer(),
      );

  /// Creates a row for a property of the coin
  Widget _buildPropertyRow({String name, Widget value}) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$name: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            value,
          ],
        ),
      );
}
