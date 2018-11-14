import 'dart:async';

import 'package:flutter/material.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'currency_details.dart';
import 'database.dart';
import 'drawer.dart';
import 'price_widget.dart';
import 'session.dart';
import 'track_button.dart';

/// Represents the price of a coin at a particular time
class _CoinPrice {
  /// The symbol in which the quote price was obtained
  String quoteSymbol;

  /// The quote price of the coin
  num quotePrice;

  /// Constructs this instance
  _CoinPrice(this.quoteSymbol, this.quotePrice);
}

/// Type of the delegate function called when a coin is pressed
typedef void CoinPressedDelegate(Coin coin);

/// Widget for displaying, searching, and sorting the list of currencies
/// This class is stateful because it must update as the user searches and sorts
class CurrencyListPage extends StatefulWidget {
  /// Function to call when a coin is pressed
  final CoinPressedDelegate onCoinPressed;

  /// Whether the page should display as a dialog instead of a full page
  /// When used as a dialog, there will be no drawer in the app bar
  final bool asDialog;

  /// Constructs this instance
  CurrencyListPage({this.onCoinPressed, this.asDialog = false});

  /// Creates the mutable state for this widget
  @override
  createState() => _CurrencyListPageState();
}

/// Possible states for the app bar to occupy
enum _AppBarState {
  /// Initial state, displaying the search and sort buttons
  initial,

  /// Search state, displaying a text field for entering a search filter
  search,
}

/// State for the currency list page
class _CurrencyListPageState extends State<CurrencyListPage> {
  /// Instance of the application session
  final _session = Session();

  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Current state of the app bar
  /// The app bar serves multiple purposes and changes state when the user
  /// presses the search button or the cancel search button
  var _appBarState = _AppBarState.initial;

  /// Controls the search bar text label
  final _searchFilter = TextEditingController();

  /// The current subscription to the profile for refreshing
  StreamSubscription<Profile> _refreshSubscription;

  /// The future for the list of coins
  Future<Map<Coin, _CoinPrice>> _coins;

  /// Called when this object is inserted into the tree
  /// Requests the list of coins and installs a listener on the search filter
  @override
  void initState() {
    super.initState();

    _refreshCoins();

    // Whenever the search filter is modified, force a rebuild of the widget
    _searchFilter.addListener(() => setState(() {}));
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          body: TabBarView(
            children: [
              _buildAllCoins(),
              _buildTrackedCoins(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.sort),
            onPressed: _sortPressed,
          ),
          appBar: AppBar(
            centerTitle: true,
            title: _buildAppBarTitle(),
            actions: _buildAppBarActions(),
            bottom: TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Tracked'),
              ],
            ),
          ),
          drawer: widget.asDialog ? null : UserDrawer(),
        ),
      );

  /// Creates a title widget for the app bar appropriate for its state
  Widget _buildAppBarTitle() {
    switch (_appBarState) {
      case _AppBarState.initial:
        return _initialAppBarTitle();
      case _AppBarState.search:
        return _searchAppBarTitle();
      default:
        return null;
    }
  }

  /// Creates a title widget for the app bar in its initial state
  Widget _initialAppBarTitle() => Text('Currencies');

  /// Creates a title widget for the app bar in its search state
  Widget _searchAppBarTitle() => TextField(
        controller: _searchFilter,
        decoration: InputDecoration(
          // TODO: Make the underline white
          // This might be better accomplished with a theme
          prefixIcon: Icon(Icons.search, color: Colors.white),
          hintText: 'Search...',
          hintStyle: TextStyle(
            color: Colors.white,
          ),
        ),
        style: TextStyle(
          color: Colors.white,
        ),
      );

  /// Creates an actions list for the app bar appropriate for its state
  List<Widget> _buildAppBarActions() {
    switch (_appBarState) {
      case _AppBarState.initial:
        return _initialAppBarActions();
      case _AppBarState.search:
        return _searchAppBarActions();
      default:
        return null;
    }
  }

  /// Creates an actions list for the app bar in its initial state
  List<Widget> _initialAppBarActions() => [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: _searchPressed,
        ),
      ];

  /// Creates an actions list for the app bar in its search state
  List<Widget> _searchAppBarActions() => [
        IconButton(
          icon: Icon(Icons.close),
          onPressed: _closeSearchPressed,
        ),
      ];

  /// Called when the search button is pressed
  /// Changes the state of the app bar to its search state
  void _searchPressed() {
    setState(() {
      _appBarState = _AppBarState.search;
    });
  }

  /// Called when the close search button is pressed
  /// Changes the state of the app bar to its initial state and clears the
  /// search filter
  void _closeSearchPressed() {
    setState(() {
      _appBarState = _AppBarState.initial;
      _searchFilter.clear();
    });
  }

  /// Called when the sort button is pressed
  void _sortPressed() {
    // TODO
  }

  /// Creates a list tile widget for an individual coin
  Widget _buildCoinRow(MapEntry<Coin, _CoinPrice> entry) {
    var children = <Widget>[];

    if (entry.value != null) {
      children.add(Flexible(
          child: priceWidget(entry.value.quoteSymbol, entry.value.quotePrice)));
    }

    children
        .add(Flexible(child: buildTrackButton(entry.key, _session.profileRef)));

    return ListTile(
      title: Text(entry.key.fullName),
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
      onTap: () => (widget.onCoinPressed ?? _goToDetails)(entry.key),
    );
  }

  /// Navigates to the details page for the given coin
  void _goToDetails(Coin coin) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => CurrencyDetailsPage(coin: coin)));
  }

  /// Filters a list of coins to only include coins whose names contain the
  /// search filter text
  List<MapEntry<Coin, _CoinPrice>> _filterCoins(
      List<MapEntry<Coin, _CoinPrice>> allCoins) {
    final pattern = _searchFilter.text.toLowerCase();
    final filter = (MapEntry<Coin, _CoinPrice> entry) =>
        entry.key.fullName.toLowerCase().contains(pattern);
    return allCoins.where(filter).toList();
  }

  /// Create a list view widget for a list of coins
  /// If the search filter is not empty, only matching coins are included
  Widget _buildCoinsListView(List<Coin> allCoins) => futureWidget(
      future: _coins?.then((m) => m.entries.toList()),
      builder: (context, List<MapEntry<Coin, _CoinPrice>> allEntries) {
        final entries =
            allEntries.where((entry) => allCoins.contains(entry.key)).toList();
        final coins = _appBarState == _AppBarState.search
            ? _filterCoins(entries)
            : entries;
        return RefreshIndicator(
          onRefresh: _refreshCoins,
          child: ListView.builder(
            itemCount: coins.length,
            itemBuilder: (context, index) => _buildCoinRow(coins[index]),
          ),
        );
      });

  /// Creates a stream builder widget for a list of coins
  /// While the list is being retrieved, a progress indicator is displayed
  Widget _buildStreamCoins(Stream<List<Coin>> stream) => streamWidget(
        stream: stream,
        builder: (context, data) => _buildCoinsListView(data),
      );

  /// Creates a widget for the list of tracked coins
  Widget _buildTrackedCoins() => _buildStreamCoins(_trackedCoins());

  /// Creates a widget for the list of coins
  Widget _buildAllCoins() => _buildCoinsListView(_session.coins);

  /// Builds a stream of the user's tracked coins
  Stream<List<Coin>> _trackedCoins() =>
      Profile.buildStream(_session.profileRef).map((profile) => _session.coins
          .where((coin) => profile.trackedSymbols.contains(coin.symbol))
          .toList());

  /// Refreshes the list of coin prices
  Future<void> _refreshCoins() async {
    _refreshSubscription?.cancel();
    _refreshSubscription =
        Profile.buildStream(_session.profileRef).listen((profile) {
      var futures = <Future<List<MapEntry<Coin, _CoinPrice>>>>[];
      var remainingCoins = List<Coin>.from(_session.coins);
      while (remainingCoins.isNotEmpty) {
        var batchCoins = <Coin>[];
        var batchSymbols = '';
        while (remainingCoins.isNotEmpty &&
            CryptoCompare.appendList(batchSymbols, remainingCoins.first.symbol)
                    .length <
                CryptoCompare.maxPriceMultiFromSymbolsLength) {
          batchSymbols = CryptoCompare.appendList(
              batchSymbols, remainingCoins.first.symbol);
          batchCoins.add(remainingCoins.first);
          remainingCoins.removeAt(0);
        }

        futures.add(_cryptoCompare.priceMulti(
            batchCoins.map((coin) => coin.symbol).toList(), [
          profile.displaySymbol
        ]).then((prices) => prices.entries
            .map((e) => MapEntry<Coin, _CoinPrice>(
                batchCoins.singleWhere((coin) => coin.symbol == e.key),
                _CoinPrice(
                    profile.displaySymbol, e.value[profile.displaySymbol])))
            .toList()));
      }

      setState(() {
        _coins = Future.wait(futures).then((lists) =>
            Map<Coin, _CoinPrice>.fromEntries(lists
                .fold<List<MapEntry<Coin, _CoinPrice>>>([], (a, x) => a + x)));
      });
    });
    return Future.value();
  }
}
