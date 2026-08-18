import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../models/member.dart';
import '../core/utils/calculation_utils.dart';

class ShareService {
  static Future<void> shareMemberReceipt({
    required MemberMonthlyReport report,
    required Uint8List pdfBytes,
    required String languageCode,
  }) async {
    final monthName = CalculationUtils.getMonthName(report.month);
    final filename = 'BG_Receipt_${report.member.name}_${report.month}_${report.year}.pdf';
    
    String message;
    if (languageCode == 'mr') {
      message = "नमस्कार ${report.member.name},\n\n"
          "तुमचा $monthName ${report.year} चा बचत गटाचा मासिक अहवाल:\n\n"
          "• नियमित हप्ता: ${CalculationUtils.formatCurrency(report.paidHafta)}\n"
          "• परत केलेले कर्ज मुद्दल: ${CalculationUtils.formatCurrency(report.principalRepaid)}\n"
          "• कर्ज व्याज (२%): ${CalculationUtils.formatCurrency(report.interestAmount)}\n"
          "• एकूण भरलेली रक्कम: ${CalculationUtils.formatCurrency(report.totalPaid)}\n"
          "• शिल्लक थकीत कर्ज: ${CalculationUtils.formatCurrency(report.closingPrincipal)}\n"
          "${report.pendingHafta > 0 ? '• थकीत हप्ता: ${CalculationUtils.formatCurrency(report.pendingHafta)}\n' : ''}\n"
          "कृपया जोडलेली सविस्तर पावती पहा.";
    } else {
      message = "Namaskar ${report.member.name},\n\n"
          "Your Bachat Gat monthly statement for $monthName ${report.year}:\n\n"
          "• Regular Hafta: ${CalculationUtils.formatCurrency(report.paidHafta)}\n"
          "• Loan Principal Repaid: ${CalculationUtils.formatCurrency(report.principalRepaid)}\n"
          "• Loan Interest (2%): ${CalculationUtils.formatCurrency(report.interestAmount)}\n"
          "• Total Paid: ${CalculationUtils.formatCurrency(report.totalPaid)}\n"
          "• Pending Loan Balance: ${CalculationUtils.formatCurrency(report.closingPrincipal)}\n"
          "${report.pendingHafta > 0 ? '• Pending Hafta: ${CalculationUtils.formatCurrency(report.pendingHafta)}\n' : ''}\n"
          "Please find the detailed receipt attached.";
    }

    if (kIsWeb) {
      // On Web, initiate direct browser download and/or share
      try {
        await Share.shareXFiles(
          [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
          text: message,
          subject: 'Bachat Gat Monthly Receipt',
        );
      } catch (_) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      }
    } else {
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
        text: message,
        subject: 'Bachat Gat Monthly Receipt',
      );
    }
  }

  static Future<void> shareGroupReport({
    required GroupMonthlyReport report,
    required Uint8List pdfBytes,
    required String languageCode,
  }) async {
    final monthName = CalculationUtils.getMonthName(report.month);
    final filename = 'BG_Group_Report_${report.month}_${report.year}.pdf';
    
    String message;
    if (languageCode == 'mr') {
      message = "नमस्कार सर्वांना,\n\n"
          "${report.groupName} चा $monthName ${report.year} चा मासिक अहवाल:\n\n"
          "• एकूण सभासद: ${report.totalMembers}\n"
          "• हप्ता जमा: ${CalculationUtils.formatCurrency(report.totalCollectedHafta)}\n"
          "• कर्ज मुद्दल जमा: ${CalculationUtils.formatCurrency(report.totalPrincipalRepaid)}\n"
          "• व्याज जमा (२%): ${CalculationUtils.formatCurrency(report.totalInterestCollected)}\n"
          "• एकूण मासिक वसुली: ${CalculationUtils.formatCurrency(report.totalCollection)}\n"
          "• एकूण थकीत कर्ज: ${CalculationUtils.formatCurrency(report.totalOutstandingLoan)}\n"
          "${report.totalPendingHafta > 0 ? '• एकूण थकीत हप्ता: ${CalculationUtils.formatCurrency(report.totalPendingHafta)}\n' : ''}\n"
          "सविस्तर अहवाल फाईल जोडली आहे.";
    } else {
      message = "Namaskar everyone,\n\n"
          "Monthly Collection Report for ${report.groupName} ($monthName ${report.year}):\n\n"
          "• Total Members: ${report.totalMembers}\n"
          "• Regular Hafta Collected: ${CalculationUtils.formatCurrency(report.totalCollectedHafta)}\n"
          "• Loan Principal Collected: ${CalculationUtils.formatCurrency(report.totalPrincipalRepaid)}\n"
          "• Interest Collected (2%): ${CalculationUtils.formatCurrency(report.totalInterestCollected)}\n"
          "• Total Monthly Collection: ${CalculationUtils.formatCurrency(report.totalCollection)}\n"
          "• Total Outstanding Loans: ${CalculationUtils.formatCurrency(report.totalOutstandingLoan)}\n"
          "${report.totalPendingHafta > 0 ? '• Total Pending Hafta: ${CalculationUtils.formatCurrency(report.totalPendingHafta)}\n' : ''}\n"
          "Detailed collection register is attached.";
    }

    if (kIsWeb) {
      try {
        await Share.shareXFiles(
          [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
          text: message,
          subject: 'Bachat Gat Monthly Collection Report',
        );
      } catch (_) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      }
    } else {
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
        text: message,
        subject: 'Bachat Gat Monthly Collection Report',
      );
    }
  }

  static Future<void> shareMemberLedger({
    required Member member,
    required Uint8List pdfBytes,
    required String languageCode,
  }) async {
    final filename = 'BG_Ledger_${member.name}.pdf';
    String message = languageCode == 'mr'
        ? "नमस्कार ${member.name},\n\nतुमचे बचत गटाचे खाते विवरण (Ledger Statement) जोडले आहे."
        : "Namaskar ${member.name},\n\nPlease find your Bachat Gat Account Statement (Ledger) attached.";

    if (kIsWeb) {
      try {
        await Share.shareXFiles(
          [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
          text: message,
          subject: 'Bachat Gat Member Ledger Statement',
        );
      } catch (_) {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      }
    } else {
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: filename)],
        text: message,
        subject: 'Bachat Gat Member Ledger Statement',
      );
    }
  }

  static Future<void> sharePendingSummary({
    required List<PendingMemberReport> pendingList,
    required String groupName,
    required int month,
    required int year,
    required String languageCode,
  }) async {
    final monthName = languageCode == 'mr'
        ? CalculationUtils.getMonthNameMarathi(month)
        : CalculationUtils.getMonthName(month);
    final totalPendingHafta = pendingList.fold<double>(0.0, (sum, p) => sum + p.pendingHafta);
    final totalPendingLoan = pendingList.fold<double>(0.0, (sum, p) => sum + p.pendingLoanPrincipal);
    final totalOverall = pendingList.fold<double>(0.0, (sum, p) => sum + p.totalPending);

    final buffer = StringBuffer();
    if (languageCode == 'mr') {
      buffer.writeln("⚠️ *थकीत रक्कम अहवाल - $groupName*");
      buffer.writeln("महिना: $monthName $year\n");
      for (var p in pendingList) {
        buffer.writeln("👤 *${p.member.name}*");
        if (p.pendingHafta > 0) buffer.writeln("  - थकीत हप्ता: ${CalculationUtils.formatCurrency(p.pendingHafta)}");
        if (p.pendingLoanPrincipal > 0) buffer.writeln("  - थकीत कर्ज मुद्दल: ${CalculationUtils.formatCurrency(p.pendingLoanPrincipal)}");
        if (p.pendingInterest > 0) buffer.writeln("  - थकीत व्याज: ${CalculationUtils.formatCurrency(p.pendingInterest)}");
        buffer.writeln("  - एकूण येणे: ${CalculationUtils.formatCurrency(p.totalPending)}\n");
      }
      buffer.writeln("------------------------------");
      buffer.writeln("📊 *एकूण थकीत हप्ता:* ${CalculationUtils.formatCurrency(totalPendingHafta)}");
      buffer.writeln("📊 *एकूण थकीत कर्ज:* ${CalculationUtils.formatCurrency(totalPendingLoan)}");
      buffer.writeln("💰 *एकूण थकीत रक्कम:* ${CalculationUtils.formatCurrency(totalOverall)}");
    } else {
      buffer.writeln("⚠️ *Pending Dues Report - $groupName*");
      buffer.writeln("Period: $monthName $year\n");
      for (var p in pendingList) {
        buffer.writeln("👤 *${p.member.name}*");
        if (p.pendingHafta > 0) buffer.writeln("  - Pending Hafta: ${CalculationUtils.formatCurrency(p.pendingHafta)}");
        if (p.pendingLoanPrincipal > 0) buffer.writeln("  - Pending Principal: ${CalculationUtils.formatCurrency(p.pendingLoanPrincipal)}");
        if (p.pendingInterest > 0) buffer.writeln("  - Pending Interest: ${CalculationUtils.formatCurrency(p.pendingInterest)}");
        buffer.writeln("  - Total Dues: ${CalculationUtils.formatCurrency(p.totalPending)}\n");
      }
      buffer.writeln("------------------------------");
      buffer.writeln("📊 *Total Pending Hafta:* ${CalculationUtils.formatCurrency(totalPendingHafta)}");
      buffer.writeln("📊 *Total Pending Loans:* ${CalculationUtils.formatCurrency(totalPendingLoan)}");
      buffer.writeln("💰 *Overall Pending Total:* ${CalculationUtils.formatCurrency(totalOverall)}");
    }

    await Share.share(
      buffer.toString(),
      subject: 'Pending Dues Summary',
    );
  }
}
