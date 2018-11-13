import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'async_widget.dart';
import 'cryptocompare.dart';
import 'database.dart';
import 'session.dart';

Widget currentPriceWidget(String fromSymbol) => streamWidget(
    stream:
        Profile.buildStream(Session().profileRef).map((x) => x.displaySymbol),
    waitBuilder: emptyWaitBuilder,
    builder: (context, toSymbol) => futureWidget(
        future: CryptoCompare().price(fromSymbol, toSymbol),
        waitBuilder: emptyWaitBuilder,
        builder: (context, price) => Text(NumberFormat.simpleCurrency(
                locale: Intl.systemLocale, name: toSymbol)
            .format(price))));
