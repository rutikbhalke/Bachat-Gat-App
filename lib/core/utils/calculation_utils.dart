import 'package:intl/intl.dart';

class CalculationUtils {
  CalculationUtils._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _detailedCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount, {bool showDecimals = false}) {
    if (showDecimals && amount % 1 != 0) {
      return _detailedCurrencyFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  /// Calculates monthly interest on the outstanding principal.
  /// Default rate is 2.0% per month as per Bachat-Gat rules.
  static double calculateMonthlyInterest({
    required double outstandingPrincipal,
    double annualRate = 2.0,
  }) {
    if (outstandingPrincipal <= 0 || annualRate <= 0) return 0.0;
    return (outstandingPrincipal * annualRate) / 100.0;
  }

  /// Calculates total payment for a monthly transaction.
  /// Total = Regular Hafta + Loan Principal Repaid + Loan Interest Paid + Other
  static double calculateTotalPayment({
    required double regularHafta,
    double principalRepaid = 0.0,
    double interestPaid = 0.0,
    double other = 0.0,
  }) {
    return regularHafta + principalRepaid + interestPaid + other;
  }

  /// Calculates remaining principal after payment.
  static double calculateRemainingPrincipal(double openingPrincipal, double principalRepaid) {
    final remaining = openingPrincipal - principalRepaid;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Calculates pending hafta.
  static double calculatePendingHafta(double expectedHafta, double paidHafta) {
    final pending = expectedHafta - paidHafta;
    return pending > 0 ? pending : 0.0;
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(date);
  }

  static String getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2026, month));
  }
}
