import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'drawer.dart';

/// Widget for displaying the exchange rate calculator to
/// exchange between two specified currencies
class ExchangeRateCalculator extends StatefulWidget {
  /// The current sign-in user
  final FirebaseUser user;

  /// Constructs this widget instance
  ExchangeRateCalculator({@required this.user});

  /// Creates the mutable state for this widget
  @override
  createState() => _ExchangeRateCalculatorState();
}

class _ExchangeRateCalculatorState extends State<ExchangeRateCalculator> {
  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Get users default currency preference to display initially
  final String userPreferrence = '';

  /// Future that holds all available coins
  Future<List<Coin>> _allCoins;

  /// List that holds all available coins
  List<Coin> _coinsList;

  /// Coin type to be converted from
  String _fromValue;

  /// Coin type to convert to
  String _toValue;

  /// Value to exchange
  double _inputValue;

  /// Value that has been converted
  String _convertedValue = '';

  /// Add flags for whether to show error UI
  bool _showErrorUI = false;
  bool _showValidationError = false;

  /// Pass this into the TextField so that the input value persists!
  final _inputKey = GlobalKey(debugLabel: 'inputText');

  /// Called when first initializing the state
//  @override
  void initState() {
    super.initState();

    // Start the coins request before the widget is built
    // By only requesting the list of coins whenever the state is initialized,
    // the request is only made once per instantiation of the page
    _allCoins = _cryptoCompare.coins().then((coins) => coins.complete());
  }

  /// Build the calculator which consists of two dropdown menus for user to select
  /// currencies to convert
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        drawer: UserDrawer(user: widget.user),
        body: ListView(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 32.0),
                    ),
                    Text(
                      'Select the currencies you\'d like to convert',
                      style: TextStyle(fontSize: 16.0),
                    )
                  ],
                )
              ],
            ),
            Row(
              /// Row to hold drop down menu for converting from and user input box
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 32.0),
                      width: 250.0,
                      child: TextField(
                        key: _inputKey,
                        style: Theme.of(context).textTheme.display1,
                        decoration: InputDecoration(
                          labelStyle: Theme.of(context).textTheme.display1,
                          errorText: _showValidationError
                              ? 'Invalid number entered'
                              : null,
                          labelText: 'Input',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        // Since we only want numerical input, we use a number keyboard. There
                        // are also other keyboards for dates, emails, phone numbers, etc.
                        keyboardType: TextInputType.number,
                        // When input is changed, call update function
                        onChanged: _updateInputValue,
                      ),
                    ),
                    Container(

                        /// Build dropdown menu
                        padding: const EdgeInsets.only(top: 32.0),
                        child: _buildCoins(_allCoins, 'FROM')),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                    ),
                    RotatedBox(
                      quarterTurns: 1,
                      child: Icon(
                        Icons.compare_arrows,
                        color: Colors.green,
                        size: 32.0,
                      ),
                    )
                  ],
                ),
              ],
            ),
            Row(
              /// Row to hold drop down menu for converting to
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: _buildCoins(_allCoins, 'TO')),
                    Container(
                      padding: const EdgeInsets.only(top: 64.0),
                      width: 250.0,
                      child: InputDecorator(
                          isFocused: false,
                          child: Text(_convertedValue,
                              style: Theme.of(context).textTheme.display1),
                          decoration: InputDecoration(
                              labelText: 'Output',
                              labelStyle: Theme.of(context).textTheme.display1,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(5.0)))),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  /// Creates a future builder widget for a list of coins
  /// While the list is being retrieved, a progress indicator is displayed

  Widget _buildCoins(Future<List<Coin>> future, String op) => FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());

            case ConnectionState.none:
            case ConnectionState.done:
              if (snapshot.hasError || snapshot.data == null) {
                print('error');
                return Text(snapshot.error.toString()); // TODO: Style this
              }

//              coinNames = extractNames(snapshot.data);

              /// Returns the list of coins
              return _buildDropDown(snapshot.data, op);
          }
        },
      );

  /// Return the specified drop down menu, with the option to select the available coins
  Widget _buildDropDown(List<Coin> coins, String op) {
    ///TODO: NEED TO ADD CURRENCY VALUES HERE, SUCH AS USD, GPB, JPY, ETC.
    if (op == 'FROM') {
      return DropdownButton(
          hint: _fromValue == null
              ? Text('Select a Value to Convert From')
              : Text(_fromValue),
          items: coins.map((Coin coin) {
            return DropdownMenuItem<String>(
                child: Text(coin.fullName), value: coin.symbol);
          }).toList(),
          onChanged: (String v) {
            _fromValue = v;
            setState(() {});
          });
    } else {
      return DropdownButton(
          hint: _toValue == null
              ? Text('Select a Value to Convert To')
              : Text(_toValue),
          items: coins.map((Coin coin) {
            return DropdownMenuItem<String>(
                child: Text(coin.fullName), value: coin.symbol);
          }).toList(),
          onChanged: (String value) {
            _toValue = value;
            setState(() {});
          });
    }
  }

  /// function to return a list of <String> with all the names of the given
  /// List of <Coin>
  List<String> extractNames(List<Coin> coins) {
    List<String> names = [];

    for (Coin coin in coins) {
      names.add(coin.fullName);
    }

    return names;
  }

  /// Build the app bar for Exchange Rate Calculator Page
  Widget _buildAppBar() {
    return AppBar(
      title: Text('Exchange Currencies'),
      centerTitle: true,
    );
  }

  /// Take in the inputted value to be converted (from string to double)
  void _updateInputValue(String input) {
    setState(() {
      if (input == null || input.isEmpty) {
        _convertedValue = '';
      } else {
        // Encapsulate in a try block in case of non-numerical input
        try {
          final inputDouble = double.parse(input);
          _showValidationError = false;
          _inputValue = inputDouble;

          // update the converted value based on the inputted value
          _updateConversionValue();
        } on Exception catch (error) {
          print('Error: $error');
          _showValidationError = true;
        }
      }
    });
  }

  /// Convert the provided fromValue to toValue times the provided user input
  Future<void> _updateConversionValue() async {
    if (_fromValue != null && _toValue != null) {
      try {
        final _singlePrice = await _cryptoCompare.price(_fromValue, _toValue);
        final _price = _inputValue * _singlePrice;
        if (_price != null) {
          setState(() {
            if (_price.toString().length > 4) {
              _convertedValue = _price.toStringAsPrecision(7);
            } else {
              _convertedValue = _price.toString();
            }
          });
        }
      } on Exception catch (error) {
        setState(() {
          _showErrorUI = true;
          _showDialog(error.toString());
        });
      }
    } else {
      _showDialog('To and From values cannot be empty! '
          'Please seletc values to convert from the dropdowns.');
    }
  }

  /// Show the error dialog to user
  void _showDialog(String errorMessage) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type dialog
          return AlertDialog(
            title: Text('Error in Conversion!'),
            content: Text(errorMessage),
            actions: <Widget>[
              FlatButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }
}
