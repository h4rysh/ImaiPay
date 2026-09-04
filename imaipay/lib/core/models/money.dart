import 'package:intl/intl.dart';

class Money {
  final int paise;

  const Money({required this.paise});

  factory Money.fromRupees(double rupees) {
    return Money(paise: (rupees * 100).round());
  }

  double get rupees => paise / 100;

  String get formatted {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return format.format(rupees);
  }

  String get formattedWithoutDecimals {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(rupees);
  }
}
