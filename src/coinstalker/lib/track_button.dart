import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'database.dart';

/// Builds a button to display the tracked status of a coin
Widget buildTrackButton(Coin coin, DocumentReference profileRef) =>
    streamWidget(
      stream: Profile.buildStream(profileRef).map((x) => x.trackedSymbols),
      waitBuilder: emptyWaitBuilder,
      builder: (context, data) {
        if (data.contains(coin.symbol)) {
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
