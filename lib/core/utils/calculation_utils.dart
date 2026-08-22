import 'package:intl/intl.dart';
import '../../models/member.dart';
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

  /// Calculates total monthly hafta for a member given their share count and contribution per share.
  static double calculateMemberMonthlyHafta({
    required int shares,
    required double contributionPerShare,
  }) {
    final validShares = shares >= 1 ? shares : 1;
    final validPerShare = (contributionPerShare.isFinite && contributionPerShare >= 0) ? contributionPerShare : 0.0;
    return validShares * validPerShare;
  }

  /// Validates whether a financial amount is finite, valid, and non-negative.
  static bool isValidFinancialAmount(double? amount) {
    if (amount == null) return false;
    return amount.isFinite && !amount.isNaN && amount >= 0;
  }

  /// Calculates actual available fund for lending:
  /// Formula: Available Group Balance = Total Savings + Actual Interest Received - Outstanding Loan Principal
  static double calculateAvailableFund({
    required double totalSavings,
    required double outstandingLoans,
    double totalInterest = 0.0,
    double? availableCash,
  }) {
    final validSavings = totalSavings > 0 ? totalSavings : 0.0;
    final validInterest = totalInterest > 0 ? totalInterest : 0.0;
    final validLoans = outstandingLoans > 0 ? outstandingLoans : 0.0;
    final available = (validSavings + validInterest) - validLoans;
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
    return (cashBalance.isFinite && cashBalance > 0) ? cashBalance : 0.0;
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
    return contributions.fold<double>(0.0, (total, c) => total + c.actualRegularPaid);
  }

  /// Calculates total interest collected from loan repayments.
  static double calculateTotalInterestCollected(List<LoanRepayment> repayments) {
    return repayments.fold<double>(0.0, (total, r) => total + r.interestAmount);
  }

  /// Calculates monthly savings progress target dynamically from active members:
  /// Target = activeMemberCount * 1000 (where every member represents exactly 1 share = ₹1,000).
  /// Normalizes members by omitting un-numbered duplicate base names.
  static double calculateMonthlySavingsTarget(
    List<Member> members, {
    double? perShareAmount,
    double? fallbackTarget,
  }) {
    final activeMembers = members.where((m) => m.status == MemberStatus.active).toList();
    if (activeMembers.isEmpty) {
      return 0.0;
    }
    final normalized = sortMembersByBaseNameAndSequence(activeMembers);
    final rate = (perShareAmount != null && perShareAmount > 0) ? perShareAmount : 1000.0;
    return normalized.length * rate;
  }

  /// Resolves the localized display group name.
  /// If the stored group name is default or legacy, returns localized l10n default.
  /// If the user custom-edited the group name, preserves the user's custom name.
  static String resolveGroupName(String? name, String localizedDefault) {
    if (name == null || name.trim().isEmpty) return localizedDefault;
    final trimmed = name.trim();
    if (trimmed == 'Shivshahi' ||
        trimmed == 'Shivshahi Bachat Gat' ||
        trimmed == 'शिवशाही' ||
        trimmed == 'शिवशाही बचत गट' ||
        trimmed == 'shivshahi_group_001' ||
        trimmed == 'Chhatrapati Bachat Gat, Ghargaon Stand' ||
        trimmed == 'छत्रपती बचत गट, घारगाव स्टँड') {
      return localizedDefault;
    }
    return trimmed;
  }

  /// Calculates total active shares across active members.
  static int calculateTotalActiveShares(List<Member> members) {
    return members
        .where((m) => m.status == MemberStatus.active)
        .fold<int>(0, (total, m) => total + m.shares);
  }

  /// Calculates current month's regular member contributions collected (Hafta only).
  /// Strictly excludes loan principal, loan repayments, interest income, and pending uncollected dues.
  static double calculateCurrentMonthCollectedSavings(
    List<MonthlyContribution> contributions, {
    required int month,
    required int year,
  }) {
    return contributions
        .where((c) => c.month == month && c.year == year)
        .fold<double>(0.0, (total, c) => total + c.actualRegularPaid);
  }

  /// Calculates a member's expected regular monthly due based on shares and group per-share amount.
  static double calculateMemberMonthlyDue({
    required Member member,
    double? perShareAmount,
  }) {
    if (member.status != MemberStatus.active) return 0.0;
    final rate = (perShareAmount != null && perShareAmount > 0)
        ? perShareAmount
        : member.monthlyContributionPerShare;
    return member.shares * (rate > 0 ? rate : 1000.0);
  }

  /// Returns the actual regular monthly contribution paid by a member for a given month.
  /// Strictly isolates regular savings from loan principal repayments and loan interest.
  static double calculateMemberPaidForMonth(MonthlyContribution? contribution) {
    return contribution?.actualRegularPaid ?? 0.0;
  }

  /// Calculates a member's pending regular monthly hafta for a given month & year.
  /// Returns remaining amount: max(0, memberMonthlyDue - memberPaidForMonth).
  /// If remaining <= 0, returns 0.0 (fully paid / not pending).
  static double calculateMemberPendingHafta({
    required Member member,
    MonthlyContribution? contribution,
    double? perShareAmount,
  }) {
    if (member.status != MemberStatus.active) return 0.0;
    final monthlyDue = calculateMemberMonthlyDue(member: member, perShareAmount: perShareAmount);
    final paidAmount = calculateMemberPaidForMonth(contribution);
    final remaining = monthlyDue - paidAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Calculates authoritative total monthly pending amount: max(0, monthlyTarget - monthlyCollected).
  static double calculateMonthlyPendingTotal({
    required double target,
    required double collected,
  }) {
    final pending = target - collected;
    return pending > 0 ? pending : 0.0;
  }

  /// Calculates clamped savings progress ratio (0.0 to 1.0) for visual progress indicators.
  static double calculateSavingsProgressRatio({
    required double collected,
    required double target,
  }) {
    if (target <= 0) return 0.0;
    final ratio = collected / target;
    return ratio.clamp(0.0, 1.0);
  }

  /// Calculates the payment window for a given month and year.
  /// The payment window runs from `dueDay` of month $M$ through `dueDay` of month $M+1$.
  ///
  /// Example (dueDay = 10, month = 8, year = 2026):
  /// - Start: August 10, 2026 00:00:00
  /// - End: September 10, 2026 00:00:00 (September cycle starts on Sep 10)
  static PaymentWindow getPaymentWindow({
    required int month,
    required int year,
    int dueDay = 10,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final effectiveStartDay = dueDay > daysInMonth ? daysInMonth : dueDay;
    final windowStart = DateTime(year, month, effectiveStartDay, 0, 0, 0);

    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final effectiveEndDay = dueDay > daysInNextMonth ? daysInNextMonth : dueDay;
    final windowEnd = DateTime(nextYear, nextMonth, effectiveEndDay, 0, 0, 0);

    return PaymentWindow(start: windowStart, end: windowEnd);
  }

  /// Determines if a month's payment window has expired (overdue).
  /// For Month $M$, payment window is [Month M dueDay, Month M+1 dueDay).
  /// Once Month $M+1$ dueDay arrives, Month $M+1$ starts and Month $M$ becomes overdue.
  ///
  /// Example (dueDay = 10, month = 8, year = 2026):
  /// - Aug 10, Aug 25, Sep 1, Sep 9 -> NOT overdue (returns false).
  /// - Sep 10 onward -> OVERDUE (returns true).
  static bool isMonthOverdue({
    required int month,
    required int year,
    DateTime? currentDate,
    int dueDay = 10,
  }) {
    final now = currentDate ?? DateTime.now();
    final active = getActiveCycleForDate(now, dueDay: dueDay);
    return (active.year * 12 + active.month) > (year * 12 + month);
  }

  /// Determines the active cycle month and year for a given transaction date.
  /// Each monthly hafta payment window runs from:
  /// Current Month `dueDay` -> Next Month `dueDay`
  /// 
  /// Example (dueDay = 10):
  /// - 10 Aug to 9 Sep -> Month 8, Year 2026 (August hafta available)
  /// - 10 Sep to 9 Oct -> Month 9, Year 2026 (September hafta starts on 10 Sep)
  /// - 10 Oct to 9 Nov -> Month 10, Year 2026 (October hafta starts on 10 Oct)
  /// - 10 Dec 2026 to 9 Jan 2027 -> Month 12, Year 2026 (December)
  /// - 10 Jan 2027 to 9 Feb 2027 -> Month 1, Year 2027 (January)
  static PaymentCycle getActiveCycleForDate(DateTime date, {int dueDay = 10}) {
    if (date.day >= dueDay) {
      return PaymentCycle(month: date.month, year: date.year);
    } else {
      final prevMonth = date.month == 1 ? 12 : date.month - 1;
      final prevYear = date.month == 1 ? date.year - 1 : date.year;
      return PaymentCycle(month: prevMonth, year: prevYear);
    }
  }

  /// Extracts the base name and sequence number from a member's name.
  /// Example: 'महेश मनोहर आहेर 3' -> (baseName: 'महेश मनोहर आहेर', sequence: 3)
  /// Example: 'आकाश चंद्रकांत गुळाळ' -> (baseName: 'आकाश चंद्रकांत गुळाळ', sequence: -1)
  static MapEntry<String, int> parseMemberBaseNameAndSequence(String name) {
    final trimmed = name.trim();
    final match = RegExp(r'^(.*?)(?:\s+([0-9\u0966-\u096F]+))?$').firstMatch(trimmed);
    if (match != null && match.group(2) != null) {
      final base = (match.group(1) ?? '').trim();
      final seqRaw = match.group(2)!;
      final asciiDigits = seqRaw.split('').map((char) {
        final code = char.codeUnitAt(0);
        if (code >= 0x0966 && code <= 0x096F) {
          return (code - 0x0966).toString();
        }
        return char;
      }).join('');
      final seq = int.tryParse(asciiDigits) ?? -1;
      return MapEntry(base.isNotEmpty ? base : trimmed, seq);
    }
    return MapEntry(trimmed, -1);
  }

  /// Sorts and normalizes a list of members so all members belonging to the same base name
  /// ALWAYS appear together, ordered strictly by their numeric sequence:
  /// 1. Base member name
  /// 2. Sequence number (0, 1, 2, 3, 4, 5...)
  /// 3. Member ID as fallback
  ///
  /// If a base name has numbered members (e.g. 'Name 1', 'Name 2'), any duplicate or un-numbered
  /// plain base-name record ('Name') is automatically omitted from the output.
  static List<Member> sortMembersByBaseNameAndSequence(List<Member> members) {
    if (members.isEmpty) return const [];

    // 1. Group members by base name
    final grouped = <String, List<Member>>{};
    for (final m in members) {
      final base = parseMemberBaseNameAndSequence(m.name).key;
      grouped.putIfAbsent(base, () => []).add(m);
    }

    final normalized = <Member>[];

    for (final entry in grouped.entries) {
      final groupMembers = entry.value;
      if (groupMembers.length <= 1) {
        normalized.addAll(groupMembers);
        continue;
      }

      // Check if numbered records (seq >= 0) exist in this base name group
      final hasNumbered = groupMembers.any((m) {
        final seq = parseMemberBaseNameAndSequence(m.name).value;
        return seq >= 0;
      });

      if (hasNumbered) {
        // Exclude the un-numbered plain base-name record (seq == -1)
        final numberedOnly = groupMembers.where((m) {
          final seq = parseMemberBaseNameAndSequence(m.name).value;
          return seq >= 0;
        }).toList();
        normalized.addAll(numberedOnly);
      } else {
        normalized.addAll(groupMembers);
      }
    }

    // 2. Sort by base name and sequence number
    normalized.sort((a, b) {
      final parsedA = parseMemberBaseNameAndSequence(a.name);
      final parsedB = parseMemberBaseNameAndSequence(b.name);

      final baseCompare = parsedA.key.compareTo(parsedB.key);
      if (baseCompare != 0) {
        return baseCompare;
      }

      final seqCompare = parsedA.value.compareTo(parsedB.value);
      if (seqCompare != 0) {
        return seqCompare;
      }

      return a.id.compareTo(b.id);
    });

    return normalized;
  }

  static const _shortEnglishMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  static const _englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

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

  static String formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthStr = (date.month >= 1 && date.month <= 12) ? _shortEnglishMonths[date.month - 1] : '';
    return '$day $monthStr ${date.year}';
  }

  static String formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthStr = (date.month >= 1 && date.month <= 12) ? _englishMonths[date.month - 1] : '';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$day $monthStr ${date.year}, ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }

  static String getMonthName(int month, {String locale = 'en'}) {
    if (locale == 'mr') {
      return getMonthNameMarathi(month);
    }
    if (month >= 1 && month <= 12) {
      return _englishMonths[month - 1];
    }
    return '';
  }

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

  /// Normalizes a phone number to standard international format (e.g. 919604231760).
  /// Strips +, -, spaces, parentheses.
  /// Returns null if phone number is invalid (less than 10 digits).
  static String? normalizeIndianPhoneNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      return '91${digits.substring(1)}';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }
    if (digits.length >= 10) {
      return digits;
    }
    return null;
  }
}

class PaymentWindow {
  final DateTime start;
  final DateTime end;

  const PaymentWindow({required this.start, required this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentWindow &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'PaymentWindow(start: $start, end: $end)';
}

class PaymentCycle {
  final int month;
  final int year;

  const PaymentCycle({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentCycle &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;

  @override
  String toString() => 'PaymentCycle(month: $month, year: $year)';
}
