import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'currency_list.dart';
import 'drawer.dart';
import 'session.dart';

/// Widget for displaying the exchange rate calculator to
/// exchange between two specified currencies
class ExchangeRateCalculator extends StatefulWidget {
  /// Creates the mutable state for this widget
  @override
  createState() => _ExchangeRateCalculatorState();
}

class _ExchangeRateCalculatorState extends State<ExchangeRateCalculator> {
  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Instance of the application session
  final _session = Session();

  /// Get users default currency preference to display initially
  final String userPreferrence = '';

  /// Coin type to be converted from
  String _fromValue;

  /// Coin type to convert to
  String _toValue;

  /// Amount to exchange
  double _inputValue;

  /// Coin/currency to exchange
  Coin _userInput;

  /// Controller for text field for FROM
  TextEditingController _fromController = TextEditingController();

  /// Controller for text field for TO
  TextEditingController _toController = TextEditingController();

  /// Controller for text field for AMOUNT
  TextEditingController _amountController = TextEditingController();

  /// Value that has been converted
  String _convertedValue = '';

  /// Add flags for whether to show error UI
  bool _showErrorUI = false;
  bool _showValidationError = false;

  /// Pass this into the TextField so that the input value persists!
  final _inputKey = GlobalKey(debugLabel: 'inputText');

  /// Build the calculator which consists of two dropdown menus for user to select
  /// currencies to convert
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        drawer: UserDrawer(),
        body: ListView(
          children: <Widget>[
            Row(
              /// Row for the title of page
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
              /// Row to hold the text fields for user input of amount and currency
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.only(top: 32.0),
                      width: 250.0,
                      child: TextField(
                          controller: _amountController,
                          key: _inputKey,
                          style: TextStyle(fontSize: 18.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(fontSize: 18.0),
                            errorText: _showValidationError
                                ? 'Invalid number entered'
                                : null,
                            labelText: 'Amount',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          // Since we only want numerical input, we use a number keyboard. There
                          // are also other keyboards for dates, emails, phone numbers, etc.
                          keyboardType: TextInputType.number,
                          // When input is changed, call update function
//                        onSubmitted: _updateInputValue,
                          onSubmitted: (userInput) {
                            setState(() {
                              _amountController.text = userInput;
                            });
                          }),
                    ),
                    Container(
                      /// Row for text field that allows user input for a specific
                      /// currency or populates based on selection of buttons
                      padding: const EdgeInsets.all(16.0),
                      width: 250.0,
                      child: TextField(
                        controller: _fromController,
                        style: TextStyle(fontSize: 18.0, color: Colors.black),
                        decoration: InputDecoration(
                          labelStyle: TextStyle(fontSize: 18.0),
                          errorText: _showValidationError
                              ? 'Invalid number entered'
                              : null,
                          labelText: 'Currency FROM',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        // Since we only want numerical input, we use a number keyboard. There
                        // are also other keyboards for dates, emails, phone numbers, etc.
                        keyboardType: TextInputType.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(

                        /// Build Button menu for selecting a currency
//                        child: _buildCoins('FROM')),
                        child: RaisedButton(
                            color: Colors.green,
                            child: Text(
                              'Currencies',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.white),
                            ),
                            onPressed: () async {
                              final coin = await Navigator.push<Coin>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CurrencyListPage(
                                            onCoinPressed: (coin) =>
                                                Navigator.pop(context, coin),
                                            asDialog: true,
                                          )));
                              setState(() {
                                _fromController.text = coin.symbol;
                                _fromValue = coin.symbol;
                                if (_performConversion()) {
                                  _updateInputValue(_amountController.text);
                                } else {
                                  _convertedValue = '';
                                }
                              });
                            })),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Container(

                        /// Build Button menu for selecting a FIAT symbol
                        padding: const EdgeInsets.only(left: 32.0),
                        child: RaisedButton(
                            color: Colors.green,
                            child: Text(
                              'FIAT Symbol',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.white),
                            ),
                            onPressed: () async {
                              final symbol = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => CurrencyListPage(
                                            onFiatPressed: (symbol) =>
                                                Navigator.pop(context, symbol),
                                            asDialog: true,
                                            asTabView: false,
                                          )));
                              setState(() {
                                _fromController.text = symbol;
                                _fromValue = symbol;
                                if (_performConversion()) {
                                  _updateInputValue(_amountController.text);
                                } else {
                                  _convertedValue = '';
                                }
                              });
                            }))
                  ],
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    RotatedBox(
                      quarterTurns: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.compare_arrows,
                          color: Colors.green,
                          size: 32.0,
                        ),
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
                      /// Row for text field that allows user input for a specific
                      /// currency or populates based on selection of buttons
                      padding: const EdgeInsets.all(16.0),
                      width: 250.0,
                      child: TextField(
                        controller: _toController,
                        style: TextStyle(fontSize: 18.0, color: Colors.black),
                        decoration: InputDecoration(
                          labelStyle: TextStyle(fontSize: 18.0),
                          errorText: _showValidationError
                              ? 'Invalid number entered'
                              : null,
                          labelText: 'Currency TO',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                        // Since we only want numerical input, we use a number keyboard. There
                        // are also other keyboards for dates, emails, phone numbers, etc.
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Container(

                                /// Build Button menu for selecting a currency
//                        child: _buildCoins('FROM')),
                                child: RaisedButton(
                                    color: Colors.green,
                                    child: Text(
                                      'Currencies',
                                      style: TextStyle(
                                          fontSize: 14.0, color: Colors.white),
                                    ),
                                    onPressed: () async {
                                      final coin = await Navigator.push<Coin>(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => CurrencyListPage(
                                                    onCoinPressed: (coin) =>
                                                        Navigator.pop(
                                                            context, coin),
                                                    asDialog: true,
                                                  )));
                                      setState(() {
                                        _toController.text = coin.symbol;
                                        _toValue = coin.symbol;
                                        if (_performConversion()) {
                                          _updateInputValue(
                                              _amountController.text);
                                        } else {
                                          _convertedValue = '';
                                        }
                                      });
                                    })),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Container(

                                /// Build Button menu for selecting a FIAT symbol
                                padding: const EdgeInsets.only(left: 32.0),
                                child: RaisedButton(
                                    color: Colors.green,
                                    child: Text(
                                      'FIAT Symbol',
                                      style: TextStyle(
                                          fontSize: 14.0, color: Colors.white),
                                    ),
                                    onPressed: () async {
                                      final symbol = await Navigator.push<
                                              String>(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => CurrencyListPage(
                                                    onFiatPressed: (symbol) =>
                                                        Navigator.pop(
                                                            context, symbol),
                                                    asDialog: true,
                                                    asTabView: false,
                                                  )));

                                      setState(() {
                                        _toController.text = symbol;
                                        _toValue = symbol;
                                        if (_performConversion()) {
                                          _updateInputValue(
                                              _amountController.text);
                                        } else {
                                          _convertedValue = '';
                                        }
                                      });
                                    }))
                          ],
                        )
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 32.0),
                      width: 250.0,
                      child: InputDecorator(
                          isFocused: false,
                          child: Text(_convertedValue,
                              style: TextStyle(
                                  fontSize: 18.0, color: Colors.black)),
                          decoration: InputDecoration(
                              labelText: 'Output',
                              labelStyle: TextStyle(fontSize: 18.0),
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
  Widget _buildCoins(String op) {
    if (op == 'FROM') {
      return DropdownButton(
          hint: _fromValue == null
              ? Text('Select a Value to Convert From')
              : Text(_fromValue),
          items: _session.coins.map((Coin coin) {
            return DropdownMenuItem<String>(
                child: Text(coin.fullName), value: coin.symbol);
          }).toList(),
          onChanged: (String value) {
            _fromValue = value;
            setState(() {});
          });
    } else {
      return DropdownButton(
          hint: _toValue == null
              ? Text('Select a Value to Convert To')
              : Text(_toValue),
          items: _session.coins.map((Coin coin) {
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
          'Please select values to convert from the dropdowns.');
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

  bool _performConversion() {
    if (_toValue != null &&
        _fromValue != null &&
        _toController.text != '' &&
        _fromController.text != '' &&
        _amountController.text != '') {
      return true;
    } else {
      return false;
    }
  }
}
