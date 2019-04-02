import 'package:flutter/material.dart';

/// Builds an opaque modal barrier
Widget _buildModalBarrier() => Opacity(
      opacity: 0.25,
      child: const ModalBarrier(
        dismissible: false,
        color: Colors.grey,
      ),
    );

/// Builds a circular progress indicator
Widget _buildCircularProgressIndicator() => Center(
      child: CircularProgressIndicator(),
    );

/// Builds a stack that displays a blocking circular progress indicator while
/// awaiting a future
Widget buildModalCircularProgressStack(
        {@required Future future, @required Widget child}) =>
    FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        var children = <Widget>[child];
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.done:
            break;

          case ConnectionState.active:
          case ConnectionState.waiting:
            children.add(_buildModalBarrier());
            children.add(_buildCircularProgressIndicator());
            break;
        }
        return Stack(children: children);
      },
    );
