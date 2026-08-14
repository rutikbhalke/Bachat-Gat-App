import 'package:intl/intl.dart';

class CalculationUtils {
  CalculationUtils._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  static double calculateMonthlyInterest({
    required double outstandingPrincipal,
    required double annualRate,
  }) {
    // Interest = Principal * Rate / 100
    // The requirement says 2% monthly, but usually rates are annual.
    // The user specified "2% monthly". So we use rate as monthly.
    return (outstandingPrincipal * annualRate) / 100;
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2026, month));
  }
}
