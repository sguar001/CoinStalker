import 'package:flutter/material.dart';

import 'cryptocompare.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  final cryptoCompare = CryptoCompare();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinStalker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Coins'),
        ),
        body: FutureBuilder<Coins>(
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
        ),
      ),
    );
  }

  Widget createListView(BuildContext context, AsyncSnapshot snapshot) {
    Coins coins = snapshot.data;
    return ListView.builder(
      itemCount: coins.data.length,
      itemBuilder: (context, index) {
        final coin = coins.data[index];
        return Column(children: <Widget>[
          ListTile(
            title: Text(coin.fullName),
            onTap: () => _showPrice(context, coin.symbol, 'USD'),
          ),
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
}
