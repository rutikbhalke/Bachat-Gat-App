import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bachat_gat/providers/locale_provider.dart';
import 'package:bachat_gat/l10n/app_localizations_mr.dart';
import 'package:bachat_gat/l10n/app_localizations_en.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Default Language (Marathi) & LocaleProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Fresh startup defaults to Marathi Locale(mr)', () async {
      final provider = LocaleProvider();
      expect(provider.locale, const Locale('mr'));
    });

    test('2. Startup with preloaded SharedPreferences defaults to Marathi Locale(mr) when key is absent', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs);
      expect(provider.locale, const Locale('mr'));
    });

    test('3. User can switch to English and it updates locale and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs);
      expect(provider.locale, const Locale('mr'));

      await provider.setLocale(const Locale('en'));
      expect(provider.locale, const Locale('en'));

      final savedLang = prefs.getString('language_code');
      expect(savedLang, 'en');
    });

    test('4. User can switch back to Marathi and it updates locale and persists', () async {
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs);
      expect(provider.locale, const Locale('en'));

      await provider.setLocale(const Locale('mr'));
      expect(provider.locale, const Locale('mr'));

      final savedLang = prefs.getString('language_code');
      expect(savedLang, 'mr');
    });

    test('5. Group Info popup localization strings match exact requirements', () {
      final mr = AppLocalizationsMr();
      expect(mr.defaultGroupName, 'छत्रपती बचत गट, घारगाव स्टँड');
      expect(mr.groupId, 'गट क्रमांक');
      expect(mr.monthlyContribution, 'मासिक बचत');
      expect(mr.perMember, 'प्रति सभासद');
      expect(mr.monthlyTarget, 'मासिक लक्ष्य');
      expect(mr.createdDate, 'निर्मिती दिनांक');
      expect(mr.close, 'बंद करा');

      final en = AppLocalizationsEn();
      expect(en.defaultGroupName, 'Chhatrapati Bachat Gat, Ghargaon Stand');
      expect(en.groupId, 'Group ID');
      expect(en.monthlyContribution, 'Monthly Contribution');
      expect(en.perMember, 'per member');
      expect(en.monthlyTarget, 'Monthly Target');
      expect(en.createdDate, 'Created Date');
      expect(en.close, 'Close');
    });

    test('6. Recent Activity & Dashboard section localization strings and description translations', () {
      final mr = AppLocalizationsMr();
      expect(mr.monthlyContribution, 'मासिक बचत');
      expect(mr.monthlyPayment, 'मासिक भरणा');
      expect(mr.repayment, 'परतफेड');
      expect(mr.loanIssued, 'कर्ज दिले');
      expect(mr.viewAll, 'सर्व पहा');
      expect(mr.tenthOfEveryMonth, 'दर महिन्याच्या १० तारखेला');
      expect(mr.recentActivity, 'अलीकडील हालचाली');
      expect(mr.viewDetails, 'तपशील पहा');

      final en = AppLocalizationsEn();
      expect(en.monthlyContribution, 'Monthly Contribution');
      expect(en.monthlyPayment, 'Monthly Payment');
      expect(en.repayment, 'Repayment');
      expect(en.loanIssued, 'Loan Issued');
      expect(en.viewAll, 'View All');
      expect(en.tenthOfEveryMonth, '10th of every month');
      expect(en.recentActivity, 'Recent Activity');
      expect(en.viewDetails, 'View Details');

      // Test description translation while preserving member names and numbers
      expect(
        CalculationUtils.localizeTransactionDescription('Monthly Contribution - August 2026', isMarathi: true),
        'मासिक बचत - ऑगस्ट 2026',
      );
      expect(
        CalculationUtils.localizeTransactionDescription('Monthly Payment - August 2026 (Hafta: ₹1000, Interest: ₹100, Principal: ₹0)', isMarathi: true),
        'मासिक भरणा - ऑगस्ट 2026 (हप्ता: ₹1000, व्याज: ₹100, मुद्दल: ₹0)',
      );
      expect(
        CalculationUtils.localizeTransactionDescription('Repayment - August 2026 (Hafta: ₹1000, Interest: ₹100, Principal: ₹0)', isMarathi: true),
        'परतफेड - ऑगस्ट 2026 (हप्ता: ₹1000, व्याज: ₹100, मुद्दल: ₹0)',
      );
      expect(
        CalculationUtils.localizeTransactionDescription('Loan Issued: ₹2000 to Tanmay Hase', isMarathi: true),
        'कर्ज दिले: ₹2000 - Tanmay Hase',
      );
      expect(
        CalculationUtils.localizeTransactionDescription('Loan Issued: ₹2500', isMarathi: true),
        'कर्ज दिले: ₹2500',
      );

      // Verify English preserves original strings exactly
      expect(
        CalculationUtils.localizeTransactionDescription('Monthly Contribution - August 2026', isMarathi: false),
        'Monthly Contribution - August 2026',
      );
      expect(
        CalculationUtils.localizeTransactionDescription('Loan Issued: ₹2000 to Tanmay Hase', isMarathi: false),
        'Loan Issued: ₹2000 to Tanmay Hase',
      );
    });

    test('7. Pending Dues & Reports section localization strings', () {
      final mr = AppLocalizationsMr();
      expect(mr.monthlyRegister, 'मासिक नोंद');
      expect(mr.pendingDues, 'बाकी रक्कम');
      expect(mr.loansOverview, 'कर्जाचा आढावा');
      expect(mr.pendingDuesSummary, 'बाकी रकमेचा सारांश');
      expect(mr.membersPendingBalance, 'सभासदांची रक्कम बाकी आहे');
      expect(mr.share, 'शेअर करा');
      expect(mr.outstandingLoanPrincipal, 'बाकी कर्जाचे मुद्दल');
      expect(mr.pendingInterest2Percent, 'बाकी व्याज (२%)');
      expect(mr.pendingHafta, 'बाकी हप्ता');
      expect(mr.allCollectionsUpToDate, 'सर्व वसुली पूर्ण! कोणतीही बाकी रक्कम नाही.');
      expect(mr.totalInterest2Percent, 'एकूण व्याज (२%)');
      expect(mr.outstandingPrincipal, 'बाकी मुद्दल');
      expect(mr.availableGroupBalance, 'उपलब्ध गट शिल्लक');
      expect(mr.monthlyRegisterBreakdown, 'मासिक नोंद तपशील');
      expect(mr.noCollectionRecordsForMonth, 'या महिन्यासाठी कोणतीही वसुली नोंद नाही');
      expect(mr.noLoansIssuedYet, 'अद्याप कोणतेही कर्ज दिलेले नाही');
      expect(mr.originalLoan, 'मूळ कर्ज');
      expect(mr.principalPaid, 'भरलेले मुद्दल');
      expect(mr.interestPaid2Percent, 'भरलेले व्याज (२%)');
      expect(mr.remaining, 'उर्वरित बाकी');
      expect(mr.repayments, 'परतफेड हप्ते');
      expect(mr.retry, 'पुन्हा प्रयत्न करा');
      expect(mr.refreshReport, 'अहवाल रीफ्रेश करा');

      final en = AppLocalizationsEn();
      expect(en.monthlyRegister, 'Monthly Register');
      expect(en.pendingDues, 'Pending Dues');
      expect(en.loansOverview, 'Loans Overview');
      expect(en.pendingDuesSummary, 'Pending Dues Summary');
      expect(en.membersPendingBalance, 'members have pending balance');
      expect(en.share, 'Share');
      expect(en.outstandingLoanPrincipal, 'Outstanding Loan Principal');
      expect(en.pendingInterest2Percent, 'Pending Interest (2%)');
      expect(en.pendingHafta, 'Pending Hafta');
      expect(en.allCollectionsUpToDate, 'All collections up to date! No pending dues.');
      expect(en.totalInterest2Percent, 'Total Interest (2%)');
      expect(en.outstandingPrincipal, 'Outstanding Principal');
      expect(en.availableGroupBalance, 'Available Group Balance');
      expect(en.monthlyRegisterBreakdown, 'Monthly Register Breakdown');
      expect(en.noCollectionRecordsForMonth, 'No collection records for this month');
      expect(en.noLoansIssuedYet, 'No loans issued yet');
      expect(en.originalLoan, 'Original Loan');
      expect(en.principalPaid, 'Principal Paid');
      expect(en.interestPaid2Percent, 'Interest Paid (2%)');
      expect(en.remaining, 'Remaining');
      expect(en.repayments, 'Repayments');
      expect(en.retry, 'Retry');
      expect(en.refreshReport, 'Refresh Report');
    });

    test('8. Manage Loans & Loan Details section localization strings', () {
      final mr = AppLocalizationsMr();
      expect(mr.manageLoans, 'कर्ज व्यवस्थापन');
      expect(mr.activeLoansTab, 'चालू कर्जे');
      expect(mr.closedLoansTab, 'बंद कर्जे');
      expect(mr.interestRate, 'व्याज दर');
      expect(mr.outstanding, 'बाकी रक्कम');
      expect(mr.repaid, 'परतफेड');
      expect(mr.perMonth, 'महिना');
      expect(mr.noLoansFound, 'कोणतेही कर्ज आढळले नाही');
      expect(mr.loanDetails, 'कर्ज तपशील');
      expect(mr.recordPayment, 'भरणा नोंदवा');
      expect(mr.currentMonthInterest2Percent, 'चालू महिन्याचे व्याज (२%)');
      expect(mr.monthlyInterestDue, 'देय मासिक व्याज:');
      expect(mr.repaymentHistory, 'परतफेड इतिहास');
      expect(mr.payments, 'भरणा');
      expect(mr.noRepaymentsRecordedYet, 'अद्याप कोणतीही परतफेड नोंदवलेली नाही');
      expect(mr.interestPaid, 'भरलेले व्याज');
      expect(mr.monthlyRate, 'मासिक दर');
      expect(mr.closingBalance, 'अंतिम बाकी');
      expect(mr.recordLoanPayment, 'कर्ज भरणा नोंदवा');
      expect(mr.principalRepaymentAmount, 'मुद्दल परतफेड रक्कम (₹)');
      expect(mr.regularHaftaOptional, 'नियमित हप्ता (पर्यायी) (₹)');
      expect(mr.totalPayment, 'एकूण भरणा:');
      expect(mr.record, 'नोंदवा');
      expect(mr.cancel, 'रद्द करा');
      expect(mr.year, 'वर्ष');
      expect(mr.principalCannotExceedPending, 'मुद्दल परतफेड बाकी मुद्दलापेक्षा जास्त असू शकत नाही');

      final en = AppLocalizationsEn();
      expect(en.manageLoans, 'Manage Loans');
      expect(en.activeLoansTab, 'Active Loans');
      expect(en.closedLoansTab, 'Closed');
      expect(en.interestRate, 'Interest Rate');
      expect(en.outstanding, 'Outstanding');
      expect(en.repaid, 'Repaid');
      expect(en.perMonth, 'mo');
      expect(en.noLoansFound, 'No loans found');
      expect(en.loanDetails, 'Loan Details');
      expect(en.recordPayment, 'Record Payment');
      expect(en.currentMonthInterest2Percent, 'CURRENT MONTH INTEREST (2%)');
      expect(en.monthlyInterestDue, 'Monthly Interest due:');
      expect(en.repaymentHistory, 'REPAYMENT HISTORY');
      expect(en.payments, 'Payments');
      expect(en.noRepaymentsRecordedYet, 'No repayments recorded yet');
      expect(en.interestPaid, 'Interest Paid');
      expect(en.monthlyRate, 'Monthly Rate');
      expect(en.closingBalance, 'Closing Balance');
      expect(en.recordLoanPayment, 'Record Loan Payment');
      expect(en.principalRepaymentAmount, 'Principal Repayment Amount (₹)');
      expect(en.regularHaftaOptional, 'Regular Hafta (Optional) (₹)');
      expect(en.totalPayment, 'Total Payment:');
      expect(en.record, 'Record');
      expect(en.cancel, 'Cancel');
      expect(en.year, 'Year');
      expect(en.principalCannotExceedPending, 'Principal repayment cannot exceed pending principal');
    });
  });
}
