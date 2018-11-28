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

  /// Key for the entire credentials form
  final _formKey = GlobalKey<FormState>();

  /// Controller for text field for FROM
  final _fromController = TextEditingController();

  /// Controller for text field for TO
  final _toController = TextEditingController();

  /// Controller for text field for AMOUNT
  final _amountController = TextEditingController();

  /// Value that has been converted
  String _convertedValue = '';

  /// Build the calculator which consists of two dropdown menus for user to select
  /// currencies to convert
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Exchange Rate Calculator'),
          centerTitle: true,
        ),
        drawer: UserDrawer(),
        body: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Row(
                /// Row to hold the text fields for user input of amount and currency
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.only(top: 32.0),
                        width: 250.0,
                        child: TextFormField(
                          controller: _amountController,
                          style: TextStyle(fontSize: 18.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(fontSize: 18.0),
                            labelText: 'Amount',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          // Since we only want numerical input, we use a number keyboard. There
                          // are also other keyboards for dates, emails, phone numbers, etc.
                          keyboardType: TextInputType.number,
                          onEditingComplete: _updateConversionValue,
                          validator: _validateAmount,
                          autovalidate: true,
                        ),
                      ),
                      Container(
                        /// Row for text field that allows user input for a specific
                        /// currency or populates based on selection of buttons
                        padding: const EdgeInsets.all(16.0),
                        width: 250.0,
                        child: TextFormField(
                          controller: _fromController,
                          style: TextStyle(fontSize: 18.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(fontSize: 18.0),
                            labelText: 'Currency FROM',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          // Since we only want numerical input, we use a number keyboard. There
                          // are also other keyboards for dates, emails, phone numbers, etc.
                          keyboardType: TextInputType.text,
                          onEditingComplete: _updateConversionValue,
                          validator: _validateSymbol,
                          autovalidate: true,
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
                          child: RaisedButton(
                              color: Colors.green,
                              child: Text(
                                'Crypto',
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
                                setState(
                                    () => _fromController.text = coin.symbol);
                                _updateConversionValue();
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
                                'Fiat',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.white),
                              ),
                              onPressed: () async {
                                final symbol = await Navigator.push<String>(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => CurrencyListPage(
                                              onFiatPressed: (symbol) =>
                                                  Navigator.pop(
                                                      context, symbol),
                                              asDialog: true,
                                              asTabView: false,
                                            )));
                                setState(() => _fromController.text = symbol);
                                _updateConversionValue();
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
                        child: TextFormField(
                          controller: _toController,
                          style: TextStyle(fontSize: 18.0, color: Colors.black),
                          decoration: InputDecoration(
                            labelStyle: TextStyle(fontSize: 18.0),
                            labelText: 'Currency TO',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          // Since we only want numerical input, we use a number keyboard. There
                          // are also other keyboards for dates, emails, phone numbers, etc.
                          keyboardType: TextInputType.text,
                          onEditingComplete: _updateConversionValue,
                          validator: _validateSymbol,
                          autovalidate: true,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Container(

                                  /// Build Button menu for selecting a currency
                                  child: RaisedButton(
                                      color: Colors.green,
                                      child: Text(
                                        'Crypto',
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.white),
                                      ),
                                      onPressed: () async {
                                        final coin = await Navigator.push<Coin>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    CurrencyListPage(
                                                      onCoinPressed: (coin) =>
                                                          Navigator.pop(
                                                              context, coin),
                                                      asDialog: true,
                                                    )));
                                        setState(() =>
                                            _toController.text = coin.symbol);
                                        _updateConversionValue();
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
                                        'Fiat',
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.white),
                                      ),
                                      onPressed: () async {
                                        final symbol =
                                            await Navigator.push<String>(
                                                context,
                                                MaterialPageRoute(
                                                    builder:
                                                        (_) => CurrencyListPage(
                                                              onFiatPressed: (symbol) =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      symbol),
                                                              asDialog: true,
                                                              asTabView: false,
                                                            )));
                                        setState(
                                            () => _toController.text = symbol);
                                        _updateConversionValue();
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
          ),
        ),
      );

  /// Validates the form and saving its state when valid
  bool _validate() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  /// Validate the input amount
  String _validateAmount(String value) {
    if (value == null || value.isEmpty) return 'Required';

    // Encapsulate in a try block in case of non-numerical input
    try {
      final valueDouble = double.parse(value);
      return null;
    } catch (error) {
      print('Error: $error');
      return 'Must be a number';
    }
  }

  /// Validate a symbol field
  String _validateSymbol(String value) {
    if (value == null || value.isEmpty) return 'Required';
    if (_session.coins.where((x) => x.symbol == value.toUpperCase()).length ==
        1) {
      return null;
    }
    if (_session.fiatSymbols.contains(value.toUpperCase())) return null;
    return 'Unrecognized symbol';
  }

  /// Perform the conversion
  void _updateConversionValue() async {
    if (!_validate()) return;

    try {
      final singlePrice =
          await _cryptoCompare.price(_fromController.text, _toController.text);
      final price = double.parse(_amountController.text) * singlePrice.price;
      setState(() {
        if ('$price'.length > 4) {
          _convertedValue = price.toStringAsPrecision(7);
        } else {
          _convertedValue = price.toString();
        }
      });
    } catch (error) {
      _showErrorDialog('$error');
    }
  }

  /// Show the error dialog to user
  void _showErrorDialog(String errorMessage) {
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
