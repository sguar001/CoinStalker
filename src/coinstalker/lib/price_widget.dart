import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'database.dart';
import 'session.dart';

/// Builds a widget displaying the given price in the given display symbol
Widget priceWidget(String toSymbol, num price, {bool exact = false}) {
  final formatted =
      NumberFormat.simpleCurrency(locale: Intl.systemLocale, name: toSymbol)
          .format(price);
  return Text(exact ? '$formatted ($price)' : formatted);
}

/// Builds a widget containing the quote price of the given symbol in the user's
/// chosen display symbol
Widget currentPriceWidget(String fromSymbol, {bool exact = false}) =>
    streamWidget(
      stream:
          Profile.buildStream(Session().profileRef).map((x) => x.displaySymbol),
      waitBuilder: emptyWaitBuilder,
      builder: (context, toSymbol) => futureWidget(
            future: CryptoCompare().price(fromSymbol, toSymbol),
            waitBuilder: emptyWaitBuilder,
            builder: (context, price) =>
                priceWidget(toSymbol, price, exact: exact),
          ),
    );
