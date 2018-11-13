import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'drawer.dart';
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: FractionallySizedBox(
                  widthFactor: 0.66,
                  child: ListView(
                    children: [
                      // TODO: OLHC graph
                      _buildPropertyRow(
                          name: 'Symbol', value: Text(widget.coin.symbol)),
                      _buildPropertyRow(name: 'Price', value: _buildPrice()),
                      _buildPropertyRow(
                          name: 'Algorithm',
                          value: Text(widget.coin.algorithm)),
                      _buildPropertyRow(
                          name: 'Proof type',
                          value: Text(widget.coin.proofType)),
                    ],
                  ),
                ),
              ),
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

  /// Creates a future builder widget for the current price of the coin
  Widget _buildPrice() => currentPriceWidget(widget.coin.symbol);
}
