import 'package:flutter/material.dart';
import 'cryptocompare.dart';

class CurrencyDetail extends StatefulWidget {
  final Coin coin;
  final Set<String> _saved;

  CurrencyDetail(this.coin, this._saved);

  @override
  _CurrencyDetailState createState() => _CurrencyDetailState();
}

class _CurrencyDetailState extends State<CurrencyDetail> {
  CryptoCompare cryptoCompare = new CryptoCompare();

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () {
        // Override backbutton press on Android
        final alreadySaved = widget._saved.contains(widget.coin.fullName);
        Navigator.pop(context,
            alreadySaved); // When going back, return whether it was saved
      },
      child: new Scaffold(
          appBar: _buildAppBar(),
          body: new Container(
              child: new Stack(
            children: <Widget>[
              _getCoinDetails(),
            ],
          ))),
    );
  }

  // function to display various details of the specified coin
  Widget _getCoinDetails() {
    return new ListView(
      padding: new EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 32.0),
      children: <Widget>[
        new Container(
            padding: new EdgeInsets.symmetric(horizontal: 32.0),
            child: new Column(
              // Stack allows widgets to be placed on top of each other
              children: <Widget>[
                new Container(
                  // Add a row underneath coin name that holds various coin details
                  padding: EdgeInsets.only(top: 18.0), // adds padding to top
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: new Column(children: <Widget>[
                          new Text('Current USD Price: '),
                          new Container(
                            padding: EdgeInsets.all(32.0),
                            child: _getPrice(widget.coin.symbol, 'USD'),
                          )
                        ]),
                      ),
                    ],
                  ),
                ),
                new Container(
                    padding: EdgeInsets.only(top: 18.0),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                            child: new Column(
                          children: <Widget>[new Text('Latest news')],
                        ))
                      ],
                    ))
              ],
            ))
      ],
    );
  }

  Container _getToolBar(BuildContext context) {
    return new Container(
      margin: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: new BackButton(color: Colors.white),
    );
  }

  // Function to build the appbar
  // Use widget.objectName to access object initialized in StatefulWidget
  Widget _buildAppBar() {
    final alreadySaved = widget._saved.contains(widget.coin.fullName);
    return new AppBar(
      centerTitle: true,
      title: new Text(widget.coin.coinName),
      backgroundColor: Colors.green,
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context,
              alreadySaved); // When going back, return whether it was saved
        },
      ),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(alreadySaved ? Icons.favorite : Icons.favorite_border,
              color: alreadySaved ? Colors.red : null),
          onPressed: () {
            setState(() {
              if (alreadySaved) {
                widget._saved.remove(widget.coin.fullName);
              } else {
                widget._saved.add(widget.coin.fullName);
              }
            });
          },
        )
      ],
    );
  }

//  Function that returns a widget (text) that contains price of coin in value specified
  Widget _getPrice(String fromSymbol, String toSymbol) {
    Widget toReturn = FutureBuilder(
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
                return Text('$price $toSymbol');
              }
          }
        });
    return toReturn;
  }
}
