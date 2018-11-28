import 'package:intl/intl.dart';

/// Represents the price of a coin, including symbol
class Price {
  /// The symbol in which the quote price was obtained
  String symbol;

  /// The quote price of the coin
  num price;

  /// Constructs this instance
  Price(this.symbol, this.price);

  /// Formats the price as a localized string
  String toString({bool exact = false}) {
    final formatted =
        NumberFormat.simpleCurrency(locale: Intl.systemLocale, name: symbol)
            .format(price);
    return exact ? '$formatted ($price)' : formatted;
  }
}
