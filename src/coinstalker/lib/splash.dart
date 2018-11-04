import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard.dart';
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

  /// Called when this object is inserted into the tree
  @override
  void initState() {
    super.initState();

    // FIXME: Loading is a little flickery
    // Perhaps add a brief delay to ensure that animations have time to run
    _auth.currentUser().then((user) {
      if (user == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => SignInPage()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => DashboardPage(user: user)));
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
