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

  /// Constructs a class instance
  Session._({@required this.user, @required this.coins})
      : profileRef = Profile.buildReference(user);

  /// Initializes the session for a signed-in user
  static void initialize({@required user, @required coins}) =>
      _instance = Session._(user: user, coins: coins);

  /// Resets the session to a null instance
  static Session reset() => _instance = null;
}
