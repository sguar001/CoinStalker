import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'database.dart';
import 'drawer.dart';

/// Widget for displaying the details of an individual currency
/// This class is stateful because it must update as the user toggles tracking
class CurrencyDetailsPage extends StatefulWidget {
  /// The current signed-in user
  final FirebaseUser user;

  /// The coin to display details for
  final Coin coin;

  /// Constructs the widget instance
  CurrencyDetailsPage({@required this.user, @required this.coin});

  /// Creates the mutable state for this widget
  @override
  createState() => _CurrencyDetailsPageState();
}

/// State for the currency details page
class _CurrencyDetailsPageState extends State<CurrencyDetailsPage> {
  /// Instance of the CryptoCompare library
  final _cryptoCompare = CryptoCompare();

  /// Instance of the Firestore library
  final _firestore = Firestore.instance;

  /// Current price of the currency retrieved from CryptoCompare
  Future<double> _price;

  /// Document reference for the current user profile
  DocumentReference _userProfileRef;

  /// User profile from _userProfileRef
  Profile _userProfile;

  /// Called when this object is inserted into the tree
  /// Requests the price of the currency
  @override
  void initState() {
    super.initState();

    // Start the price request before the widget is built
    // By only requesting the price whenever the state is initialized, the
    // request is only made once per instantiation of the page
    // TODO: Use the user's chosen display currency
    _price = _cryptoCompare.price(widget.coin.symbol, 'USD');

    // Request the user profile
    _userProfileRef = Profile.buildReference(widget.user);
    _userProfileRef
        .snapshots()
        .map((snapshot) => Profile.fromSnapshot(snapshot))
        .listen((profile) => setState(() {
              _userProfile = profile;
            }));
  }

  /// Builds a button to display the tracked status of a coin
  Widget _buildTrackButton() {
    if (_userProfile.trackedSymbols.contains(widget.coin.symbol)) {
      return IconButton(
        icon: Icon(Icons.favorite),
        color: Colors.red,
        onPressed: () {
          _firestore.runTransaction((tx) async {
            _userProfileRef.updateData(<String, dynamic>{
              'trackedSymbols': FieldValue.arrayRemove([widget.coin.symbol]),
            });
          });
        },
      );
    }

    return IconButton(
      icon: Icon(Icons.favorite_border),
      onPressed: () {
        _firestore.runTransaction((tx) async {
          _userProfileRef.updateData(<String, dynamic>{
            'trackedSymbols': FieldValue.arrayUnion([widget.coin.symbol]),
          });
        });
      },
    );
  }

  /// Describes the part of the user interface represented by this widget
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.1,
                child: Image.network(widget.coin.imageUrl),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: FractionallySizedBox(
                  widthFactor: 0.66,
                  child: ListView(
                    children: [
                      // TODO: OLHC graph
                      _buildPropertyRow(
                          name: 'Symbol', value: Text(widget.coin.symbol)),
                      _buildPropertyRow(name: 'Price', value: _buildPrice()),
                      _buildPropertyRow(
                          name: 'Algorithm',
                          value: Text(widget.coin.algorithm)),
                      _buildPropertyRow(
                          name: 'Proof type',
                          value: Text(widget.coin.proofType)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        appBar: AppBar(
          centerTitle: true,
          title: Text(widget.coin.coinName),
          actions: [
            _buildTrackButton(),
          ],
        ),
        drawer: UserDrawer(user: widget.user),
      );

  /// Creates a row for a property of the coin
  Widget _buildPropertyRow({String name, Widget value}) => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$name: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            value,
          ],
        ),
      );

  /// Creates a future builder widget for the current price of the coin
  Widget _buildPrice() => FutureBuilder(
      future: _price,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Container();

          case ConnectionState.none:
          case ConnectionState.done:
            if (snapshot.hasError || snapshot.data == null) {
              return Text(snapshot.error.toString()); // TODO: Style this
            }
            return Text(snapshot.data.toString()); // TODO: Formatting
        }
      });
}
