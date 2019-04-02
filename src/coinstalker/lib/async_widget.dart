import 'package:flutter/material.dart';

typedef Widget ErrorBuilder(BuildContext context, dynamic error);
typedef Widget WaitBuilder(BuildContext context);
typedef Widget DataBuilder<T>(BuildContext context, T data);

/// The default error builder for async widgets
/// Displays a centered, red error icon
Widget defaultErrorBuilder(BuildContext context, dynamic error) {
  print('$error'); // TODO: Error reporting
  return Center(child: Icon(Icons.error, color: Colors.red));
}

/// The default wait builder for async widgets
/// Displays a centered, circular progress indicator
Widget defaultWaitBuilder(BuildContext context) =>
    Center(child: CircularProgressIndicator());

/// The empty wait builder for async widgets
/// Displays a zero-size container
Widget emptyWaitBuilder(BuildContext context) =>
    Container(width: 0.0, height: 0.0);

/// Creates a stream builder widget with the given builder functions
Widget streamWidget<T>(
        {@required Stream<T> stream,
        ErrorBuilder errorBuilder = defaultErrorBuilder,
        WaitBuilder waitBuilder = defaultWaitBuilder,
        @required DataBuilder<T> builder}) =>
    StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return errorBuilder(context, snapshot.error);
        if (snapshot.hasData) return builder(context, snapshot.data);
        return waitBuilder(context);
      },
    );

/// Creates a future builder widget with the given builder functions
Widget futureWidget<T>(
        {@required Future<T> future,
        ErrorBuilder errorBuilder = defaultErrorBuilder,
        WaitBuilder waitBuilder = defaultWaitBuilder,
        @required DataBuilder<T> builder}) =>
    FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return errorBuilder(context, snapshot.error);
        if (snapshot.hasData) return builder(context, snapshot.data);
        return waitBuilder(context);
      },
    );
