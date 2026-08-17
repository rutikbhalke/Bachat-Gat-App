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
