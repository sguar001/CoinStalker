import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'dashboard.dart';
import 'session.dart';
import 'signin.dart';

/// Widget for displaying the details of an individual currency
/// This class is stateful because it must navigate to the next page after the
/// authentication information is retrieved
class SplashPage extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _SplashPageState();
}

/// State for the splash page
class _SplashPageState extends State<SplashPage> {
  /// Instance of the Firebase authentication library
  final _auth = FirebaseAuth.instance;

  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Called when this object is inserted into the tree
  @override
  void initState() {
    super.initState();

    _auth.currentUser().then((user) {
      if (user == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => SignInPage()));
      } else {
        // Begin the prefetch
        Future.wait([_cryptoCompare.coins().then((coins) => coins.complete())])
            .then((List responses) {
          // Fill out the session
          Session.initialize(user: user, coins: responses[0]);

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => DashboardPage()));
        }).catchError((e) =>
                print('Error in splash prefetch: $e')); // TODO: Error reporting
      }
    });
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) =>
    // TODO: Use a splash image
    Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
}
