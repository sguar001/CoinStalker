import 'package:flutter/material.dart';
import 'currency_detail.dart';
import 'cryptocompare.dart';

/// Class for building the Currency List
/// This will display the currency list

class CurrencyList extends StatefulWidget {
  // default constructor
  const CurrencyList();

  @override
  _CurrencyListState createState() => _CurrencyListState();
}

// Class is Stateful because we must update the list as user enters text
class _CurrencyListState extends State<CurrencyList> {
  CryptoCompare cryptoCompare = new CryptoCompare();
  // Controls the text label we use as a search bar
  final TextEditingController _filter = new TextEditingController();

  // Holds the search text query
  String _searchText = "";

  // Coins we get from API
  List coinList = new List();

  // Coins filtered by search text
  List filteredCoins = new List();

  Icon _searchIcon = new Icon(Icons.search);

  Widget _appBarTitle = new Text('Coins');

  final _saved = new Set<String>();

  // Override the default constructor for the page state so that it evaluates
  // whether there is text present in the search bar, and if it is, it sets
  // the _searchText to the input so that the list can be updated appropriately
  _CurrencyListState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          filteredCoins = coinList;
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  // need to override the initState method so that we can get the coin list and assign
  // the results to coins and filteredCoins list when page Loads
//  @override
  void initState() {
    this._getCoins();
    super.initState();
  }

  // function to build the app bar and container that holds coin list
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        child: _getCoins(),
      ),
      resizeToAvoidBottomPadding: false,
    );
  }

  // function to build the app bar, setting the title to current _appBarTitle
  Widget _buildAppBar(BuildContext context) {
    return new AppBar(
      centerTitle: true,
      title: _appBarTitle,
      backgroundColor: Colors.green,
      leading: new IconButton(
        icon: _searchIcon,
        onPressed: _searchPressed,
      ),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.list),
          onPressed: _pushSaved,
        )
      ],
    );
  }

  // function to change route to favorite's list
  void _pushSaved() {
    // When the user taps the list icon in the app bar, build a route and push it to the Navigator’s stack. This action changes the screen to display the new route.
    Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
      final tiles = _saved.map((coinName) {
        return new ListTile(title: new Text(coinName));
      });
      final divided = ListTile.divideTiles(
        context: context,
        tiles: tiles,
      ).toList();

      return new Scaffold(
        appBar: new AppBar(
          title: new Text('Saved Coins'),
          backgroundColor: Colors.green,
          centerTitle: true,
        ),
        body: new ListView(children: divided),
      );
    }));
  }

  // callback function that activates when the search icon is pressed
  // in the event the search box is activated, the icon is changed to close icon
  // and app bar title is switched to a search box
  // Otherwise, it is the default state of having title and search icon
  void _searchPressed() {
    // update the state of the app bar to show search box
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          controller: _filter,
          decoration: new InputDecoration(
              prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('Coins');
        filteredCoins = coinList;
        _filter.clear();
      }
    });
  }

  // Create a list view from coins retrieved from coin API
  // If search query is not empty, create a list from matched results
  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
    Coins coins = snapshot.data;

    if (!(_searchText.isEmpty)) {
      List tempList = new List();
      for (int i = 0; i < coins.data.length; i++) {
        if (coins.data[i].fullName
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tempList.add(coins.data[i]);
        }
      }
      filteredCoins = tempList;
    } else {
      List tempList = new List();
      for (int i = 0; i < coins.data.length; i++) {
        tempList.add(coins.data[i]);
      }
      filteredCoins = tempList;
    }

    return ListView.builder(
      itemCount: coinList == null ? 0 : filteredCoins.length,
      itemBuilder: (context, index) {
        return Column(children: <Widget>[
          _buildRow(filteredCoins[index]),
          Divider(height: 2.0),
        ]);
      },
    );
  }

  void _showPrice(BuildContext context, String fromSymbol, String toSymbol) {
    var alert = AlertDialog(
      title: Text('Price'),
      content: FutureBuilder(
          future: cryptoCompare.price(fromSymbol, toSymbol),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return CircularProgressIndicator();

              default:
                if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                } else {
                  var price = snapshot.data as double;
                  return Text('1 $fromSymbol = $price $toSymbol');
                }
            }
          }),
      actions: <Widget>[
        FlatButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
    showDialog(context: context, builder: (context) => alert);
  }

//  function to build a row to be used in a list view
  Widget _buildRow(Coin currencyCoin) {
    return new ListTile(
      title: Text(currencyCoin.fullName),
      onTap: () async {
        // On tapping of the tile, transition to detail page of coin
        // when Navigator returns, it returns whether coin was favorited or not
        final result = await Navigator.push(
            context,
            new MaterialPageRoute(
              builder: (context) => new CurrencyDetail(currencyCoin, _saved),
            ));
        // Based on the returned value, if it was saved, add to _saved list,
        // otherwise return
        setState(() {
          if (result) {
            _saved.add(currencyCoin.fullName);
          } else {
            _saved.remove(currencyCoin.fullName);
          }
        });
      },
    );
  }

  // function that returns a widget, either the list of coins retrieved
  // from the API or error message widget
  Widget _getCoins() {
    Widget toReturn = FutureBuilder<Coins>(
      future: cryptoCompare.coins(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(child: CircularProgressIndicator());

          default:
            if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else {
              return createListView(context, snapshot);
            }
        }
      },
    );
    return toReturn;
  }
}
