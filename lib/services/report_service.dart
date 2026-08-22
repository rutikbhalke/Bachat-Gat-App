import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/member.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/report_models.dart';
import '../models/transaction.dart';
import '../services/firebase_service.dart';
import '../core/utils/calculation_utils.dart';
import '../core/utils/perf_logger.dart';

class ReportService {
  final FirebaseService _firebaseService;

  // In-memory cache for fast tab navigation & repeated requests
  final Map<String, GroupMonthlyReport> _groupReportCache = {};
  final Map<String, List<PendingMemberReport>> _pendingReportCache = {};
  final Map<String, List<LoanReportItem>> _loanReportCache = {};
  final Map<String, List<MemberLedgerEntry>> _memberLedgerCache = {};

  ReportService(this._firebaseService);

  /// Clears all cached reports and ledger data.
  /// Should be called after any contribution, loan, repayment, or member mutation.
  void invalidateCache() {
    _groupReportCache.clear();
    _pendingReportCache.clear();
    _loanReportCache.clear();
    _memberLedgerCache.clear();
    debugPrint('[REPORT] Report cache invalidated');
  }

  /// Calculates MemberMonthlyReport synchronously in-memory using pre-fetched collections.
  MemberMonthlyReport _computeMemberMonthlyReportFromData({
    required Member member,
    required int month,
    required int year,
    MonthlyContribution? contribution,
    required List<Loan> memberLoans,
    required Map<String, List<LoanRepayment>> repaymentsByLoanId,
  }) {
    // Find active loan as of the report period
    Loan? targetLoan;
    final reportDate = DateTime(year, month);

    for (var loan in memberLoans) {
      final loanStart = DateTime(loan.loanDate.year, loan.loanDate.month);

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
      final loanRepayments = repaymentsByLoanId[targetLoan.id] ?? const [];

      // Check if there is an explicit repayment record for this period
      final matchingRepayments = loanRepayments.where((r) => r.month == month && r.year == year);
      final periodRepayment = matchingRepayments.isNotEmpty ? matchingRepayments.first : null;

      if (periodRepayment != null) {
        openingPrincipal = periodRepayment.openingPrincipal;
        interestAmount = periodRepayment.interestAmount;
        principalRepaid = periodRepayment.principalRepaid;
        closingPrincipal = periodRepayment.closingPrincipal;
      } else {
        // Calculate based on previous repayments up to before this month
        final sortedRepayments = List<LoanRepayment>.from(loanRepayments)
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

    final paidHafta = CalculationUtils.calculateMemberPaidForMonth(contribution);
    final expectedHafta = CalculationUtils.calculateMemberMonthlyDue(member: member);
    final pendingHafta = CalculationUtils.calculateMemberPendingHafta(
      member: member,
      contribution: contribution,
    );

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
      pendingInterest: (targetLoan != null &&
              principalRepaid == 0 &&
              interestAmount > 0 &&
              (contribution == null || contribution.interestAmount == 0))
          ? interestAmount
          : 0.0,
      totalPaid: paidHafta + principalRepaid + (contribution?.interestAmount ?? interestAmount),
    );
  }

  /// Generates a single member's monthly report with parallel queries.
  Future<MemberMonthlyReport> getMemberMonthlyReport({
    required String groupId,
    required Member member,
    required int month,
    required int year,
  }) async {
    return PerfLogger.traceAsync('getMemberMonthlyReport(${member.id}, $month/$year)', () async {
      debugPrint('[REPORT] getMemberMonthlyReport START: member=${member.name}, $month/$year');
      try {
        final futures = await Future.wait<QuerySnapshot>([
          _firebaseService
              .monthlyContributions(groupId)
              .where('memberId', isEqualTo: member.id)
              .where('month', isEqualTo: month)
              .where('year', isEqualTo: year)
              .limit(1)
              .get(),
          _firebaseService
              .loans(groupId)
              .where('memberId', isEqualTo: member.id)
              .get(),
          _firebaseService
              .loanRepayments(groupId)
              .where('memberId', isEqualTo: member.id)
              .get(),
        ]);

        final savingsSnapshot = futures[0];
        final loansSnapshot = futures[1];
        final repaymentsSnapshot = futures[2];

        MonthlyContribution? contribution;
        if (savingsSnapshot.docs.isNotEmpty) {
          contribution = MonthlyContribution.fromJson(savingsSnapshot.docs.first.data() as Map<String, dynamic>);
        }

        final allLoans = loansSnapshot.docs.map((doc) => Loan.fromJson(doc.data() as Map<String, dynamic>)).toList();
        final allRepayments = repaymentsSnapshot.docs.map((doc) => LoanRepayment.fromJson(doc.data() as Map<String, dynamic>)).toList();

        final repaymentsByLoanId = <String, List<LoanRepayment>>{};
        for (var r in allRepayments) {
          repaymentsByLoanId.putIfAbsent(r.loanId, () => []).add(r);
        }

        final report = _computeMemberMonthlyReportFromData(
          member: member,
          month: month,
          year: year,
          contribution: contribution,
          memberLoans: allLoans,
          repaymentsByLoanId: repaymentsByLoanId,
        );
        debugPrint('[REPORT] getMemberMonthlyReport END: member=${member.name}, totalPaid=${report.totalPaid}');
        return report;
      } catch (e, stack) {
        debugPrint('[REPORT ERROR] getMemberMonthlyReport FAILED: $e\n$stack');
        rethrow;
      }
    });
  }

  /// Generates GroupMonthlyReport with parallel bulk queries and O(1) in-memory aggregation.
  Future<GroupMonthlyReport> getGroupMonthlyReport({
    required String groupId,
    required String groupName,
    required int month,
    required int year,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$groupId-$month-$year';
    if (!forceRefresh && _groupReportCache.containsKey(cacheKey)) {
      debugPrint('[REPORT] getGroupMonthlyReport CACHE HIT for $cacheKey');
      return _groupReportCache[cacheKey]!;
    }

    return PerfLogger.traceAsync('getGroupMonthlyReport($month/$year)', () async {
      debugPrint('[REPORT] MONTHLY REGISTER START: groupId=$groupId, groupName=$groupName, month=$month, year=$year');
      try {
        debugPrint('[REPORT] MEMBERS QUERY START (path: groups/$groupId/members)');
        debugPrint('[REPORT] CONTRIBUTIONS QUERY START (path: groups/$groupId/monthly_contributions)');
        debugPrint('[REPORT] LOANS QUERY START (path: groups/$groupId/loans)');
        debugPrint('[REPORT] REPAYMENTS QUERY START (path: groups/$groupId/loan_repayments)');

        // Execute 4 bulk queries concurrently
        final futures = await Future.wait<QuerySnapshot>([
          _firebaseService.members(groupId).get(),
          _firebaseService
              .monthlyContributions(groupId)
              .where('month', isEqualTo: month)
              .where('year', isEqualTo: year)
              .get(),
          _firebaseService.loans(groupId).get(),
          _firebaseService.loanRepayments(groupId).get(),
        ]);

        final membersSnapshot = futures[0];
        final contributionsSnapshot = futures[1];
        final loansSnapshot = futures[2];
        final repaymentsSnapshot = futures[3];

        debugPrint('[REPORT] MEMBERS QUERY END: ${membersSnapshot.docs.length} docs');
        debugPrint('[REPORT] CONTRIBUTIONS QUERY END: ${contributionsSnapshot.docs.length} docs');
        debugPrint('[REPORT] LOANS QUERY END: ${loansSnapshot.docs.length} docs');
        debugPrint('[REPORT] REPAYMENTS QUERY END: ${repaymentsSnapshot.docs.length} docs');

        debugPrint('[REPORT] REPORT CALCULATION START');

        final members = membersSnapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();

        // Build lookup maps in O(N)
        final contributionsByMember = <String, MonthlyContribution>{};
        for (var doc in contributionsSnapshot.docs) {
          try {
            final c = MonthlyContribution.fromJson(doc.data() as Map<String, dynamic>);
            contributionsByMember[c.memberId] = c;
          } catch (e) {
            debugPrint('[REPORT ERROR] Failed to parse contribution ${doc.id}: $e');
          }
        }

        final loansByMember = <String, List<Loan>>{};
        for (var doc in loansSnapshot.docs) {
          try {
            final l = Loan.fromJson(doc.data() as Map<String, dynamic>);
            loansByMember.putIfAbsent(l.memberId, () => []).add(l);
          } catch (e) {
            debugPrint('[REPORT ERROR] Failed to parse loan ${doc.id}: $e');
          }
        }

        final repaymentsByLoanId = <String, List<LoanRepayment>>{};
        for (var doc in repaymentsSnapshot.docs) {
          try {
            final r = LoanRepayment.fromJson(doc.data() as Map<String, dynamic>);
            repaymentsByLoanId.putIfAbsent(r.loanId, () => []).add(r);
          } catch (e) {
            debugPrint('[REPORT ERROR] Failed to parse repayment ${doc.id}: $e');
          }
        }

        // Compute all member reports in memory
        final memberReports = <MemberMonthlyReport>[];
        for (var member in members) {
          final report = _computeMemberMonthlyReportFromData(
            member: member,
            month: month,
            year: year,
            contribution: contributionsByMember[member.id],
            memberLoans: loansByMember[member.id] ?? const [],
            repaymentsByLoanId: repaymentsByLoanId,
          );
          memberReports.add(report);
        }

        final totalExpectedHafta = memberReports.fold<double>(0.0, (val, r) => val + r.expectedHafta);
        final totalCollectedHafta = memberReports.fold<double>(0.0, (val, r) => val + r.paidHafta);
        final totalPendingHafta = memberReports.fold<double>(0.0, (val, r) => val + r.pendingHafta);

        final totalActiveLoans = memberReports.where((r) => r.openingPrincipal > 0).fold<double>(0.0, (val, r) => val + r.openingPrincipal);
        final totalPrincipalRepaid = memberReports.fold<double>(0.0, (val, r) => val + r.principalRepaid);
        final totalInterestCollected = memberReports.fold<double>(0.0, (val, r) => val + r.interestAmount);
        final totalOutstandingLoan = memberReports.fold<double>(0.0, (val, r) => val + r.closingPrincipal);
        final totalPendingInterest = memberReports.fold<double>(0.0, (val, r) => val + r.pendingInterest);

        final result = GroupMonthlyReport(
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

        debugPrint('[REPORT] REPORT CALCULATION END: totalMembers=${result.totalMembers}, totalCollection=${result.totalCollection}');
        debugPrint('[REPORT] UI STATE = SUCCESS (Monthly Register)');

        _groupReportCache[cacheKey] = result;
        return result;
      } catch (e, stack) {
        debugPrint('[REPORT ERROR] getGroupMonthlyReport FAILED: $e\n$stack');
        rethrow;
      }
    });
  }

  /// Generates PendingMemberReport list with parallel queries and in-memory evaluation.
  Future<List<PendingMemberReport>> getPendingReport({
    required String groupId,
    int? month,
    int? year,
    String? memberId,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;
    final cacheKey = '$groupId-$targetMonth-$targetYear-${memberId ?? 'all'}';

    if (!forceRefresh && _pendingReportCache.containsKey(cacheKey)) {
      debugPrint('[REPORT] getPendingReport CACHE HIT for $cacheKey');
      return _pendingReportCache[cacheKey]!;
    }

    return PerfLogger.traceAsync('getPendingReport($targetMonth/$targetYear)', () async {
      debugPrint('[REPORT] PENDING DUES REPORT START: groupId=$groupId, month=$targetMonth, year=$targetYear');
      try {
        Query membersQuery = _firebaseService.members(groupId).where('status', isEqualTo: 'active');
        if (memberId != null) {
          membersQuery = _firebaseService.members(groupId).where('id', isEqualTo: memberId);
        }

        // Parallel bulk fetch
        final futures = await Future.wait<QuerySnapshot>([
          membersQuery.get(),
          _firebaseService
              .monthlyContributions(groupId)
              .where('month', isEqualTo: targetMonth)
              .where('year', isEqualTo: targetYear)
              .get(),
          _firebaseService.loans(groupId).get(),
          _firebaseService.loanRepayments(groupId).get(),
        ]);

        final membersSnapshot = futures[0];
        final contributionsSnapshot = futures[1];
        final loansSnapshot = futures[2];
        final repaymentsSnapshot = futures[3];

        debugPrint('[REPORT] PENDING MEMBERS QUERY END: ${membersSnapshot.docs.length} docs');
        debugPrint('[REPORT] PENDING CONTRIBUTIONS QUERY END: ${contributionsSnapshot.docs.length} docs');
        debugPrint('[REPORT] PENDING LOANS QUERY END: ${loansSnapshot.docs.length} docs');
        debugPrint('[REPORT] PENDING REPAYMENTS QUERY END: ${repaymentsSnapshot.docs.length} docs');

        final members = membersSnapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();

        final contributionsByMember = <String, MonthlyContribution>{};
        for (var doc in contributionsSnapshot.docs) {
          try {
            final c = MonthlyContribution.fromJson(doc.data() as Map<String, dynamic>);
            contributionsByMember[c.memberId] = c;
          } catch (e) {
            debugPrint('[REPORT ERROR] Parse contribution error ${doc.id}: $e');
          }
        }

        final loansByMember = <String, List<Loan>>{};
        for (var doc in loansSnapshot.docs) {
          try {
            final l = Loan.fromJson(doc.data() as Map<String, dynamic>);
            loansByMember.putIfAbsent(l.memberId, () => []).add(l);
          } catch (e) {
            debugPrint('[REPORT ERROR] Parse loan error ${doc.id}: $e');
          }
        }

        final repaymentsByLoanId = <String, List<LoanRepayment>>{};
        for (var doc in repaymentsSnapshot.docs) {
          try {
            final r = LoanRepayment.fromJson(doc.data() as Map<String, dynamic>);
            repaymentsByLoanId.putIfAbsent(r.loanId, () => []).add(r);
          } catch (e) {
            debugPrint('[REPORT ERROR] Parse repayment error ${doc.id}: $e');
          }
        }

        final pendingList = <PendingMemberReport>[];
        for (var member in members) {
          final report = _computeMemberMonthlyReportFromData(
            member: member,
            month: targetMonth,
            year: targetYear,
            contribution: contributionsByMember[member.id],
            memberLoans: loansByMember[member.id] ?? const [],
            repaymentsByLoanId: repaymentsByLoanId,
          );

          if (report.hasPendingDues) {
            final memberActiveLoans = (loansByMember[member.id] ?? const [])
                .where((l) => l.status == LoanStatus.active)
                .toList();

            pendingList.add(PendingMemberReport(
              member: member,
              pendingHafta: report.pendingHafta,
              pendingLoanPrincipal: report.closingPrincipal,
              pendingInterest: report.pendingInterest,
              totalPending: report.totalPending,
              month: targetMonth,
              year: targetYear,
              activeLoans: memberActiveLoans,
            ));
          }
        }

        debugPrint('[REPORT] PENDING REPORT CALCULATION END: ${pendingList.length} members with pending dues');
        debugPrint('[REPORT] UI STATE = SUCCESS (Pending Dues)');

        _pendingReportCache[cacheKey] = pendingList;
        return pendingList;
      } catch (e, stack) {
        debugPrint('[REPORT ERROR] getPendingReport FAILED: $e\n$stack');
        rethrow;
      }
    });
  }

  /// Generates LoanReportItem list with parallel bulk queries.
  Future<List<LoanReportItem>> getLoanReport({
    required String groupId,
    LoanStatus? statusFilter,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$groupId-${statusFilter?.name ?? 'all'}';
    if (!forceRefresh && _loanReportCache.containsKey(cacheKey)) {
      debugPrint('[REPORT] getLoanReport CACHE HIT for $cacheKey');
      return _loanReportCache[cacheKey]!;
    }

    return PerfLogger.traceAsync('getLoanReport(${statusFilter?.name ?? 'all'})', () async {
      debugPrint('[REPORT] LOANS OVERVIEW REPORT START: groupId=$groupId, statusFilter=$statusFilter');
      try {
        Query loansQuery = _firebaseService.loans(groupId);
        if (statusFilter != null) {
          loansQuery = loansQuery.where('status', isEqualTo: statusFilter.name);
        }

        final futures = await Future.wait<QuerySnapshot>([
          loansQuery.get(),
          _firebaseService.members(groupId).get(),
          _firebaseService.loanRepayments(groupId).get(),
        ]);

        final loansSnap = futures[0];
        final membersSnap = futures[1];
        final repaymentsSnap = futures[2];

        debugPrint('[REPORT] LOANS OVERVIEW LOANS END: ${loansSnap.docs.length} docs');
        debugPrint('[REPORT] LOANS OVERVIEW MEMBERS END: ${membersSnap.docs.length} docs');
        debugPrint('[REPORT] LOANS OVERVIEW REPAYMENTS END: ${repaymentsSnap.docs.length} docs');

        final loans = loansSnap.docs.map((d) => Loan.fromJson(d.data() as Map<String, dynamic>)).toList();
        final membersMap = {for (var doc in membersSnap.docs) doc.id: Member.fromJson(doc.data() as Map<String, dynamic>)};

        final repaymentsByLoanId = <String, List<LoanRepayment>>{};
        for (var doc in repaymentsSnap.docs) {
          try {
            final r = LoanRepayment.fromJson(doc.data() as Map<String, dynamic>);
            repaymentsByLoanId.putIfAbsent(r.loanId, () => []).add(r);
          } catch (e) {
            debugPrint('[REPORT ERROR] Parse repayment error in loan report ${doc.id}: $e');
          }
        }

        final reportItems = <LoanReportItem>[];
        for (var loan in loans) {
          final repayments = repaymentsByLoanId[loan.id] ?? const [];

          final totalPrincipalPaid = repayments.fold<double>(0.0, (total, r) => total + r.principalRepaid);
          final totalInterestPaid = repayments.fold<double>(0.0, (total, r) => total + r.interestAmount);
          final currentPending = loan.pendingPrincipal;
          final currentInterest = CalculationUtils.calculateMonthlyInterest(
            outstandingPrincipal: currentPending,
            annualRate: loan.interestRate,
          );

          final member = membersMap[loan.memberId] ??
              Member(
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

        debugPrint('[REPORT] LOANS OVERVIEW CALCULATION END: ${reportItems.length} loan report items');
        debugPrint('[REPORT] UI STATE = SUCCESS (Loans Overview)');

        _loanReportCache[cacheKey] = reportItems;
        return reportItems;
      } catch (e, stack) {
        debugPrint('[REPORT ERROR] getLoanReport FAILED: $e\n$stack');
        rethrow;
      }
    });
  }

  /// Generates MemberLedger entries with caching.
  Future<List<MemberLedgerEntry>> getMemberLedger({
    required String groupId,
    required String memberId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$groupId-$memberId';
    if (!forceRefresh && _memberLedgerCache.containsKey(cacheKey)) {
      debugPrint('[REPORT] getMemberLedger CACHE HIT for $cacheKey');
      return _memberLedgerCache[cacheKey]!;
    }

    return PerfLogger.traceAsync('getMemberLedger($memberId)', () async {
      debugPrint('[REPORT] MEMBER LEDGER START: memberId=$memberId');
      try {
        final activitiesSnap = await _firebaseService
            .activities(groupId)
            .where('memberId', isEqualTo: memberId)
            .get();

        final activities = activitiesSnap.docs
            .map((doc) => AppTransaction.fromJson(doc.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        double runningBalance = 0.0;
        final entries = <MemberLedgerEntry>[];

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

        debugPrint('[REPORT] MEMBER LEDGER END: ${entries.length} entries');
        _memberLedgerCache[cacheKey] = entries;
        return entries;
      } catch (e, stack) {
        debugPrint('[REPORT ERROR] getMemberLedger FAILED: $e\n$stack');
        rethrow;
      }
    });
  }
}
