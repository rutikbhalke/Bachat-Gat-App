import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('mr')
  ];

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @totalGroupFund.
  ///
  /// In en, this message translates to:
  /// **'TOTAL GROUP FUND'**
  String get totalGroupFund;

  /// No description provided for @totalSavings.
  ///
  /// In en, this message translates to:
  /// **'Total Savings'**
  String get totalSavings;

  /// No description provided for @activeLoans.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get activeLoans;

  /// No description provided for @totalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total Interest'**
  String get totalInterest;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @addSavings.
  ///
  /// In en, this message translates to:
  /// **'Add Savings'**
  String get addSavings;

  /// No description provided for @loans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get loans;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @monthlySavingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Monthly Savings Progress'**
  String get monthlySavingsProgress;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @collect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @nextCollection.
  ///
  /// In en, this message translates to:
  /// **'Next Collection'**
  String get nextCollection;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @monthlyReceipt.
  ///
  /// In en, this message translates to:
  /// **'Monthly Receipt'**
  String get monthlyReceipt;

  /// No description provided for @groupMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Group Monthly Report'**
  String get groupMonthlyReport;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @monthlyContribution.
  ///
  /// In en, this message translates to:
  /// **'Monthly Contribution'**
  String get monthlyContribution;

  /// No description provided for @regularHafta.
  ///
  /// In en, this message translates to:
  /// **'Regular Hafta'**
  String get regularHafta;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @loan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get loan;

  /// No description provided for @openingLoan.
  ///
  /// In en, this message translates to:
  /// **'Opening Loan'**
  String get openingLoan;

  /// No description provided for @interestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get interestRate;

  /// No description provided for @monthlyInterest.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest'**
  String get monthlyInterest;

  /// No description provided for @loanRepaid.
  ///
  /// In en, this message translates to:
  /// **'Loan Principal Repaid'**
  String get loanRepaid;

  /// No description provided for @closingLoan.
  ///
  /// In en, this message translates to:
  /// **'Closing Pending Loan'**
  String get closingLoan;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @collectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Collection Summary'**
  String get collectionSummary;

  /// No description provided for @totalExpectedHafta.
  ///
  /// In en, this message translates to:
  /// **'Total Expected Hafta'**
  String get totalExpectedHafta;

  /// No description provided for @totalHaftaCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Hafta Collected'**
  String get totalHaftaCollected;

  /// No description provided for @totalHaftaPending.
  ///
  /// In en, this message translates to:
  /// **'Total Hafta Pending'**
  String get totalHaftaPending;

  /// No description provided for @loanSummary.
  ///
  /// In en, this message translates to:
  /// **'Loan Summary'**
  String get loanSummary;

  /// No description provided for @totalActiveLoans.
  ///
  /// In en, this message translates to:
  /// **'Total Active Loans'**
  String get totalActiveLoans;

  /// No description provided for @totalPrincipalRepaid.
  ///
  /// In en, this message translates to:
  /// **'Total Principal Repaid'**
  String get totalPrincipalRepaid;

  /// No description provided for @totalInterestCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Interest Collected'**
  String get totalInterestCollected;

  /// No description provided for @totalOutstandingLoan.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding Loan'**
  String get totalOutstandingLoan;

  /// No description provided for @totalCollection.
  ///
  /// In en, this message translates to:
  /// **'Total Collection'**
  String get totalCollection;

  /// No description provided for @memberWiseSummary.
  ///
  /// In en, this message translates to:
  /// **'Member-wise Summary'**
  String get memberWiseSummary;

  /// No description provided for @hafta.
  ///
  /// In en, this message translates to:
  /// **'Hafta'**
  String get hafta;

  /// No description provided for @interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interest;

  /// No description provided for @principal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get principal;

  /// No description provided for @pendingLoan.
  ///
  /// In en, this message translates to:
  /// **'Pending Loan'**
  String get pendingLoan;

  /// No description provided for @generateReceipt.
  ///
  /// In en, this message translates to:
  /// **'Generate Receipt'**
  String get generateReceipt;

  /// No description provided for @shareOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsApp;

  /// No description provided for @previewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Preview Receipt'**
  String get previewReceipt;

  /// No description provided for @groupId.
  ///
  /// In en, this message translates to:
  /// **'Group ID'**
  String get groupId;

  /// No description provided for @perMember.
  ///
  /// In en, this message translates to:
  /// **'per member'**
  String get perMember;

  /// No description provided for @monthlyTarget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Target'**
  String get monthlyTarget;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get createdDate;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @defaultGroupName.
  ///
  /// In en, this message translates to:
  /// **'Shivshahi Bachat Gat'**
  String get defaultGroupName;

  /// No description provided for @monthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment'**
  String get monthlyPayment;

  /// No description provided for @repayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repayment;

  /// No description provided for @loanIssued.
  ///
  /// In en, this message translates to:
  /// **'Loan Issued'**
  String get loanIssued;

  /// No description provided for @tenthOfEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'10th of every month'**
  String get tenthOfEveryMonth;

  /// No description provided for @activeGroupTargetProgress.
  ///
  /// In en, this message translates to:
  /// **'Active Group Target Progress'**
  String get activeGroupTargetProgress;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @monthlyRegister.
  ///
  /// In en, this message translates to:
  /// **'Monthly Register'**
  String get monthlyRegister;

  /// No description provided for @pendingDues.
  ///
  /// In en, this message translates to:
  /// **'Pending Dues'**
  String get pendingDues;

  /// No description provided for @loansOverview.
  ///
  /// In en, this message translates to:
  /// **'Loans Overview'**
  String get loansOverview;

  /// No description provided for @pendingDuesSummary.
  ///
  /// In en, this message translates to:
  /// **'Pending Dues Summary'**
  String get pendingDuesSummary;

  /// No description provided for @membersPendingBalance.
  ///
  /// In en, this message translates to:
  /// **'members have pending balance'**
  String get membersPendingBalance;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @outstandingLoanPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Loan Principal'**
  String get outstandingLoanPrincipal;

  /// No description provided for @pendingInterest2Percent.
  ///
  /// In en, this message translates to:
  /// **'Pending Interest (2%)'**
  String get pendingInterest2Percent;

  /// No description provided for @pendingHafta.
  ///
  /// In en, this message translates to:
  /// **'Pending Hafta'**
  String get pendingHafta;

  /// No description provided for @allCollectionsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'All collections up to date! No pending dues.'**
  String get allCollectionsUpToDate;

  /// No description provided for @totalInterest2Percent.
  ///
  /// In en, this message translates to:
  /// **'Total Interest (2%)'**
  String get totalInterest2Percent;

  /// No description provided for @outstandingPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Principal'**
  String get outstandingPrincipal;

  /// No description provided for @availableGroupBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Group Balance'**
  String get availableGroupBalance;

  /// No description provided for @monthlyRegisterBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Monthly Register Breakdown'**
  String get monthlyRegisterBreakdown;

  /// No description provided for @noCollectionRecordsForMonth.
  ///
  /// In en, this message translates to:
  /// **'No collection records for this month'**
  String get noCollectionRecordsForMonth;

  /// No description provided for @noLoansIssuedYet.
  ///
  /// In en, this message translates to:
  /// **'No loans issued yet'**
  String get noLoansIssuedYet;

  /// No description provided for @originalLoan.
  ///
  /// In en, this message translates to:
  /// **'Original Loan'**
  String get originalLoan;

  /// No description provided for @principalPaid.
  ///
  /// In en, this message translates to:
  /// **'Principal Paid'**
  String get principalPaid;

  /// No description provided for @interestPaid2Percent.
  ///
  /// In en, this message translates to:
  /// **'Interest Paid (2%)'**
  String get interestPaid2Percent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @repayments.
  ///
  /// In en, this message translates to:
  /// **'Repayments'**
  String get repayments;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refreshReport.
  ///
  /// In en, this message translates to:
  /// **'Refresh Report'**
  String get refreshReport;

  /// No description provided for @manageLoans.
  ///
  /// In en, this message translates to:
  /// **'Manage Loans'**
  String get manageLoans;

  /// No description provided for @activeLoansTab.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get activeLoansTab;

  /// No description provided for @closedLoansTab.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLoansTab;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @repaid.
  ///
  /// In en, this message translates to:
  /// **'Repaid'**
  String get repaid;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'mo'**
  String get perMonth;

  /// No description provided for @noLoansFound.
  ///
  /// In en, this message translates to:
  /// **'No loans found'**
  String get noLoansFound;

  /// No description provided for @loanDetails.
  ///
  /// In en, this message translates to:
  /// **'Loan Details'**
  String get loanDetails;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @currentMonthInterest2Percent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT MONTH INTEREST (2%)'**
  String get currentMonthInterest2Percent;

  /// No description provided for @monthlyInterestDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest due:'**
  String get monthlyInterestDue;

  /// No description provided for @repaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'REPAYMENT HISTORY'**
  String get repaymentHistory;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @noRepaymentsRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No repayments recorded yet'**
  String get noRepaymentsRecordedYet;

  /// No description provided for @interestPaid.
  ///
  /// In en, this message translates to:
  /// **'Interest Paid'**
  String get interestPaid;

  /// No description provided for @monthlyRate.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rate'**
  String get monthlyRate;

  /// No description provided for @closingBalance.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance'**
  String get closingBalance;

  /// No description provided for @recordLoanPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Loan Payment'**
  String get recordLoanPayment;

  /// No description provided for @principalRepaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Principal Repayment Amount (₹)'**
  String get principalRepaymentAmount;

  /// No description provided for @regularHaftaOptional.
  ///
  /// In en, this message translates to:
  /// **'Regular Hafta (Optional) (₹)'**
  String get regularHaftaOptional;

  /// No description provided for @totalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total Payment:'**
  String get totalPayment;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @principalCannotExceedPending.
  ///
  /// In en, this message translates to:
  /// **'Principal repayment cannot exceed pending principal'**
  String get principalCannotExceedPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
