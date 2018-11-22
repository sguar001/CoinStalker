import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share/share.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'database.dart';
import 'drawer.dart';
import 'ohlcv_graph.dart';
import 'price_widget.dart';
import 'session.dart';
import 'track_button.dart';
import 'comments.dart';

/// Widget for displaying the details of an individual currency
/// This class is stateful because it must update as the user toggles tracking
class CurrencyDetailsPage extends StatefulWidget {
  /// The coin to display details for
  final Coin coin;

  /// Default Constructor that constructs the widget instance for the specified
  /// coin
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          width: 250.0,
                          child: Comments(coinID: widget.coin.id),
                        )
                      ],
                    )
                  ],
                )
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
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.share),
          onPressed: _shareCoin,
          tooltip: 'Share details about this coin',
        ),
      );

  /// send a message with the name of the currency, its current value, and
  /// a link that opens the Coinstalker app to that currency page.
  void _shareCoin() async {
    var price = '';

    /// Get the current price of the coin, converted to the users default currency preference
    await getCurrentPrice(widget.coin.symbol, exact: true).then((value) {
      price = value;
    });

    /// Get the name of the coin to be shared
    var coinName = widget.coin.coinName;

    /// Dynamic link that will open app or take user to store to download
    Uri dynamicLink;

    /// build the dynamic link for this specific coin (find by id)
    await _buildDynamicURLToCoin(widget.coin.id).then((value) {
      dynamicLink = value;
    });

    /// Message to be shared
    var msg = 'Hey, check out the coin: $coinName.\n'
        'It\'s currently priced at: $price!\n'
        '$dynamicLink';

    Share.share(msg);
  }

  /// Build the dynamic link programmically to find a specific coin, by id
  Future<Uri> _buildDynamicURLToCoin(int coinID) async {
    final DynamicLinkParameters parameters = new DynamicLinkParameters(
      domain: 'coinstalkerucr.page.link',
      link: Uri.parse('https://example.com/coin/$coinID'),
      androidParameters: new AndroidParameters(
          packageName: 'com.coinstalkerucr.coinstalker', minimumVersion: 1),
      socialMetaTagParameters: new SocialMetaTagParameters(
        title: 'Example of a Dynamic Link',
        description: 'This link works whether app is installed or not!',
      ),
    );

    /// Build the long url given the above parameters
    final Uri dynamicUrl = await parameters.buildUrl();

    /// Shorten the link before returning, making length "short"
    final ShortDynamicLink shortenedLink =
        await DynamicLinkParameters.shortenUrl(
            dynamicUrl,
            DynamicLinkParametersOptions(
                shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short));

    return shortenedLink.shortUrl;
  }

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
