import 'package:flutter/material.dart';

class Either extends StatelessWidget {
  final bool isLeftChild;
  final Widget leftChild;
  final Widget rightChild;

  Either(
      {@required this.isLeftChild,
      @required this.leftChild,
      @required this.rightChild});

  @override
  Widget build(BuildContext context) => isLeftChild ? leftChild : rightChild;
}

class MinimalEmptyFallback extends Either {
  final bool isFallback;
  final Widget child;

  MinimalEmptyFallback({@required this.isFallback, @required this.child})
      : super(
          isLeftChild: isFallback,
          leftChild: Container(width: 0.0, height: 0.0),
          rightChild: child,
        );
}

class MaximalEmptyFallback extends Either {
  final bool isFallback;
  final Widget child;

  MaximalEmptyFallback({@required this.isFallback, @required this.child})
      : super(
          isLeftChild: isFallback,
          leftChild: Container(),
          rightChild: child,
        );
}

class CircularProgressFallback extends Either {
  final bool isFallback;
  final Widget child;

  CircularProgressFallback({@required this.isFallback, @required this.child})
      : super(
          isLeftChild: isFallback,
          leftChild: Center(child: CircularProgressIndicator()),
          rightChild: child,
        );
}

class EitherBuilder extends StatelessWidget {
  final bool isLeftChild;
  final WidgetBuilder leftBuilder;
  final WidgetBuilder rightBuilder;

  EitherBuilder(
      {@required this.isLeftChild,
      @required this.leftBuilder,
      @required this.rightBuilder});

  @override
  Widget build(BuildContext context) =>
      isLeftChild ? leftBuilder(context) : rightBuilder(context);
}

class MinimalEmptyFallbackBuilder extends EitherBuilder {
  final bool isFallback;
  final WidgetBuilder builder;

  MinimalEmptyFallbackBuilder(
      {@required this.isFallback, @required this.builder})
      : super(
          isLeftChild: isFallback,
          leftBuilder: (_) => Container(width: 0.0, height: 0.0),
          rightBuilder: builder,
        );
}

class MaximalEmptyFallbackBuilder extends EitherBuilder {
  final bool isFallback;
  final WidgetBuilder builder;

  MaximalEmptyFallbackBuilder(
      {@required this.isFallback, @required this.builder})
      : super(
          isLeftChild: isFallback,
          leftBuilder: (_) => Container(),
          rightBuilder: builder,
        );
}

class CircularProgressFallbackBuilder extends EitherBuilder {
  final bool isFallback;
  final WidgetBuilder builder;

  CircularProgressFallbackBuilder(
      {@required this.isFallback, @required this.builder})
      : super(
          isLeftChild: isFallback,
          leftBuilder: (_) => Center(child: CircularProgressIndicator()),
          rightBuilder: builder,
        );
}
