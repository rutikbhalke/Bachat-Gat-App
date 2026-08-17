import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/report_models.dart';
import '../models/transaction.dart';
import '../services/firebase_service.dart';
import '../core/utils/calculation_utils.dart';

class ReportService {
  final FirebaseService _firebaseService;

  ReportService(this._firebaseService);

  Future<MemberMonthlyReport> getMemberMonthlyReport({
    required String groupId,
    required Member member,
    required int month,
    required int year,
  }) async {
    // 1. Fetch contribution for this month
    final savingsSnapshot = await _firebaseService.monthlyContributions(groupId)
        .where('memberId', isEqualTo: member.id)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    MonthlyContribution? contribution;
    if (savingsSnapshot.docs.isNotEmpty) {
      contribution = MonthlyContribution.fromJson(savingsSnapshot.docs.first.data() as Map<String, dynamic>);
    }

    // 2. Fetch loan info for this member
    final loansSnapshot = await _firebaseService.loans(groupId)
        .where('memberId', isEqualTo: member.id)
        .get();

    final allLoans = loansSnapshot.docs.map((doc) => Loan.fromJson(doc.data() as Map<String, dynamic>)).toList();
    
    // Find active loan as of the report period
    Loan? targetLoan;
    for (var loan in allLoans) {
      final loanStart = DateTime(loan.loanDate.year, loan.loanDate.month);
      final reportDate = DateTime(year, month);
      
      if (loanStart.isBefore(reportDate) || loanStart.isAtSameMomentAs(reportDate)) {
        if (loan.status == LoanStatus.closed) {
          final loanEnd = DateTime(loan.updatedAt.year, loan.updatedAt.month);
          if (loanEnd.isAfter(reportDate) || loanEnd.isAtSameMomentAs(reportDate)) {
            targetLoan = loan;
            break;
          }
        } else {
          targetLoan = loan;
          break;
        }
      }
    }

    double openingPrincipal = 0.0;
    double interestRate = 2.0; // Default 2% per month
    double interestAmount = 0.0;
    double principalRepaid = 0.0;
    double closingPrincipal = 0.0;

    if (targetLoan != null) {
      interestRate = targetLoan.interestRate;
      
      // Check if there is an explicit repayment record for this period
      final repaymentSnapshot = await _firebaseService.loanRepayments(groupId)
          .where('loanId', isEqualTo: targetLoan.id)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (repaymentSnapshot.docs.isNotEmpty) {
        final r = LoanRepayment.fromJson(repaymentSnapshot.docs.first.data() as Map<String, dynamic>);
        openingPrincipal = r.openingPrincipal;
        interestAmount = r.interestAmount;
        principalRepaid = r.principalRepaid;
        closingPrincipal = r.closingPrincipal;
      } else {
        // Calculate based on previous repayments up to before this month
        final previousRepayments = await _firebaseService.loanRepayments(groupId)
            .where('loanId', isEqualTo: targetLoan.id)
            .get();

        final sortedRepayments = previousRepayments.docs
            .map((doc) => LoanRepayment.fromJson(doc.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => (a.year * 12 + a.month).compareTo(b.year * 12 + b.month));

        double lastClosing = targetLoan.originalPrincipal;
        for (var r in sortedRepayments) {
          if (r.year < year || (r.year == year && r.month < month)) {
            lastClosing = r.closingPrincipal;
          } else {
            break;
          }
        }
        
        openingPrincipal = lastClosing;
        if (openingPrincipal > 0) {
          interestAmount = CalculationUtils.calculateMonthlyInterest(
            outstandingPrincipal: openingPrincipal,
            annualRate: interestRate,
          );
        }
        closingPrincipal = openingPrincipal;
      }
    }

    final paidHafta = contribution != null ? contribution.regularHaftaAmount : 0.0;
    final expectedHafta = contribution?.expectedAmount ?? member.monthlyContribution;
    final pendingHafta = (expectedHafta - paidHafta) > 0 ? (expectedHafta - paidHafta) : 0.0;
    
    return MemberMonthlyReport(
      member: member,
      month: month,
      year: year,
      expectedHafta: expectedHafta,
      paidHafta: paidHafta,
      pendingHafta: pendingHafta,
      loanId: targetLoan?.id,
      openingPrincipal: openingPrincipal,
      interestRate: interestRate,
      interestAmount: interestAmount,
      principalRepaid: principalRepaid,
      closingPrincipal: closingPrincipal,
      pendingInterest: (targetLoan != null && principalRepaid == 0 && interestAmount > 0 && (contribution == null || contribution.interestAmount == 0)) ? interestAmount : 0.0,
      totalPaid: paidHafta + principalRepaid + (contribution?.interestAmount ?? interestAmount),
    );
  }

  Future<GroupMonthlyReport> getGroupMonthlyReport({
    required String groupId,
    required String groupName,
    required int month,
    required int year,
  }) async {
    final membersSnapshot = await _firebaseService.members(groupId).get();
    final members = membersSnapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();

    List<MemberMonthlyReport> memberReports = [];
    for (var member in members) {
      final report = await getMemberMonthlyReport(groupId: groupId, member: member, month: month, year: year);
      memberReports.add(report);
    }

    double totalExpectedHafta = memberReports.fold(0.0, (val, r) => val + r.expectedHafta);
    double totalCollectedHafta = memberReports.fold(0.0, (val, r) => val + r.paidHafta);
    double totalPendingHafta = memberReports.fold(0.0, (val, r) => val + r.pendingHafta);
    
    double totalActiveLoans = memberReports.where((r) => r.openingPrincipal > 0).fold(0.0, (val, r) => val + r.openingPrincipal);
    double totalPrincipalRepaid = memberReports.fold(0.0, (val, r) => val + r.principalRepaid);
    double totalInterestCollected = memberReports.fold(0.0, (val, r) => val + r.interestAmount);
    double totalOutstandingLoan = memberReports.fold(0.0, (val, r) => val + r.closingPrincipal);
    double totalPendingInterest = memberReports.fold(0.0, (val, r) => val + r.pendingInterest);
    
    return GroupMonthlyReport(
      groupName: groupName,
      month: month,
      year: year,
      totalMembers: members.length,
      memberReports: memberReports,
      totalExpectedHafta: totalExpectedHafta,
      totalCollectedHafta: totalCollectedHafta,
      totalPendingHafta: totalPendingHafta,
      totalActiveLoans: totalActiveLoans,
      totalPrincipalRepaid: totalPrincipalRepaid,
      totalInterestCollected: totalInterestCollected,
      totalOutstandingLoan: totalOutstandingLoan,
      totalCollection: totalCollectedHafta + totalPrincipalRepaid + totalInterestCollected,
      totalPendingPrincipal: totalOutstandingLoan,
      totalPendingInterest: totalPendingInterest,
      totalOverallPending: totalPendingHafta + totalOutstandingLoan + totalPendingInterest,
    );
  }

  Future<List<PendingMemberReport>> getPendingReport({
    required String groupId,
    int? month,
    int? year,
    String? memberId,
  }) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    Query membersQuery = _firebaseService.members(groupId).where('status', isEqualTo: 'active');
    if (memberId != null) {
      membersQuery = _firebaseService.members(groupId).where('id', isEqualTo: memberId);
    }
    final membersSnapshot = await membersQuery.get();
    final members = membersSnapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();

    List<PendingMemberReport> pendingList = [];
    for (var member in members) {
      final report = await getMemberMonthlyReport(groupId: groupId, member: member, month: targetMonth, year: targetYear);
      if (report.hasPendingDues) {
        final loansSnap = await _firebaseService.loans(groupId)
            .where('memberId', isEqualTo: member.id)
            .where('status', isEqualTo: LoanStatus.active.name)
            .get();
        final activeLoans = loansSnap.docs.map((d) => Loan.fromJson(d.data() as Map<String, dynamic>)).toList();

        pendingList.add(PendingMemberReport(
          member: member,
          pendingHafta: report.pendingHafta,
          pendingLoanPrincipal: report.closingPrincipal,
          pendingInterest: report.pendingInterest,
          totalPending: report.totalPending,
          month: targetMonth,
          year: targetYear,
          activeLoans: activeLoans,
        ));
      }
    }
    return pendingList;
  }

  Future<List<LoanReportItem>> getLoanReport({
    required String groupId,
    LoanStatus? statusFilter,
  }) async {
    Query loansQuery = _firebaseService.loans(groupId);
    if (statusFilter != null) {
      loansQuery = loansQuery.where('status', isEqualTo: statusFilter.name);
    }
    final loansSnap = await loansQuery.get();
    final loans = loansSnap.docs.map((d) => Loan.fromJson(d.data() as Map<String, dynamic>)).toList();

    final membersSnap = await _firebaseService.members(groupId).get();
    final membersMap = {for (var doc in membersSnap.docs) doc.id: Member.fromJson(doc.data() as Map<String, dynamic>)};

    List<LoanReportItem> reportItems = [];
    for (var loan in loans) {
      final repaymentsSnap = await _firebaseService.loanRepayments(groupId).where('loanId', isEqualTo: loan.id).get();
      final repayments = repaymentsSnap.docs.map((d) => LoanRepayment.fromJson(d.data() as Map<String, dynamic>)).toList();

      final totalPrincipalPaid = repayments.fold<double>(0.0, (total, r) => total + r.principalRepaid);
      final totalInterestPaid = repayments.fold<double>(0.0, (total, r) => total + r.interestAmount);
      final currentPending = loan.pendingPrincipal;
      final currentInterest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: currentPending,
        annualRate: loan.interestRate,
      );

      final member = membersMap[loan.memberId] ?? Member(
        id: loan.memberId,
        groupId: groupId,
        name: 'Member',
        phone: '',
        joinDate: loan.loanDate,
        monthlyContribution: 1000,
        createdAt: loan.createdAt,
        updatedAt: loan.updatedAt,
      );

      reportItems.add(LoanReportItem(
        loan: loan,
        member: member,
        totalPrincipalPaid: totalPrincipalPaid,
        totalInterestPaid: totalInterestPaid,
        currentPendingPrincipal: currentPending,
        currentMonthInterest: currentInterest,
        totalPendingAmount: currentPending + (loan.status == LoanStatus.active ? currentInterest : 0.0),
        repaymentCount: repayments.length,
      ));
    }
    return reportItems;
  }

  Future<List<MemberLedgerEntry>> getMemberLedger({
    required String groupId,
    required String memberId,
  }) async {
    final activitiesSnap = await _firebaseService.activities(groupId)
        .where('memberId', isEqualTo: memberId)
        .get();
    
    final activities = activitiesSnap.docs
        .map((doc) => AppTransaction.fromJson(doc.data() as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0.0;
    List<MemberLedgerEntry> entries = [];

    for (var tx in activities) {
      double debit = 0.0;
      double credit = 0.0;

      switch (tx.type) {
        case TransactionType.monthlyInvestment:
          credit = tx.amount; // Member deposited savings
          runningBalance += credit;
          break;
        case TransactionType.loanIssue:
          debit = tx.amount; // Member borrowed loan
          runningBalance -= debit;
          break;
        case TransactionType.loanRepayment:
        case TransactionType.interestPayment:
          credit = tx.amount; // Member repaid loan/interest
          runningBalance += credit;
          break;
        case TransactionType.adjustment:
        case TransactionType.otherIncome:
          credit = tx.amount;
          runningBalance += credit;
          break;
        case TransactionType.otherExpense:
          debit = tx.amount;
          runningBalance -= debit;
          break;
      }

      entries.add(MemberLedgerEntry(
        id: tx.id,
        date: tx.date,
        type: tx.type.name,
        description: tx.description ?? tx.type.name,
        debit: debit,
        credit: credit,
        balance: runningBalance,
        referenceId: tx.referenceId,
      ));
    }

    return entries;
  }
}
