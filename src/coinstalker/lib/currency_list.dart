import 'package:flutter/material.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'currency_details.dart';
import 'database.dart';
import 'drawer.dart';
import 'price_widget.dart';
import 'session.dart';
import 'track_button.dart';

/// Widget for displaying, searching, and sorting the list of currencies
/// This class is stateful because it must update as the user searches and sorts
class CurrencyListPage extends StatefulWidget {
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

  /// Current state of the app bar
  /// The app bar serves multiple purposes and changes state when the user
  /// presses the search button or the cancel search button
  var _appBarState = _AppBarState.initial;

  /// Controls the search bar text label
  final _searchFilter = TextEditingController();

  /// Called when this object is inserted into the tree
  /// Requests the list of coins and installs a listener on the search filter
  @override
  void initState() {
    super.initState();

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
          drawer: UserDrawer(),
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
  Widget _buildCoinRow(Coin coin) => ListTile(
        title: Text(coin.fullName),
        trailing: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: currentPriceWidget(coin.symbol)),
            Flexible(child: buildTrackButton(coin, _session.profileRef)),
          ],
        ),
        // When the tile is tapped, transition to the details page for the
        // chosen coin
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => CurrencyDetailsPage(coin: coin))),
      );

  /// Filters a list of coins to only include coins whose names contain the
  /// search filter text
  List<Coin> _filterCoins(List<Coin> allCoins) {
    final pattern = _searchFilter.text.toLowerCase();
    final filter = (Coin coin) => coin.fullName.toLowerCase().contains(pattern);
    return allCoins.where(filter).toList();
  }

  /// Create a list view widget for a list of coins
  /// If the search filter is not empty, only matching coins are included
  Widget _buildCoinsListView(List<Coin> allCoins) {
    final coins =
        _appBarState == _AppBarState.search ? _filterCoins(allCoins) : allCoins;
    return ListView.builder(
      itemCount: coins.length,
      itemBuilder: (context, index) => _buildCoinRow(coins[index]),
    );
  }

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
}
