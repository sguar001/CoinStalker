import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User profile document
/// This class represents the Firestore documents 'profiles/$userId'
class Profile {
  /// Gets a reference to the profile document for a given user
  static DocumentReference buildReference(FirebaseUser user) =>
      Firestore.instance.document('profiles/${user.uid}');

  /// Builds a stream for the given user profile reference
  static Stream<Profile> buildStream(DocumentReference reference) =>
      reference.snapshots().map((snapshot) => Profile.fromSnapshot(snapshot));

  /// Reference to the storing document
  final DocumentReference reference;

  /// Preferred symbol to display exchange rates in
  final String displaySymbol;

  /// List of tracked symbols
  final List<String> trackedSymbols;

  /// Constructs this document instance
  Profile({this.reference, this.displaySymbol, this.trackedSymbols});

  /// Constructs this document instance from a map and optional reference
  Profile.fromMap(Map<String, dynamic> map, {this.reference})
      : displaySymbol = map['displaySymbol'],
        trackedSymbols = map['trackedSymbols'].cast<String>();

  /// Constructs this document instance from a snapshot
  Profile.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  /// Converts this document instance to a map
  toMap() => <String, dynamic>{
        'displaySymbol': displaySymbol,
        'trackedSymbols': trackedSymbols.cast<dynamic>()
      };
}
