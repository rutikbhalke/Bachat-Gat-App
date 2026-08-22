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
  /// **'Chhatrapati Bachat Gat, Ghargaon Stand'**
  String get defaultGroupName;

  /// No description provided for @monthlyHaftaDueDate.
  ///
  /// In en, this message translates to:
  /// **'Monthly Hafta Due Date'**
  String get monthlyHaftaDueDate;

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

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @partialStatus.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialStatus;

  /// No description provided for @selectMember.
  ///
  /// In en, this message translates to:
  /// **'Select Member'**
  String get selectMember;

  /// No description provided for @recordMonthlyCollection.
  ///
  /// In en, this message translates to:
  /// **'Record Monthly Collection'**
  String get recordMonthlyCollection;

  /// No description provided for @searchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members...'**
  String get searchMembers;

  /// No description provided for @allMembers.
  ///
  /// In en, this message translates to:
  /// **'All Members'**
  String get allMembers;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @memberProfile.
  ///
  /// In en, this message translates to:
  /// **'Member Profile'**
  String get memberProfile;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembers;

  /// No description provided for @groupSettingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Group Settings & Profile'**
  String get groupSettingsProfile;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @defaultMonthlyContribution.
  ///
  /// In en, this message translates to:
  /// **'Default Monthly Contribution'**
  String get defaultMonthlyContribution;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @loanManagement.
  ///
  /// In en, this message translates to:
  /// **'Loan Management'**
  String get loanManagement;

  /// No description provided for @monthlyCollection.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection'**
  String get monthlyCollection;

  /// No description provided for @loanRepayment.
  ///
  /// In en, this message translates to:
  /// **'Loan Repayment'**
  String get loanRepayment;

  /// No description provided for @loanInterest.
  ///
  /// In en, this message translates to:
  /// **'Loan Interest'**
  String get loanInterest;

  /// No description provided for @totalLoan.
  ///
  /// In en, this message translates to:
  /// **'Total Loan'**
  String get totalLoan;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @pendingMembers.
  ///
  /// In en, this message translates to:
  /// **'Pending Members'**
  String get pendingMembers;

  /// No description provided for @createLoan.
  ///
  /// In en, this message translates to:
  /// **'Create Loan'**
  String get createLoan;

  /// No description provided for @loanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get loanAmount;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Member'**
  String get editMember;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @updateMember.
  ///
  /// In en, this message translates to:
  /// **'Update Member'**
  String get updateMember;

  /// No description provided for @memberName.
  ///
  /// In en, this message translates to:
  /// **'Member Name'**
  String get memberName;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDate;

  /// No description provided for @defaultContribution.
  ///
  /// In en, this message translates to:
  /// **'Default Contribution'**
  String get defaultContribution;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @sharesCount.
  ///
  /// In en, this message translates to:
  /// **'Shares Count'**
  String get sharesCount;

  /// No description provided for @perShare.
  ///
  /// In en, this message translates to:
  /// **'Per Share'**
  String get perShare;

  /// No description provided for @regularHaftaLabel.
  ///
  /// In en, this message translates to:
  /// **'Regular Hafta (₹)'**
  String get regularHaftaLabel;

  /// No description provided for @totalPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Payment:'**
  String get totalPaymentLabel;

  /// No description provided for @loanPrincipalRepaymentOptional.
  ///
  /// In en, this message translates to:
  /// **'Loan Principal Repayment (₹) (Optional)'**
  String get loanPrincipalRepaymentOptional;

  /// No description provided for @activeLoan.
  ///
  /// In en, this message translates to:
  /// **'Active Loan'**
  String get activeLoan;

  /// No description provided for @interestDue.
  ///
  /// In en, this message translates to:
  /// **'Interest Due'**
  String get interestDue;

  /// No description provided for @loanAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount (₹)'**
  String get loanAmountLabel;

  /// No description provided for @monthlyInterestRatePercent.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest Rate (%)'**
  String get monthlyInterestRatePercent;

  /// No description provided for @purposeOptional.
  ///
  /// In en, this message translates to:
  /// **'Purpose (optional)'**
  String get purposeOptional;

  /// No description provided for @availableForLending.
  ///
  /// In en, this message translates to:
  /// **'Available for Lending'**
  String get availableForLending;

  /// No description provided for @maxAllowed.
  ///
  /// In en, this message translates to:
  /// **'Max allowed'**
  String get maxAllowed;

  /// No description provided for @selectActiveLoan.
  ///
  /// In en, this message translates to:
  /// **'Select Active Loan'**
  String get selectActiveLoan;

  /// No description provided for @regularHaftaAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Regular Hafta Amount (₹)'**
  String get regularHaftaAmountLabel;

  /// No description provided for @interestLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interestLabel;

  /// No description provided for @totalInvested.
  ///
  /// In en, this message translates to:
  /// **'Total Invested'**
  String get totalInvested;

  /// No description provided for @outstandingLoan.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Loan'**
  String get outstandingLoan;

  /// No description provided for @investmentHistory.
  ///
  /// In en, this message translates to:
  /// **'INVESTMENT HISTORY'**
  String get investmentHistory;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get noHistoryFound;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @groupSummary.
  ///
  /// In en, this message translates to:
  /// **'GROUP SUMMARY'**
  String get groupSummary;

  /// No description provided for @monthlyPerformance.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY PERFORMANCE'**
  String get monthlyPerformance;

  /// No description provided for @savingsGrowthChart.
  ///
  /// In en, this message translates to:
  /// **'Savings Growth Chart'**
  String get savingsGrowthChart;

  /// No description provided for @comingInNextUpdate.
  ///
  /// In en, this message translates to:
  /// **'Coming in next update'**
  String get comingInNextUpdate;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @monthlyCollectionDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Collection Due'**
  String get monthlyCollectionDue;

  /// No description provided for @collectionScheduledTenth.
  ///
  /// In en, this message translates to:
  /// **'Monthly savings collection scheduled on the 10th.'**
  String get collectionScheduledTenth;

  /// No description provided for @interestRule2Percent.
  ///
  /// In en, this message translates to:
  /// **'2% Monthly Interest Rule'**
  String get interestRule2Percent;

  /// No description provided for @interestCalculatedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Interest is calculated automatically on outstanding principal.'**
  String get interestCalculatedAutomatically;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @settingsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Settings updated successfully'**
  String get settingsUpdatedSuccessfully;

  /// No description provided for @perShareAmount.
  ///
  /// In en, this message translates to:
  /// **'per share'**
  String get perShareAmount;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @noPendingMembersMatch.
  ///
  /// In en, this message translates to:
  /// **'No pending members match search'**
  String get noPendingMembersMatch;

  /// No description provided for @moInterestLabel.
  ///
  /// In en, this message translates to:
  /// **'2% Mo. Interest'**
  String get moInterestLabel;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get overdue;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'DUE'**
  String get due;

  /// No description provided for @issued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issued;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @monthlyInterestLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest (2%)'**
  String get monthlyInterestLabel;

  /// No description provided for @failedLoadLedger.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ledger'**
  String get failedLoadLedger;

  /// No description provided for @noLedgerEntries.
  ///
  /// In en, this message translates to:
  /// **'No ledger entries recorded'**
  String get noLedgerEntries;

  /// No description provided for @deactivateMember.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Member'**
  String get deactivateMember;

  /// No description provided for @deactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate {name}?'**
  String deactivateConfirm(Object name);

  /// No description provided for @noCollectionHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No collection history found'**
  String get noCollectionHistoryFound;

  /// No description provided for @noLoansIssuedForMember.
  ///
  /// In en, this message translates to:
  /// **'No loans issued for this member'**
  String get noLoansIssuedForMember;
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
