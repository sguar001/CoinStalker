import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';

import 'comments.dart';
import 'cryptocompare.dart';
import 'database.dart';
import 'drawer.dart';
import 'either.dart';
import 'ohlcv_graph.dart';
import 'price.dart';
import 'session.dart';
import 'track_button.dart';

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

  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Stream for the user profile
  Stream<Profile> _profileStream;

  /// Current user profile instance
  Profile _profile;

  // Live data
  bool _isLoading = true;
  List<Ohlcv> _ohlcv1Hour;
  List<Ohlcv> _ohlcv1Day;
  List<Ohlcv> _ohlcv1Week;
  Price _price;

  /// For comments text field
  final _commentsController = TextEditingController();

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
    setState(() => _isLoading = true);
    final futures = [
      _cryptoCompare.minuteOhlcv(widget.coin.symbol, _profile.displaySymbol,
          limit: 60),
      _cryptoCompare.minuteOhlcv(widget.coin.symbol, _profile.displaySymbol,
          limit: 6 * 24),
      _cryptoCompare.hourOhlcv(widget.coin.symbol, _profile.displaySymbol,
          limit: 30 * 24),
      _cryptoCompare.price(widget.coin.symbol, _profile.displaySymbol),
    ];
    return Future.wait(futures).then((responses) {
      setState(() {
        _ohlcv1Hour = responses[0];
        _ohlcv1Day = responses[1];
        _ohlcv1Week = responses[2];
        _price = responses[3];
        _isLoading = false;
      });
    });
  }

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
            CircularProgressFallbackBuilder(
              isFallback: _isLoading,
              builder: (context) => RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      padding: const EdgeInsets.all(32.0),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DefaultTabController(
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
                                      Tab(text: '1 Hour'),
                                      Tab(text: '1 Day'),
                                      Tab(text: '1 Week'),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                AspectRatio(
                                  aspectRatio: 2.0,
                                  child: TabBarView(
                                    children: [
                                      _ohlcvWidget(
                                        data: _ohlcv1Hour,
                                        symbol: _profile.displaySymbol,
                                        xAxisInterval: Duration(minutes: 10),
                                        range: '1-hour',
                                      ),
                                      _ohlcvWidget(
                                        data: _ohlcv1Day,
                                        symbol: _profile.displaySymbol,
                                        xAxisInterval: Duration(hours: 3),
                                        range: '1-day',
                                      ),
                                      _ohlcvWidget(
                                        data: _ohlcv1Week,
                                        symbol: _profile.displaySymbol,
                                        xAxisInterval: Duration(days: 1),
                                        range: '1-week',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildPropertyRow(
                            name: 'Symbol', value: Text(widget.coin.symbol)),
                        _buildPropertyRow(
                            name: 'Price',
                            value: Text(_price == null
                                ? 'None'
                                : _price.toString(exact: true))),
                        _buildPropertyRow(
                            name: 'Algorithm',
                            value: Text(widget.coin.algorithm)),
                        _buildPropertyRow(
                            name: 'Proof type',
                            value: Text(widget.coin.proofType)),
                        Row(
                          /// Row that holds the container for list of comments for coin
                          /// Gets comments from Firebase DB for specific coin ID
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  width: 330.0,
                                  height: 300.0,
                                  child: Comments(coinID: widget.coin.id),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          /// Row that holds text field for comment input
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Column(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.only(
                                      top: 16.0, bottom: 16.0),
                                  constraints: BoxConstraints.expand(
                                      width: 300.0, height: 100.0),
                                  child: TextFormField(
                                    controller: _commentsController,
                                    style: TextStyle(
                                        fontSize: 16.0, color: Colors.black),
                                    decoration: InputDecoration(
                                      labelStyle: TextStyle(fontSize: 18.0),
                                      labelText: 'Enter Comment',
                                      border: UnderlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    keyboardType: TextInputType.text,
                                    onEditingComplete: () {
                                      /// add the comment and rebuild widget
                                      setState(() {
                                        Comments.addComment(
                                            _commentsController.text,
                                            widget.coin.id);
                                        _commentsController.clear();
                                      });

                                      /// TODO: fix bug where it only reloads when closing keyboard
                                      /// need to figure out how to reload in addComment, but can't currenlty
                                      /// call setState there cause static void function

                                      /// From services.dart, hides keyboard on submission of comment
//                                      SystemChannels.textInput
//                                          .invokeMethod('TextInput.hide');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.share),
          onPressed: _shareCoin,
          tooltip: 'Share details about this coin',
        ),
      );

  Widget _ohlcvWidget(
      {@required List<Ohlcv> data,
      @required String symbol,
      @required Duration xAxisInterval,
      @required String range}) {
    if (data == null) return Container();
    return FlatButton(
      child: OhlcvGraph(
        data: data,
        symbol: symbol,
        xAxisInterval: xAxisInterval,
      ),
      onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OhlcvPage(
                  title: '$range ${widget.coin.symbol}-$symbol chart',
                  data: data,
                  symbol: symbol,
                  xAxisInterval: xAxisInterval,
                ),
          )),
    );
  }

  /// send a message with the name of the currency, its current value, and
  /// a link that opens the Coinstalker app to that currency page.
  void _shareCoin() async {
    /// Get the current price of the coin, converted to the users default currency preference
    var price = _price == null ? 'None' : _price.toString(exact: true);

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
