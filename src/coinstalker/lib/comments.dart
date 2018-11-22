import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'database.dart';
import 'session.dart';
import 'async_widget.dart';

/// Widget for displaying the comments that users write
/// for a specific coin
class Comments extends StatefulWidget {
  /// The coin to display details for
  final int coinID;

  /// Default Constructor that constructs the widget instance for the specified
  /// coin
  Comments({@required this.coinID});

  @override
  createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  /// get an instance of the current session
  final _session = Session();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Container(
        /// need to retrieve array and then build for each item
        child: _buildUserComments(),
      ),
    );
  }

//  /// Builds a widget for displaying the user name
//  Widget _buildAccountName() => _session.user.displayName == null
//      ? Container()
//      : Text(_session.user.displayName);
//
//  /// Builds a widget for displaying the user email address
//  Widget _buildAccountEmail() =>
//      _session.user.email == null ? Container() : Text(_session.user.email);

  /// Creates a widget for the list of tracked coins
  Widget _buildUserComments() => _buildStreamComments(_userComments());

  /// Return the stream built from comments to the specified coin
  Stream<List<Map<String, dynamic>>> _userComments() {
    /// Get a reference to the comments for the specified coin
    final DocumentReference commentsRef = UserComments.buildReference(5204);

    /// return the a stream user comments that belong to the specified coin
    return UserComments.buildStream(commentsRef)
        .map((comments) => comments.userComments);
  }

  /// Creates a stream builder widget for a list of coins
  /// While the list is being retrieved, a progress indicator is displayed
  Widget _buildStreamComments(Stream<List<Map<String, dynamic>>> stream) =>
      streamWidget(
        stream: stream,
        builder: (context, data) => _buildUserCommentsListView(data),
      );

  Widget _buildUserCommentsListView(List<Map<String, dynamic>> comments) =>
      ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, int index) =>
              _buildCommentsRow(comments[index]));
//      futureWidget(
//        /// TODO: sort the comments here by post date?
//          future: _coins?.then((m) => m.entries.toList())?.then((e) {
//            e.sort(_sort.comparator());
//            return e;
//          }),
//          builder: (context, List<MapEntry<Coin, _CoinPrice>> allEntries) {
//            final entries = allEntries
//                .where((entry) => allCoins.contains(entry.key))
//                .toList();
//            final coins = _appBarState == _AppBarState.search
//                ? _filterCoins(entries)
//                : entries;
//            return RefreshIndicator(
//              onRefresh: _refreshCoins,
//              child: ListView.builder(
//                itemCount: coins.length,
//                itemBuilder: (context, index) => _buildCoinRow(coins[index]),
//              ),
//            );
//          });

  /// Build a row for each comment in userComments array for the coin
  Widget _buildCommentsRow(Map<String, dynamic> commentEntry) {
    return ListTile(
      title: Text(commentEntry['author']),
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(commentEntry['textContent']),
          Text(commentEntry['timeStamp'])
        ],
      ),
    );
  }
}
