import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'database.dart';

/// Application-wide session information
class Session {
  /// Internal instance of the session
  static Session _instance;

  /// Returns the internal instance
  factory Session() => _instance;

  /// Currently authenticated user
  final FirebaseUser user;

  /// Reference to the user's profile document
  final DocumentReference profileRef;

  /// List of all coins
  final List<Coin> coins;

  /// Set of all supported fiat symbols
  final Set<String> fiatSymbols;

  /// Constructs a class instance
  Session._(
      {@required this.user, @required this.coins, @required this.fiatSymbols})
      : profileRef = Profile.buildReference(user);

  /// Initializes the session for a signed-in user
  static void initialize(
          {@required user, @required coins, @required fiatSymbols}) =>
      _instance = Session._(user: user, coins: coins, fiatSymbols: fiatSymbols);

  /// Resets the session to a null instance
  static Session reset() => _instance = null;
}
