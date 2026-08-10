import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/bachat_models.dart';
import 'bachat_storage_service.dart';

class WhatsAppService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String _formatPhone(String rawPhone) {
    String cleaned = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    return cleaned;
  }

  static String buildPaymentReceiptText({
    required BachatGroup group,
    required BachatMember member,
    required MonthlyPayment payment,
    required double totalMemberSavings,
  }) {
    final dateStr = DateFormat('dd MMM yyyy').format(payment.paymentDate);

    final sb = StringBuffer();
    sb.writeln('🚩 *BACHAT GAT PAYMENT RECEIPT* 🚩');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('🏢 *Group:* ${group.name}');
    sb.writeln('👤 *Member:* ${member.name}');
    sb.writeln('📞 *Phone:* ${member.phone}');
    sb.writeln('📅 *Month/Period:* ${payment.monthYear}');
    sb.writeln('🗓️ *Payment Date:* $dateStr');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '💰 *Fixed Monthly Savings:* ${_currencyFormat.format(payment.savingsAmount)}');

    if (payment.interestPaid > 0) {
      sb.writeln(
          '📉 *Interest Paid (2%):* ${_currencyFormat.format(payment.interestPaid)}');
    }
    if (payment.principalPaid > 0) {
      sb.writeln(
          '💳 *Loan Principal Repaid:* ${_currencyFormat.format(payment.principalPaid)}');
    }

    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '💵 *TOTAL AMOUNT SUBMITTED:* ${_currencyFormat.format(payment.totalPaid)}');

    if (payment.remainingLoanPrincipal > 0) {
      sb.writeln(
          '🏦 *REMAINING LOAN BALANCE:* ${_currencyFormat.format(payment.remainingLoanPrincipal)}');
    } else if (payment.loanId != null && payment.remainingLoanPrincipal <= 0) {
      sb.writeln('🎉 *LOAN STATUS:* FULLY PAID OFF!');
    }

    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '🪙 *Total Savings Contributed:* ${_currencyFormat.format(totalMemberSavings)}');

    if (payment.notes.isNotEmpty) {
      sb.writeln('📝 *Notes:* ${payment.notes}');
    }

    sb.writeln('\nThank you for your contribution! 🙏');
    sb.writeln('_Generated via Bachat Gat App_');
    return sb.toString();
  }

  static String buildMemberStatementText({
    required BachatGroup group,
    required BachatMember member,
  }) {
    final storage = BachatStorageService();
    final totalSavings = storage.getTotalSavingsForMember(member.id);
    final totalInterest = storage.getTotalInterestPaidByMember(member.id);
    final totalPrincipalPaid = storage.getTotalPrincipalPaidByMember(member.id);
    final activeLoan = storage.getActiveLoanForMember(member.id);
    final payments = storage.getPaymentsForMember(member.id);

    final sb = StringBuffer();
    sb.writeln('🚩 *MEMBER BACHAT GAT STATEMENT* 🚩');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('👤 *Member:* ${member.name}');
    sb.writeln('🏢 *Group:* ${group.name}');
    sb.writeln('📞 *Phone:* ${member.phone}');
    sb.writeln('🏅 *Role:* ${member.role}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '💰 *Total Savings Contributed:* ${_currencyFormat.format(totalSavings)}');

    if (activeLoan != null) {
      sb.writeln(
          '🏦 *Original Loan Taken:* ${_currencyFormat.format(activeLoan.principalAmount)}');
      sb.writeln(
          '💳 *Total Principal Repaid:* ${_currencyFormat.format(totalPrincipalPaid)}');
      sb.writeln(
          '⚠️ *OUTSTANDING LOAN BALANCE:* ${_currencyFormat.format(activeLoan.remainingPrincipal)}');
      sb.writeln(
          '📉 *Monthly Interest Rate:* ${activeLoan.interestRateMonthly}%');
    } else {
      sb.writeln('✅ *Loan Status:* No Active Loan');
    }

    sb.writeln(
        '📊 *Total Interest Paid to Group:* ${_currencyFormat.format(totalInterest)}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('*Recent Payment Transactions:*');

    for (var p in payments.take(5)) {
      sb.writeln(
          '• ${p.monthYear}: Savings ${_currencyFormat.format(p.savingsAmount)} | Paid Total ${_currencyFormat.format(p.totalPaid)}');
    }

    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '_Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}_');
    return sb.toString();
  }

  static String buildGroupReportText({
    required BachatGroup group,
  }) {
    final storage = BachatStorageService();
    final members = storage.getMembersForGroup(group.id);
    final totalSavings = storage.getTotalSavingsForGroup(group.id);
    final totalInterest = storage.getTotalInterestEarnedForGroup(group.id);
    final totalLoans = storage.getTotalLoansDisbursedForGroup(group.id);
    final activeLoansBal =
        storage.getTotalActiveLoanPrincipalForGroup(group.id);
    final netAvailable = storage.getNetAvailableGroupFunds(group.id);

    final sb = StringBuffer();
    sb.writeln('📊 *BACHAT GAT GROUP SUMMARY REPORT* 📊');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('🏢 *Group Name:* ${group.name}');
    sb.writeln('👥 *Total Members:* ${members.length}');
    sb.writeln(
        '📅 *Formation Date:* ${DateFormat('dd MMM yyyy').format(group.formationDate)}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '💰 *Total Savings Pool Collected:* ${_currencyFormat.format(totalSavings)}');
    sb.writeln(
        '📈 *Total Interest Earned (2%):* ${_currencyFormat.format(totalInterest)}');
    sb.writeln(
        '🏦 *Total Loans Disbursed:* ${_currencyFormat.format(totalLoans)}');
    sb.writeln(
        '⚠️ *Active Loans Principal Pending:* ${_currencyFormat.format(activeLoansBal)}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln(
        '💵 *NET AVAILABLE CASH IN POOL:* ${_currencyFormat.format(netAvailable)}');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');

    sb.writeln('\n*Group Members Breakdown:*');
    for (var m in members) {
      final mSavings = storage.getTotalSavingsForMember(m.id);
      final mLoan = storage.getActiveLoanForMember(m.id);
      final loanInfo = mLoan != null
          ? ' | ⚠️ Loan: ${_currencyFormat.format(mLoan.remainingPrincipal)}'
          : '';
      sb.writeln(
          '• ${m.name} (${m.role}): Savings ${_currencyFormat.format(mSavings)}$loanInfo');
    }

    sb.writeln(
        '\n_Report generated via Bachat Gat App on ${DateFormat('dd MMM yyyy').format(DateTime.now())}_');
    return sb.toString();
  }

  static Future<bool> sendWhatsAppMessage({
    required String phoneNumber,
    required String messageText,
  }) async {
    final cleanPhone = _formatPhone(phoneNumber);
    final encodedText = Uri.encodeComponent(messageText);

    // Try direct WhatsApp scheme first, fallback to https wa.me URL
    final whatsappUri =
        Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        return await launchUrl(whatsappUri,
            mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(webUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Fallback open browser URL
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
