import 'package:flutter/material.dart';

import 'splash.dart';

/// Entry point for the application
void main() => runApp(MyApp());

/// Top-level application widget
class MyApp extends StatelessWidget {
  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CoinStalker',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: SplashPage(),
      );
}
