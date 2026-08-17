import 'member.dart';

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
    required this.totalPaid,
  });
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
  });
}
