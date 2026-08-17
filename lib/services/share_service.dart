import 'package:share_plus/share_plus.dart';
import '../models/report_models.dart';
import '../core/utils/calculation_utils.dart';

class ShareService {
  static Future<void> shareMemberReceipt({
    required MemberMonthlyReport report,
    required String filePath,
    required String languageCode,
  }) async {
    final monthName = CalculationUtils.getMonthName(report.month);
    
    String message;
    if (languageCode == 'mr') {
      message = "नमस्कार ${report.member.name},\n\n"
          "तुमचा मार्च ${report.year} चा बचत गटाचा मासिक अहवाल:\n\n"
          "नियमित हप्ता: ${CalculationUtils.formatCurrency(report.paidHafta)}\n"
          "परत केलेले कर्ज मुद्दल: ${CalculationUtils.formatCurrency(report.principalRepaid)}\n"
          "कर्ज व्याज: ${CalculationUtils.formatCurrency(report.interestAmount)}\n"
          "एकूण भरलेली रक्कम: ${CalculationUtils.formatCurrency(report.totalPaid)}\n"
          "प्रलंबित कर्ज: ${CalculationUtils.formatCurrency(report.closingPrincipal)}\n\n"
          "कृपया जोडलेली सविस्तर पावती पहा.";
    } else {
      message = "Namaskar ${report.member.name},\n\n"
          "Your Bachat Gat monthly statement for $monthName ${report.year}:\n\n"
          "Regular Hafta: ${CalculationUtils.formatCurrency(report.paidHafta)}\n"
          "Loan Principal Repaid: ${CalculationUtils.formatCurrency(report.principalRepaid)}\n"
          "Loan Interest: ${CalculationUtils.formatCurrency(report.interestAmount)}\n"
          "Total Paid: ${CalculationUtils.formatCurrency(report.totalPaid)}\n"
          "Pending Loan: ${CalculationUtils.formatCurrency(report.closingPrincipal)}\n\n"
          "Please find the detailed receipt attached.";
    }

    await Share.shareXFiles(
      [XFile(filePath)],
      text: message,
      subject: 'Bachat Gat Monthly Receipt',
    );
  }

  static Future<void> shareGroupReport({
    required GroupMonthlyReport report,
    required String filePath,
    required String languageCode,
  }) async {
    final monthName = CalculationUtils.getMonthName(report.month);
    
    String message;
    if (languageCode == 'mr') {
      message = "नमस्कार सर्वांना,\n\n"
          "${report.groupName} चा $monthName ${report.year} चा मासिक अहवाल:\n\n"
          "एकूण सभासद: ${report.totalMembers}\n"
          "हप्ता जमा: ${CalculationUtils.formatCurrency(report.totalCollectedHafta)}\n"
          "कर्ज मुद्दल जमा: ${CalculationUtils.formatCurrency(report.totalPrincipalRepaid)}\n"
          "व्याज जमा: ${CalculationUtils.formatCurrency(report.totalInterestCollected)}\n"
          "एकूण वसुली: ${CalculationUtils.formatCurrency(report.totalCollection)}\n"
          "एकूण थकीत कर्ज: ${CalculationUtils.formatCurrency(report.totalOutstandingLoan)}\n\n"
          "सविस्तर अहवाल जोडला आहे.";
    } else {
      message = "Namaskar everyone,\n\n"
          "Bachat Gat monthly report for $monthName ${report.year}:\n\n"
          "Members: ${report.totalMembers}\n"
          "Hafta Collection: ${CalculationUtils.formatCurrency(report.totalCollectedHafta)}\n"
          "Loan Principal Collection: ${CalculationUtils.formatCurrency(report.totalPrincipalRepaid)}\n"
          "Interest Collection: ${CalculationUtils.formatCurrency(report.totalInterestCollected)}\n"
          "Total Collection: ${CalculationUtils.formatCurrency(report.totalCollection)}\n"
          "Outstanding Loan: ${CalculationUtils.formatCurrency(report.totalOutstandingLoan)}\n\n"
          "Detailed monthly report is attached.";
    }

    await Share.shareXFiles(
      [XFile(filePath)],
      text: message,
      subject: 'Bachat Gat Monthly Report',
    );
  }
}
