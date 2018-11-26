import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'cryptocompare.dart';

class OhlcvGraphStyle {
  final int candlestickFlex;
  final int separatorFlex;
  final int volumeFlex;

  final double barSpacing;

  // Candle fill
  final Color candleDecreaseColor;
  final Color candleIncreaseColor;

  // Volume fill
  final Color volumeFromColor;
  final Color volumeToColor;

  // Wick
  final double wickWidth;

  // Bar stroke
  final double strokeWidth;
  final Color strokeColor;

  // Axes
  final double axisPadding;
  final TextStyle labelStyle;
  final double gridWidth;
  final Color gridColor;

  const OhlcvGraphStyle({
    this.candlestickFlex = 16,
    this.separatorFlex = 2,
    this.volumeFlex = 6,
    this.barSpacing = 2.0,
    this.candleDecreaseColor = Colors.red,
    this.candleIncreaseColor = Colors.green,
    this.wickWidth = 1.0,
    this.volumeFromColor = Colors.yellow,
    this.volumeToColor = Colors.blue,
    this.strokeWidth = 1.0,
    this.strokeColor = Colors.grey,
    this.labelStyle = const TextStyle(color: Colors.black, fontSize: 11.0),
    this.axisPadding = 4.0,
    this.gridWidth = 1.0,
    this.gridColor = Colors.black12,
  });

  int get totalFlex => candlestickFlex + separatorFlex + volumeFlex;

  Paint get candleDecreasePaint => Paint()
    ..color = candleDecreaseColor
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.fill;
  Paint get candleIncreasePaint => Paint()
    ..color = candleIncreaseColor
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.fill;

  Paint get volumeFromPaint => Paint()
    ..color = volumeFromColor
    ..style = PaintingStyle.fill;
  Paint get volumeToPaint => Paint()
    ..color = volumeToColor
    ..style = PaintingStyle.fill;

  Paint get strokePaint => Paint()
    ..color = strokeColor
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..blendMode = BlendMode.luminosity;

  Paint get gridPaint => Paint()
    ..color = gridColor
    ..strokeWidth = gridWidth
    ..style = PaintingStyle.fill;
}

class OhlcvExtents {
  double _minPrice = double.infinity;
  double _maxPrice = -double.infinity;
  double _maxVolume = -double.infinity;

  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  double get maxVolume => _maxVolume;

  OhlcvExtents(List<Ohlcv> data) {
    for (var datum in data) {
      _minPrice = min(_minPrice, datum.low.toDouble());
      _maxPrice = max(_maxPrice, datum.high.toDouble());
      _maxVolume = max(_maxVolume, datum.volumeFrom.toDouble());
      _maxVolume = max(_maxVolume, datum.volumeTo.toDouble());
    }
  }
}

class OhlcvGraph extends StatelessWidget {
  final List<Ohlcv> data;
  final String symbol;
  final OhlcvGraphStyle style;
  final Duration xAxisInterval;

  final OhlcvExtents dataExtents;

  OhlcvGraph({
    @required this.symbol,
    @required this.data,
    @required this.xAxisInterval,
    this.style = const OhlcvGraphStyle(),
  }) : dataExtents = OhlcvExtents(data);

  @override
  Widget build(BuildContext context) {
    final xAxis = _TimeAxis(
      size: MediaQuery.of(context).size.width,
      labelFormatter: (x) => x.toString(),
      labelStyle: style.labelStyle,
      labelAlign: TextAlign.right,
      minimum: data.first.time,
      maximum: data.last.time,
      interval: xAxisInterval,
    );

    // Disable the volume chart when it is empty or when requested
    if (style.volumeFlex == 0 || dataExtents.maxVolume == 0) {
      return CustomPaint(
        child: Container(),
        painter: _CandlestickPainter(this, xAxis),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: CustomPaint(
            child: Container(),
            painter: _CandlestickPainter(this, xAxis),
          ),
          flex: style.candlestickFlex,
        ),
        Expanded(
          child: Container(),
          flex: style.separatorFlex,
        ),
        Expanded(
          child: CustomPaint(
            child: Container(),
            painter: _VolumePainter(this, xAxis),
          ),
          flex: style.volumeFlex,
        ),
      ],
    );
  }
}

class InteractiveOhlcvGraph extends StatefulWidget {
  final List<Ohlcv> data;
  final String symbol;
  final OhlcvGraphStyle style;
  final Duration xAxisInterval;

  InteractiveOhlcvGraph({
    @required this.symbol,
    @required this.data,
    @required this.xAxisInterval,
    this.style = const OhlcvGraphStyle(),
  });

  @override
  createState() => _InteractiveOhlcvGraphState();
}

class _InteractiveOhlcvGraphState extends State<InteractiveOhlcvGraph> {
  @override
  Widget build(BuildContext context) => GestureDetector(
        child: OhlcvGraph(
          data: widget.data,
          symbol: widget.symbol,
          style: widget.style,
          xAxisInterval: widget.xAxisInterval,
        ),
      );
}

class OhlcvPage extends StatelessWidget {
  final String title;
  final List<Ohlcv> data;
  final String symbol;
  final OhlcvGraphStyle style;
  final Duration xAxisInterval;

  OhlcvPage({
    @required this.title,
    @required this.data,
    @required this.symbol,
    @required this.xAxisInterval,
    this.style = const OhlcvGraphStyle(),
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InteractiveOhlcvGraph(
            data: data,
            symbol: symbol,
            style: style,
            xAxisInterval: xAxisInterval,
          ),
        ),
      );
}

typedef String _LabelFormatter<T>(T value);

class _RealAxisLine {
  final double value;
  final TextPainter label;

  _RealAxisLine({
    @required this.value,
    @required this.label,
  });
}

class _RealAxis {
  final double size;
  final _LabelFormatter<double> labelFormatter;
  final TextStyle labelStyle;
  final TextAlign labelAlign;
  final double minimum;
  final double maximum;
  final double interval;

  List<_RealAxisLine> _lines = [];
  List<_RealAxisLine> get lines => _lines;

  _RealAxis({
    @required this.size,
    @required this.labelFormatter,
    @required this.labelStyle,
    @required this.labelAlign,
    @required this.minimum,
    @required this.maximum,
    @required this.interval,
  }) {
    final range = maximum - minimum;
    for (var i = 0; i <= (range / interval).ceil(); i++) {
      final value = i * interval + minimum;
      final label = TextPainter(
        text: TextSpan(
          text: labelFormatter(value),
          style: labelStyle,
        ),
        textAlign: labelAlign,
        textDirection: TextDirection.ltr,
      );
      label.layout();
      _lines.add(_RealAxisLine(value: value, label: label));
    }
  }

  void paintHorizontalLines(Canvas canvas, Size size, Offset offset,
      {@required Paint linePaint}) {
    final range = maximum - minimum;
    final scale = size.height / range;
    for (var i in lines) {
      final y = max(0, size.height - (i.value - minimum) * scale);
      canvas.drawLine(Offset(offset.dx, offset.dy + y),
          Offset(size.width, offset.dy + y), linePaint);
    }
  }

  void paintHorizontalLabels(Canvas canvas, Size size, Offset offset) {
    final range = maximum - minimum;
    final scale = size.height / range;
    Rect lastLabelRect;
    for (var i in lines) {
      final y = max(0, size.height - (i.value - minimum) * scale);

      final labelOffset = Offset(offset.dx, offset.dy + y - i.label.height);
      final labelRect = Rect.fromLTWH(
          labelOffset.dx, labelOffset.dy, i.label.width, i.label.height);
      if (labelOffset.dy >= offset.dy &&
          (lastLabelRect == null || !labelRect.overlaps(lastLabelRect))) {
        i.label.paint(canvas, labelOffset);
        lastLabelRect = labelRect;
      }
    }
  }
}

class _TimeAxisLine {
  final DateTime value;
  final TextPainter label;

  _TimeAxisLine({
    @required this.value,
    @required this.label,
  });
}

class _TimeAxis {
  final double size;
  final _LabelFormatter<DateTime> labelFormatter;
  final TextStyle labelStyle;
  final TextAlign labelAlign;
  final DateTime minimum;
  final DateTime maximum;
  final Duration interval;

  List<_TimeAxisLine> _lines = [];
  List<_TimeAxisLine> get lines => _lines;

  _TimeAxis({
    @required this.size,
    @required this.labelFormatter,
    @required this.labelStyle,
    @required this.labelAlign,
    @required this.minimum,
    @required this.maximum,
    @required this.interval,
  }) {
    final range = maximum.difference(minimum);
    for (var i = 0;
        i <= (range.inMilliseconds / interval.inMilliseconds).ceil();
        i++) {
      final value =
          minimum.add(Duration(milliseconds: i * interval.inMilliseconds));
      final label = TextPainter(
        text: TextSpan(
          text: labelFormatter(value),
          style: labelStyle,
        ),
        textAlign: labelAlign,
        textDirection: TextDirection.ltr,
      );
      label.layout();
      _lines.add(_TimeAxisLine(value: value, label: label));
    }
  }

  void paintVerticalLines(Canvas canvas, Size size, Offset offset,
      {@required Paint linePaint}) {
    final range = maximum.difference(minimum);
    final scale = size.width / range.inMilliseconds;
    for (var i in lines) {
      final x = i.value.difference(minimum).inMilliseconds * scale;
      canvas.drawLine(Offset(offset.dx + x, offset.dy),
          Offset(offset.dx + x, size.height), linePaint);
    }
  }
}

abstract class _OhlcvPainter extends CustomPainter {
  final OhlcvGraph widget;
  OhlcvGraphStyle get style => widget.style;
  _LabelFormatter get priceLabelFormatter =>
      (x) => intl.NumberFormat.simpleCurrency(
              locale: intl.Intl.systemLocale, name: widget.symbol)
          .format(x);

  _OhlcvPainter(this.widget);

  @override
  bool shouldRepaint(_OhlcvPainter oldDelegate) =>
      widget.symbol != oldDelegate.widget.symbol ||
      widget.data != oldDelegate.widget.data ||
      style != oldDelegate.style;
}

class _CandlestickPainter extends _OhlcvPainter {
  final _TimeAxis xAxis;

  _CandlestickPainter(OhlcvGraph widget, this.xAxis) : super(widget);

  @override
  void paint(Canvas canvas, Size size) {
    final yInterval = pow(
            10,
            (log(widget.dataExtents.maxPrice - widget.dataExtents.minPrice) /
                        log(10))
                    .ceil() -
                1)
        .toDouble();
    final yMinimum =
        (widget.dataExtents.minPrice / yInterval).floorToDouble() * yInterval;
    final yMaximum =
        (widget.dataExtents.maxPrice / yInterval).ceilToDouble() * yInterval;
    final yRange = yMaximum - yMinimum;
    final yAxis = _RealAxis(
      size: size.height,
      labelFormatter: priceLabelFormatter,
      labelStyle: style.labelStyle,
      labelAlign: TextAlign.right,
      minimum: yMinimum,
      maximum: yMaximum,
      interval: yInterval * (style.volumeFlex / style.candlestickFlex),
    );

    xAxis.paintVerticalLines(canvas, size, Offset.zero,
        linePaint: style.gridPaint);
    yAxis.paintHorizontalLines(canvas, size, Offset.zero,
        linePaint: style.gridPaint);

    final barWidth = size.width / widget.data.length;
    final heightScale = size.height / yRange;

    for (var i = 0; i < widget.data.length; i++) {
      final datum = widget.data[i];

      double candleTop;
      double candleBottom;
      Paint candlePaint;
      if (datum.open > datum.close) {
        candleTop = datum.open.toDouble();
        candleBottom = datum.close.toDouble();
        candlePaint = style.candleDecreasePaint;
      } else {
        candleTop = datum.close.toDouble();
        candleBottom = datum.open.toDouble();
        candlePaint = style.candleIncreasePaint;
      }
      final candleRect = Rect.fromLTRB(
        i * barWidth + style.barSpacing / 2,
        size.height - (candleTop - yMinimum) * heightScale,
        (i + 1) * barWidth - style.barSpacing / 2,
        size.height - (candleBottom - yMinimum) * heightScale,
      );
      canvas.drawRect(candleRect, candlePaint);
      canvas.drawRect(candleRect, style.strokePaint);

      final candleMiddle = (candleRect.right + candleRect.left) / 2;
      canvas.drawLine(
          Offset(candleMiddle, candleRect.top),
          Offset(candleMiddle,
              size.height - (datum.high.toDouble() - yMinimum) * heightScale),
          candlePaint);
      canvas.drawLine(
          Offset(candleMiddle, candleRect.bottom),
          Offset(candleMiddle,
              size.height - (datum.low.toDouble() - yMinimum) * heightScale),
          candlePaint);
    }

    yAxis.paintHorizontalLabels(canvas, size, Offset.zero);
  }
}

class _VolumePainter extends _OhlcvPainter {
  final _TimeAxis xAxis;

  _VolumePainter(OhlcvGraph widget, this.xAxis) : super(widget);

  @override
  void paint(Canvas canvas, Size size) {
    final yInterval =
        pow(10, (log(widget.dataExtents.maxVolume) / log(10)).ceil() - 1)
            .toDouble();
    final yMinimum = 0.0;
    final yMaximum =
        (widget.dataExtents.maxVolume / yInterval).ceilToDouble() * yInterval;
    final yRange = yMaximum - yMinimum;
    final yAxis = _RealAxis(
      size: size.height,
      labelFormatter: priceLabelFormatter,
      labelStyle: style.labelStyle,
      labelAlign: TextAlign.right,
      minimum: yMinimum,
      maximum: yMaximum,
      interval: yInterval / (style.volumeFlex / style.candlestickFlex),
    );

    xAxis.paintVerticalLines(canvas, size, Offset.zero,
        linePaint: style.gridPaint);
    yAxis.paintHorizontalLines(canvas, size, Offset.zero,
        linePaint: style.gridPaint);

    final barWidth = size.width / widget.data.length;
    final heightScale = size.height / yRange;

    for (var i = 0; i < widget.data.length; i++) {
      final datum = widget.data[i];

      final fromRect = Rect.fromLTRB(
        i * barWidth + style.barSpacing / 2,
        size.height - datum.volumeFrom.toDouble() * heightScale,
        (i + 1) * barWidth - style.barSpacing / 2,
        size.height,
      );
      final toRect = Rect.fromLTRB(
        i * barWidth + style.barSpacing / 2,
        size.height - datum.volumeTo.toDouble() * heightScale,
        (i + 1) * barWidth - style.barSpacing / 2,
        size.height,
      );

      if (datum.volumeFrom > datum.volumeTo) {
        canvas.drawRect(fromRect, style.volumeFromPaint);
        canvas.drawRect(toRect, style.volumeToPaint);
        canvas.drawRect(fromRect, style.strokePaint);
      } else {
        canvas.drawRect(toRect, style.volumeToPaint);
        canvas.drawRect(fromRect, style.volumeFromPaint);
        canvas.drawRect(toRect, style.strokePaint);
      }
    }

    yAxis.paintHorizontalLabels(canvas, size, Offset.zero);
  }
}
