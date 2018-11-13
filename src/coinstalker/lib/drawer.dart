import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'calculator.dart';
import 'currency_list.dart';
import 'session.dart';
import 'settings.dart';
import 'signin.dart';

/// Widget for displaying the side drawer when signed in
class UserDrawer extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _UserDrawerState();
}

/// State for the user drawer
class _UserDrawerState extends State<UserDrawer> {
  /// Instance of the Firebase authentication library
  final _auth = FirebaseAuth.instance;

  /// Instance of the application session
  final _session = Session();

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Drawer(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      );

  /// Builds the user account header for the top of the drawer
  Widget _buildHeader() => UserAccountsDrawerHeader(
        accountName: _buildAccountName(),
        accountEmail: _buildAccountEmail(),
        currentAccountPicture: _buildAccountPicture(),
      );

  /// Builds a widget for displaying the user name
  Widget _buildAccountName() => _session.user.displayName == null
      ? Container()
      : Text(_session.user.displayName);

  /// Builds a widget for displaying the user email address
  Widget _buildAccountEmail() =>
      _session.user.email == null ? Container() : Text(_session.user.email);

  /// Builds a widget for displaying the user portrait
  Widget _buildAccountPicture() => _session.user.photoUrl == null
      ? Container()
      : Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fill,
              image: NetworkImage(_session.user.photoUrl),
            ),
          ),
        );

  /// Builds a widget containing the list of items in the drawer
  Widget _buildList() => ListView(
        children: [
          ListTile(
            title: Text('Dashboard'),
            leading: Icon(Icons.home),
            onTap: _goToDashboard,
          ),
          ListTile(
            title: Text('Currencies'),
            leading: Icon(Icons.view_list),
            onTap: _goToCurrencies,
          ),
          ListTile(
            title: Text('Exchange Rate Calculator'),
            leading: Icon(Icons.compare_arrows),
            onTap: _goToCalculator,
          ),
          Divider(),
          ListTile(
            title: Text('Settings'),
            leading: Icon(Icons.settings),
            onTap: _goToSettings,
          ),
          ListTile(
            title: Text('Sign out'),
            leading: Icon(Icons.exit_to_app),
            onTap: _signOut,
          ),
        ],
      );

  void _goTo(MaterialPageRoute target) {
    Navigator.pop(context); // Close the drawer
    // Push the target route and remove everything between it and the dashboard
    Navigator.pushAndRemoveUntil(context, target, (route) => route.isFirst);
  }

  /// Navigates to the dashboard
  void _goToDashboard() {
    Navigator.pop(context); // Close the drawer
    // The dashboard must stay at the bottom of the stack
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// Navigates to the list of currencies
  void _goToCurrencies() {
    _goTo(MaterialPageRoute(builder: (_) => CurrencyListPage()));
  }

  void _goToCalculator() {
    _goTo(MaterialPageRoute(builder: (_) => ExchangeRateCalculator()));
  }

  void _goToSettings() {
    _goTo(MaterialPageRoute(builder: (_) => Settings()));
  }

  /// Signs out of the user account
  void _signOut() {
    // Clear the stack by popping all routes below the sign-in page
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => SignInPage(initialOperation: _auth.signOut())),
        (_) => false);
  }
}
