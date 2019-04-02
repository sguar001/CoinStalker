import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'session.dart';
import 'async_widget.dart';

/// Widget for displaying the comments that users write
/// for a specific coin
class Comments extends StatefulWidget {
  /// The coin to display details for
  final int coinID;

  /// Declared here so it could be called from another class
  /// function add a comment to the database of comments
  /// Format is username: comment [timestamp]
  static void addComment(String textContent, int coinID) {
    _CommentsState._addComment(textContent, coinID);
  }

  /// Default Constructor that constructs the widget instance for the specified
  /// coin
  Comments({@required this.coinID});

  @override
  createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  @override
  Widget build(BuildContext context) {
    /// Simply return a container that holds the list of comments
    /// pertaining to a coin
    return Center(
      child: Container(
          padding: const EdgeInsets.all(8.0),

          /// need to retrieve array and then build for each item
          child: FutureBuilder(
              future: _buildUserComments(),

              /// return comments or placeholder
              builder: (BuildContext context, AsyncSnapshot<Widget> data) {
                /// Return container if state isn't done
                if (data.connectionState == ConnectionState.waiting)
                  return Container();
                else
                  return data.data;
              })),
    );
  }

  /// Creates a widget for the list of tracked coins
  Future<Widget> _buildUserComments() async {
    final coinID = widget.coinID;

    /// Get a reference to the comments for the specified coin
    final DocumentReference commentsRef = UserComments.buildReference(coinID);

    /// bool that holds check
    bool commentsExist;

    ///Check if a comment document exists
    await commentsRef.get().asStream().first.then((data) {
      commentsExist = data.exists;
    });

    /// Check to see if there are comments
    print(
        'There comments in the DB for this coin: ' + commentsExist.toString());

    /// if the document doesn't exist, there are no comments, so return a placeholder
    /// otherwise, return the comments
    Widget toReturn;
    if (commentsExist) {
      toReturn = _buildStreamComments(_userComments(commentsRef));
    } else {
      toReturn = Text(
        'Start Commenting!',
        style: TextStyle(color: Colors.grey),
      );
    }
    return toReturn;
  }

  /// Return the stream built from comments to the specified coin
  Stream<List<Map<String, dynamic>>> _userComments(
      DocumentReference commentsRef) {
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

  Widget _buildUserCommentsListView(List<Map<String, dynamic>> comments) {
    /// Read and display the comments
    return ListView.builder(
        itemCount: comments.length,
        itemBuilder: (context, int index) =>
            _buildCommentsRow(comments[index]));

    /// TODO: sort the comments here by post date?
  }

  /// Build a row for each comment in userComments array for the coin
  Widget _buildCommentsRow(Map<String, dynamic> commentEntry) {
    return ListTile(
      title: Text(commentEntry['author']),
      subtitle: Text(commentEntry['textContent']),
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: Text(commentEntry['timeStamp'])),
        ],
      ),
    );
  }

  /// function that actually adds the comment to the database
  static void _addComment(String text, int coinID) {
    print(text);

    /// get an instance of the current session
    final _session = Session();

    /// Get a reference to the comments for the specified coin
    final DocumentReference commentsRef = UserComments.buildReference(coinID);

    /// build the username from the user's email address (part before '@' symbol)
    final userName = _session.user.email == null
        ? 'anonymous'
        : _session.user.email.split('@')[0];

    final currentTime = DateTime.now();
    int currentHour;
    int currentMinute;
    String timePeriod;

    /// convert to 12hr format
    if (currentTime.hour >= 12) {
      if (currentTime.hour == 12) {
        currentHour = currentTime.hour;
      } else {
        currentHour = currentTime.hour - 12;
      }
      currentMinute = currentTime.minute;
      timePeriod = 'PM';
    } else if (currentTime.hour < 12) {
      if (currentTime.hour == 0) {
        currentHour = currentTime.hour + 12;
      } else {
        currentHour = currentTime.hour;
      }
      currentMinute = currentTime.minute;
      timePeriod = 'AM';
    }

    /// build the actual timestamp
    final timeStamp = currentTime.month.toString() +
        '-' +
        currentTime.day.toString() +
        ' ' +
        currentHour.toString() +
        ':' +
        (currentMinute < 10
            ? '0' + currentMinute.toString()
            : currentMinute.toString()) +
        ' ' +
        timePeriod;

    /// Create a new map to be pushed to database
    final newCommentMapping = Map<String, dynamic>();

    /// Build the map with author name, text, and timestamp
    newCommentMapping['author'] = userName;
    newCommentMapping['textContent'] = text;
    newCommentMapping['timeStamp'] = timeStamp;

    /// Push comment to database
    Firestore.instance.runTransaction((tx) async {
      commentsRef.updateData(<String, dynamic>{
        'userComments': FieldValue.arrayUnion([newCommentMapping]),
      }).catchError((onError) {
        /// If we encounter the error (NOT_FOUND) where
        /// the document was not found then create the document using setData
        if (onError.toString().contains('NOT_FOUND')) {
          Firestore.instance.runTransaction((tx) async {
            commentsRef.setData(<String, dynamic>{
              'userComments': FieldValue.arrayUnion([newCommentMapping]),
            });
          });
        }
      });
    });
  }
}
