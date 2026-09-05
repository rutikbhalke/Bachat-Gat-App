import 'member.dart';
import 'loan.dart';

class MemberMonthlyReport {
  final Member member;
  final int month;
  final int year;
  
  // Contribution data
  final double expectedHafta;
  final double paidHafta;
  final double pendingHafta;
  
  // Loan data
  final String? loanId;
  final double openingPrincipal;
  final double interestRate;
  final double interestAmount;
  final double principalRepaid;
  final double closingPrincipal;
  final double pendingInterest;
  
  final double totalPaid;

  MemberMonthlyReport({
    required this.member,
    required this.month,
    required this.year,
    required this.expectedHafta,
    required this.paidHafta,
    required this.pendingHafta,
    this.loanId,
    this.openingPrincipal = 0.0,
    this.interestRate = 0.0,
    this.interestAmount = 0.0,
    this.principalRepaid = 0.0,
    this.closingPrincipal = 0.0,
    this.pendingInterest = 0.0,
    required this.totalPaid,
  });

  double get pendingLoanPrincipal => closingPrincipal;
  double get totalPending => pendingHafta + pendingInterest + closingPrincipal;
  bool get hasPendingDues => totalPending > 0;
}

class GroupMonthlyReport {
  final String groupName;
  final int month;
  final int year;
  final int totalMembers;
  
  final List<MemberMonthlyReport> memberReports;
  
  // Aggregates
  final double totalExpectedHafta;
  final double totalCollectedHafta;
  final double totalPendingHafta;
  
  final double totalActiveLoans;
  final double totalPrincipalRepaid;
  final double totalInterestCollected;
  final double totalOutstandingLoan;
  
  final double totalCollection; // Hafta + Principal + Interest
  final double totalPendingPrincipal;
  final double totalPendingInterest;
  final double totalOverallPending;

  GroupMonthlyReport({
    required this.groupName,
    required this.month,
    required this.year,
    required this.totalMembers,
    required this.memberReports,
    required this.totalExpectedHafta,
    required this.totalCollectedHafta,
    required this.totalPendingHafta,
    required this.totalActiveLoans,
    required this.totalPrincipalRepaid,
    required this.totalInterestCollected,
    required this.totalOutstandingLoan,
    required this.totalCollection,
    double? totalPendingPrincipal,
    double? totalPendingInterest,
    double? totalOverallPending,
  })  : totalPendingPrincipal = totalPendingPrincipal ?? totalOutstandingLoan,
        totalPendingInterest = totalPendingInterest ?? 0.0,
        totalOverallPending = totalOverallPending ?? (totalPendingHafta + totalOutstandingLoan);
}

class PendingMemberReport {
  final Member member;
  final double pendingHafta;
  final double pendingLoanPrincipal;
  final double pendingInterest;
  final double totalPending;
  final int month;
  final int year;
  final List<Loan> activeLoans;
  final double expectedHafta;
  final bool isHaftaPaid;
  final double currentMonthInterest;
  final double totalLoanPending;
  final bool hasActiveLoan;

  PendingMemberReport({
    required this.member,
    required this.pendingHafta,
    double? pendingLoanPrincipal,
    double? pendingInterest,
    double? totalPending,
    int? month,
    int? year,
    this.activeLoans = const [],
    double? expectedHafta,
    bool? isHaftaPaid,
    double? currentMonthInterest,
    double? totalLoanPending,
    double? totalDue,
    bool? hasActiveLoan,
  })  : pendingLoanPrincipal = pendingLoanPrincipal ?? totalLoanPending ?? 0.0,
        pendingInterest = pendingInterest ?? currentMonthInterest ?? 0.0,
        totalPending = totalPending ?? totalDue ?? (pendingHafta + (pendingInterest ?? currentMonthInterest ?? 0.0)),
        month = month ?? DateTime.now().month,
        year = year ?? DateTime.now().year,
        expectedHafta = expectedHafta ?? member.monthlyContribution,
        isHaftaPaid = isHaftaPaid ?? (pendingHafta <= 0),
        currentMonthInterest = currentMonthInterest ?? pendingInterest ?? 0.0,
        totalLoanPending = totalLoanPending ?? pendingLoanPrincipal ?? 0.0,
        hasActiveLoan = hasActiveLoan ?? activeLoans.isNotEmpty;

  double get totalDue => totalPending;
}

class MemberLedgerEntry {
  final String id;
  final DateTime date;
  final String type;
  final String description;
  final double debit; // Outflow / Loan taken / Expected charge
  final double credit; // Inflow / Payment made
  final double balance; // Running balance / Outstanding position
  final String? referenceId;

  MemberLedgerEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    required this.balance,
    this.referenceId,
  });
}

class LoanReportItem {
  final Loan loan;
  final Member member;
  final double totalPrincipalPaid;
  final double totalInterestPaid;
  final double currentPendingPrincipal;
  final double currentMonthInterest;
  final double totalPendingAmount;
  final int repaymentCount;

  LoanReportItem({
    required this.loan,
    required this.member,
    required this.totalPrincipalPaid,
    required this.totalInterestPaid,
    required this.currentPendingPrincipal,
    required this.currentMonthInterest,
    required this.totalPendingAmount,
    required this.repaymentCount,
  });
}
