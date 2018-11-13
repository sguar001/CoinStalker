import 'dart:math';

import 'package:flutter/material.dart';

import 'cryptocompare.dart';

class OhlcvGraph extends StatelessWidget {
  final String priceSymbol;
  final List<Ohlcv> data;
  final double barSpacing;
  final double lineWidth;
  final Color decreaseColor;
  final Color increaseColor;
  final Color lineColor;
  final double volumeRatio;
  final Color volumeFromColor;
  final Color volumeToColor;

  OhlcvGraph(
      {@required this.priceSymbol,
      @required this.data,
      this.barSpacing = 3.0,
      this.lineWidth = 1.0,
      this.decreaseColor = Colors.red,
      this.increaseColor = Colors.green,
      this.lineColor = Colors.grey,
      this.volumeRatio = 0.2,
      this.volumeFromColor = Colors.yellow,
      this.volumeToColor = Colors.blue});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _OhlcvPainter(this),
      );
}

class _OhlcvPainter extends CustomPainter {
  final OhlcvGraph widget;

  double _min;
  double _max;
  double _maxV;

  _OhlcvPainter(this.widget);

  void _update() {
    _min = double.infinity;
    _max = -double.infinity;
    _maxV = -double.infinity;

    for (var datum in widget.data) {
      _min = min(_min, datum.low.toDouble());
      _max = max(_max, datum.high.toDouble());
      _maxV = max(_maxV, datum.volumeFrom.toDouble());
      _maxV = max(_maxV, datum.volumeTo.toDouble());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_min == null || _max == null || _maxV == null) _update();
    if (_max - _min == 0) return;

    final barWidth = size.width / widget.data.length;

    final candleSize = Size(
        size.width, size.height * (1 - (_maxV > 0 ? widget.volumeRatio : 0)));
    final candleScale = candleSize.height / (_max - _min);

    for (var i = 0; i < widget.data.length; i++) {
      final datum = widget.data[i];

      // Candle
      double candleTop;
      double candleBottom;
      Color candleColor;
      if (datum.open > datum.close) {
        candleTop = datum.open.toDouble();
        candleBottom = datum.close.toDouble();
        candleColor = widget.decreaseColor;
      } else {
        candleTop = datum.close.toDouble();
        candleBottom = datum.open.toDouble();
        candleColor = widget.increaseColor;
      }
      final candleRect = Rect.fromLTRB(
        i * barWidth + widget.barSpacing / 2,
        candleSize.height - (candleTop - _min) * candleScale,
        (i + 1) * barWidth - widget.barSpacing / 2,
        candleSize.height - (candleBottom - _min) * candleScale,
      );
      canvas.drawRect(
          candleRect,
          Paint()
            ..color = candleColor
            ..strokeWidth = widget.lineWidth
            ..style = PaintingStyle.fill);
      canvas.drawRect(
          candleRect,
          Paint()
            ..color = widget.lineColor
            ..strokeWidth = widget.lineWidth
            ..style = PaintingStyle.stroke);

      // Wick
      final candleMiddle = (candleRect.right + candleRect.left) / 2;
      canvas.drawLine(
          Offset(candleMiddle, candleRect.top),
          Offset(candleMiddle,
              candleSize.height - (datum.high.toDouble() - _min) * candleScale),
          Paint()
            ..color = widget.lineColor
            ..strokeWidth = widget.lineWidth);
      canvas.drawLine(
          Offset(candleMiddle, candleRect.bottom),
          Offset(candleMiddle,
              candleSize.height - (datum.low.toDouble() - _min) * candleScale),
          Paint()
            ..color = widget.lineColor
            ..strokeWidth = widget.lineWidth);

      // Volume
      if (_maxV > 0) {
        final volumeSize = Size(size.width, size.height * widget.volumeRatio);
        final volumeScale = volumeSize.height / _maxV;

        final fromRect = Rect.fromLTRB(
          i * barWidth + widget.barSpacing / 2,
          candleSize.height +
              volumeSize.height -
              datum.volumeFrom.toDouble() * volumeScale,
          (i + 1) * barWidth - widget.barSpacing / 2,
          size.height,
        );
        final toRect = Rect.fromLTRB(
          i * barWidth + widget.barSpacing / 2,
          candleSize.height +
              volumeSize.height -
              datum.volumeTo.toDouble() * volumeScale,
          (i + 1) * barWidth - widget.barSpacing / 2,
          size.height,
        );
        if (datum.volumeFrom > datum.volumeTo) {
          canvas.drawRect(
              fromRect,
              Paint()
                ..color = widget.volumeFromColor
                ..strokeWidth = widget.lineWidth
                ..style = PaintingStyle.fill);
          canvas.drawRect(
              toRect,
              Paint()
                ..color = widget.volumeToColor
                ..strokeWidth = widget.lineWidth
                ..style = PaintingStyle.fill);
          canvas.drawRect(
              fromRect,
              Paint()
                ..color = widget.lineColor
                ..strokeWidth = widget.lineWidth
                ..style = PaintingStyle.stroke);
        } else {
          canvas.drawRect(
              toRect,
              Paint()
                ..color = widget.volumeToColor
                ..strokeWidth = widget.lineWidth
                ..style = PaintingStyle.fill);
          canvas.drawRect(
              fromRect,
              Paint()
                ..color = widget.volumeFromColor
                ..strokeWidth = widget.lineWidth
                ..style = PaintingStyle.fill);
          canvas.drawRect(
              toRect,
              Paint()
                ..color = widget.lineColor
                ..strokeWidth = widget.lineWidth
                ..style = PaintingStyle.stroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_OhlcvPainter oldDelegate) =>
      widget.priceSymbol != oldDelegate.widget.priceSymbol ||
      widget.data != oldDelegate.widget.data ||
      widget.barSpacing != oldDelegate.widget.barSpacing ||
      widget.lineWidth != oldDelegate.widget.lineWidth ||
      widget.decreaseColor != oldDelegate.widget.decreaseColor ||
      widget.increaseColor != oldDelegate.widget.increaseColor ||
      widget.lineColor != oldDelegate.widget.lineColor ||
      widget.volumeRatio != oldDelegate.widget.volumeRatio ||
      widget.volumeFromColor != oldDelegate.widget.volumeFromColor ||
      widget.volumeToColor != oldDelegate.widget.volumeToColor;
}
