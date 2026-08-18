import 'package:intl/intl.dart';
import '../../models/loan.dart';
import '../../models/monthly_contribution.dart';
import '../../models/loan_repayment.dart';

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

  /// Calculates actual available fund for lending:
  /// Available Fund = max(0, Total Savings - Active Outstanding Principal)
  static double calculateAvailableFund({
    required double totalSavings,
    required double outstandingLoans,
  }) {
    final validLoans = outstandingLoans > 0 ? outstandingLoans : 0.0;
    final available = totalSavings - validLoans;
    return available > 0 ? available : 0.0;
  }

  /// Checks whether there is a data inconsistency where Active Loans exceed Total Savings.
  static bool hasFundInconsistency({
    required double totalSavings,
    required double outstandingLoans,
  }) {
    return outstandingLoans > totalSavings;
  }

  /// Calculates actual available cash balance for the group (never negative).
  static double calculateAvailableCash(double cashBalance) {
    return cashBalance > 0 ? cashBalance : 0.0;
  }

  /// Calculates Total Group Fund (Total Assets / Worth) = Available Cash + Active Outstanding Loans.
  /// In Bachat-Gat accounting, total group worth consists of liquid funds in the bank/box
  /// plus all outstanding principal owed to the group by members.
  static double calculateTotalGroupFund({
    required double availableCash,
    required double outstandingLoans,
  }) {
    final validCash = calculateAvailableCash(availableCash);
    final validLoans = outstandingLoans > 0 ? outstandingLoans : 0.0;
    return validCash + validLoans;
  }

  /// Calculates total active loan outstanding principal from a list of loans.
  static double calculateActiveLoansOutstanding(List<Loan> loans) {
    return loans
        .where((l) => l.status == LoanStatus.active && l.pendingPrincipal > 0)
        .fold<double>(0.0, (total, l) => total + l.pendingPrincipal);
  }

  /// Calculates total regular savings collected from monthly contributions.
  static double calculateTotalSavings(List<MonthlyContribution> contributions) {
    return contributions.fold<double>(0.0, (total, c) => total + c.regularHaftaAmount);
  }

  /// Calculates total interest collected from loan repayments.
  static double calculateTotalInterestCollected(List<LoanRepayment> repayments) {
    return repayments.fold<double>(0.0, (total, r) => total + r.interestAmount);
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

  static const _marathiMonths = [
    'जानेवारी',
    'फेब्रुवारी',
    'मार्च',
    'एप्रिल',
    'मे',
    'जून',
    'जुलै',
    'ऑगस्ट',
    'सप्टेंबर',
    'ऑक्टोबर',
    'नोव्हेंबर',
    'डिसेंबर'
  ];

  static String getMonthNameMarathi(int month) {
    if (month >= 1 && month <= 12) {
      return _marathiMonths[month - 1];
    }
    return getMonthName(month);
  }

  static const Map<String, String> _monthEnglishToMarathi = {
    'January': 'जानेवारी',
    'February': 'फेब्रुवारी',
    'March': 'मार्च',
    'April': 'एप्रिल',
    'May': 'मे',
    'June': 'जून',
    'July': 'जुलै',
    'August': 'ऑगस्ट',
    'September': 'सप्टेंबर',
    'October': 'ऑक्टोबर',
    'November': 'नोव्हेंबर',
    'December': 'डिसेंबर',
    'Jan': 'जानेवारी',
    'Feb': 'फेब्रुवारी',
    'Mar': 'मार्च',
    'Apr': 'एप्रिल',
    'Jun': 'जून',
    'Jul': 'जुलै',
    'Aug': 'ऑगस्ट',
    'Sep': 'सप्टेंबर',
    'Oct': 'ऑक्टोबर',
    'Nov': 'नोव्हेंबर',
    'Dec': 'डिसेंबर',
  };

  /// Localizes user-facing transaction description strings according to locale.
  /// Preserves member names, amounts, numbers, and database values.
  static String localizeTransactionDescription(String? description, {required bool isMarathi}) {
    if (description == null || description.isEmpty) {
      return '';
    }
    if (!isMarathi) {
      return description;
    }

    String result = description;

    // 1. Replace activity title prefixes
    if (result.startsWith('Monthly Contribution')) {
      result = result.replaceFirst('Monthly Contribution', 'मासिक बचत');
    } else if (result.startsWith('Monthly Payment')) {
      result = result.replaceFirst('Monthly Payment', 'मासिक भरणा');
    } else if (result.startsWith('Loan Repayment')) {
      result = result.replaceFirst('Loan Repayment', 'परतफेड');
    } else if (result.startsWith('Repayment')) {
      result = result.replaceFirst('Repayment', 'परतफेड');
    } else if (result.startsWith('Loan Issued')) {
      result = result.replaceFirst('Loan Issued', 'कर्ज दिले');
    } else if (result.startsWith('Loan Disbursed')) {
      result = result.replaceFirst('Loan Disbursed', 'कर्ज दिले');
    } else if (result.startsWith('Member added')) {
      result = result.replaceFirst('Member added', 'नवीन सभासद जोडला');
    } else if (result.startsWith('Member updated')) {
      result = result.replaceFirst('Member updated', 'सभासद माहिती अद्यतनित');
    } else if (result.startsWith('Member deactivated')) {
      result = result.replaceFirst('Member deactivated', 'सभासद निष्क्रिय');
    } else if (result.startsWith('Reversed payment for')) {
      result = result.replaceFirst('Reversed payment for', 'भरणा रद्द');
    } else if (result == 'loanIssue' || result == 'loanDisbursement') {
      return 'कर्ज दिले';
    } else if (result == 'monthlyInvestment') {
      return 'मासिक बचत';
    } else if (result == 'loanRepayment') {
      return 'परतफेड';
    }

    // 2. Replace breakdown labels inside description
    result = result.replaceAll('Hafta:', 'हप्ता:');
    result = result.replaceAll('Interest:', 'व्याज:');
    result = result.replaceAll('Principal:', 'मुद्दल:');
    result = result.replaceAll(' to ', ' - ');

    // 3. Translate month names from English to Marathi
    for (final entry in _monthEnglishToMarathi.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }
}
