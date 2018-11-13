import 'package:flutter/material.dart';

import 'drawer.dart';

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

  /// Default currency to be used in conversions
  /// TODO: need to tie this value to the user!
  String _defaultCurrency = '';

  @override
  Widget build(BuildContext context) {
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
                          setState(() {});
                        })),
              ],
            )
          ],
        ),
        Divider(height: 32.0, color: Colors.black),
      ],
    );
  }

  /// Build the app bar for Settings Page
  Widget _buildAppBar() {
    return AppBar(
      title: Text('User Settings'),
      centerTitle: true,
    );
  }
}
