import 'dart:async';

import 'package:flutter/material.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'currency_details.dart';
import 'database.dart';
import 'drawer.dart';
import 'either.dart';
import 'price.dart';
import 'price_cache.dart';
import 'session.dart';
import 'sort.dart';
import 'track_button.dart';

/// Type of the delegate function called when a coin is pressed
typedef void CoinPressedDelegate(Coin coin);

/// Type of the delegate function called when a fiat symbol is pressed
typedef void FiatPressedDelegate(String symbol);

/// Widget for displaying, searching, and sorting the list of currencies
/// This class is stateful because it must update as the user searches and sorts
class CurrencyListPage extends StatefulWidget {
  /// Function to call when a coin is pressed
  final CoinPressedDelegate onCoinPressed;

  /// Function to call when a fiat symbol is pressed
  final FiatPressedDelegate onFiatPressed;

  /// Whether the page should display as a dialog instead of a full page
  /// When used as a dialog, there will be no drawer in the app bar
  final bool asDialog;

  /// Whether the page should display as a tabbed view (coins/tracked)
  /// or as fiat symbols
  final bool asTabView;

  /// Constructs this instance
  CurrencyListPage(
      {this.onCoinPressed,
      this.onFiatPressed,
      this.asDialog = false,
      this.asTabView = true});

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
  /// Initial sorting for the coins list
  static final _initialSort = Sort<MapEntry<Coin, Price>>(
    [
      SortProperty('Symbol', (x, y) => x.key.symbol.compareTo(y.key.symbol),
          order: SortOrder.ascending),
      SortProperty('Name', (x, y) => x.key.fullName.compareTo(y.key.fullName)),
      SortProperty('Price', (x, y) {
        if (x.value == null) return -1;
        if (y.value == null) return 1;
        return x.value.price.compareTo(y.value.price);
      }),
    ],
  );

  /// Instance of the application session
  final _session = Session();

  /// Stream for the user profile
  Stream<Profile> _profileStream;

  /// Most recent user profile
  Profile _profile;

  /// Cache of fetched prices
  var _priceCache = PriceCache();

  // Live data
  bool _isLoading = true;
  bool _isComplete = false;

  /// Current state of the app bar
  /// The app bar serves multiple purposes and changes state when the user
  /// presses the search button or the cancel search button
  var _appBarState = _AppBarState.initial;

  /// Controls the search bar text label
  final _searchFilter = TextEditingController();

  /// Sorting to apply to the coin list
  var _sort = Sort<MapEntry<Coin, Price>>.from(_initialSort);

  /// Called when this object is inserted into the tree
  /// Requests the list of coins and installs a listener on the search filter
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

    // Whenever the search filter is modified, force a rebuild of the widget
    _searchFilter.addListener(() => setState(() {}));
  }

  /// Refreshes the live data
  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
      _isComplete = false;
      _priceCache.allSymbols =
          _session.coins.map((coin) => coin.symbol).toList();
      _priceCache.toSymbol = _profile.displaySymbol;
    });
    _priceCache.refresh().then((_) {
      setState(() {
        _isComplete = true;
      });
    });
    setState(() {
      _isLoading = false;
    });
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) {
    if (widget.asTabView) {
      return DefaultTabController(
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
    }

    return Scaffold(
      body: _buildFiatSymbolsList(),
      appBar: AppBar(
        centerTitle: true,
        title: _buildAppBarTitle(),
        actions: _buildAppBarActions(),
      ),
      drawer: widget.asDialog ? null : UserDrawer(),
    );
  }

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
  void _sortPressed() async {
    final sort = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SortDialog(
                  title: 'Sort currencies',
                  initialSort: _initialSort,
                  sort: _sort,
                )));
    if (sort != null) setState(() => _sort = sort);
  }

  /// Creates a list tile widget for an individual coin
  Widget _buildCoinRow(Coin coin, Future<Price> priceFuture) => ListTile(
        title: Text(coin.fullName),
        trailing: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: futureWidget(
                future: priceFuture,
                waitBuilder: (context) => Container(width: 0.0, height: 0.0),
                builder: (context, price) => Text('$price'),
              ),
            ),
            Flexible(child: buildTrackButton(coin, _session.profileRef)),
          ],
        ),
        onTap: () => (widget.onCoinPressed ?? _goToDetails)(coin),
      );

  /// Navigates to the details page for the given coin
  void _goToDetails(Coin coin) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => CurrencyDetailsPage(coin: coin)));
  }

  /// Filters a list of coins to only include coins whose names contain the
  /// search filter text
  List<MapEntry<Coin, Future<Price>>> _filterCoins(
      List<MapEntry<Coin, Future<Price>>> allCoins) {
    final pattern = _searchFilter.text.toLowerCase();
    final filter = (MapEntry<Coin, Future<Price>> entry) =>
        entry.key.fullName.toLowerCase().contains(pattern);
    return allCoins.where(filter).toList();
  }

  /// Filters a list of fiat symbols to only include symbols whose names contain the
  /// search filter text
  Set<String> _filterSymbols(Set<String> allSymbols) {
    final pattern = _searchFilter.text.toLowerCase();
    final filter = (String symbol) => symbol.toLowerCase().contains(pattern);
    return allSymbols.where(filter).toSet();
  }

  /// Create a list view widget for a list of coins
  /// If the search filter is not empty, only matching coins are included
  Widget _buildCoinsListView(List<Coin> allCoins) {
    List<MapEntry<Coin, Future<Price>>> entries;
    if (_isComplete) {
      final presentCoins = allCoins
          .map((coin) => MapEntry(coin, _priceCache.prices[coin.symbol]))
          .toList();
      presentCoins.sort(_sort.comparator());
      entries = presentCoins
          .map((e) => MapEntry(e.key, Future.value(e.value)))
          .toList();
    } else {
      entries = allCoins
          .map((coin) => MapEntry(coin, _priceCache.priceFor(coin.symbol)))
          .toList();
    }

    final coins =
        _appBarState == _AppBarState.search ? _filterCoins(entries) : entries;
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        itemCount: coins.length,
        itemBuilder: (context, index) {
          final coin = coins[index];
          return _buildCoinRow(coin.key, coin.value);
        },
      ),
    );
  }

  /// Creates a widget for the list of tracked coins
  Widget _buildTrackedCoins() => CircularProgressFallbackBuilder(
        isFallback: _isLoading,
        builder: (context) {
          final trackedCoins = _session.coins
              .where((coin) => _profile.trackedSymbols.contains(coin.symbol))
              .toList();
          return _buildCoinsListView(trackedCoins);
        },
      );

  /// Creates a widget for the list of coins
  Widget _buildAllCoins() => CircularProgressFallbackBuilder(
        isFallback: _isLoading,
        builder: (context) => _buildCoinsListView(_session.coins),
      );

  Widget _buildFiatSymbolsList() {
    final entries = _session.fiatSymbols;
    final symbolsList =
        _appBarState == _AppBarState.search ? _filterSymbols(entries) : entries;
    return ListView.builder(
      itemCount: symbolsList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(symbolsList.elementAt(index)),
          onTap: () => (widget.onFiatPressed)(symbolsList.elementAt(index)),
        );
      },
    );
  }
}
