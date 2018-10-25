import 'package:flutter/material.dart';

import 'currency_list.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinStalker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CurrencyList(),
    );
  }
}
