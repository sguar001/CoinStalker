import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'cryptocompare.dart';
import 'database.dart';

/// Builds a button to display the tracked status of a coin
Widget buildTrackButton(Coin coin, DocumentReference profileRef) =>
    StreamBuilder(
      stream: Profile.buildStream(profileRef).map((x) => x.trackedSymbols),
      builder: (context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasError) {
          print('Error in buildTrackButton: ${snapshot.error}');
          return Icon(Icons.error, color: Colors.red);
        }
        if (!snapshot.hasData) {
          return Container(width: 0.0, height: 0.0);
        }

        if (snapshot.data.contains(coin.symbol)) {
          return IconButton(
            icon: Icon(Icons.favorite),
            color: Colors.red,
            onPressed: () {
              Firestore.instance.runTransaction((tx) async {
                profileRef.updateData(<String, dynamic>{
                  'trackedSymbols': FieldValue.arrayRemove([coin.symbol]),
                });
              });
            },
          );
        }

        return IconButton(
          icon: Icon(Icons.favorite_border),
          onPressed: () {
            Firestore.instance.runTransaction((tx) async {
              profileRef.updateData(<String, dynamic>{
                'trackedSymbols': FieldValue.arrayUnion([coin.symbol]),
              });
            });
          },
        );
      },
    );
