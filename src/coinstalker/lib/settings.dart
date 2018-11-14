import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'drawer.dart';
import 'session.dart';
import 'database.dart';

/// Widget for displaying the exchange rate calculator to
/// exchange between two specified currencies
class Settings extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  /// list of available currency defaults for user
  List<String> _availableCurrencies = [
    'USD',
    'GBP',
    'EUR',
    'JPY',
  ];

  /// Instance of the application session
  final _session = Session();

  /// Default currency to be used in conversions
  /// TODO: need to tie this value to the user!
  String _defaultCurrency = '';

  @override
  void initState() {
    super.initState();

    _getUserDefault().then((value) {
      print(_defaultCurrency);
      setState(() {
        _defaultCurrency = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print(_defaultCurrency);
    return Scaffold(
        appBar: _buildAppBar(), drawer: UserDrawer(), body: _buildOptions());
  }

  /// Return list of settings options
  Widget _buildOptions() {
    return ListView(
      children: <Widget>[
        Row(
          /// ROW for currency preference
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Default Currency',
                      style: TextStyle(fontSize: 18.0),
                    )),
                Container(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton(
                        hint: _defaultCurrency == ''
                            ? Text('Select the default currency')
                            : Text(_defaultCurrency),
                        items: _availableCurrencies.map((String currencyType) {
                          return DropdownMenuItem<String>(
                              child: Text(currencyType), value: currencyType);
                        }).toList(),
                        onChanged: (String currency) {
                          _defaultCurrency = currency;
                          Firestore.instance.runTransaction((tx) async {
                            _session.profileRef.updateData(<String, dynamic>{
                              'displaySymbol': _defaultCurrency,
                            });
                          });
                          setState(() {});
                        })),
              ],
            )
          ],
        ),
        Divider(height: 16.0, color: Colors.black),
      ],
    );
  }

  /// Return the users preferred currency from their profile in database
  Future<String> _getUserDefault() async {
    String defaultValue = '';
    print('1');
    await _buildStreamDefault(_userDefaultCurrency()).then((value) {
      print('2');
      defaultValue = value;
    });
    print('3');
    return defaultValue;
  }

  /// Builds a stream of the user's default currency preference
  Stream<String> _userDefaultCurrency() =>
      Profile.buildStream(_session.profileRef)
          .map((profile) => profile.displaySymbol);

  /// Get the users default currency value from the newly created stream
  Future<String> _buildStreamDefault(Stream<String> stream) async {
    String stringValue = '';

    await stream.first.then((value) {
      stringValue = value;
    });
    return stringValue;
  }

  /// Build the app bar for Settings Page
  Widget _buildAppBar() {
    return AppBar(
      title: Text('User Settings'),
      centerTitle: true,
    );
  }
}
