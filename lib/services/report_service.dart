import '../models/member.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/report_models.dart';
import '../services/firebase_service.dart';

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

    // 2. Fetch loan info
    final loansSnapshot = await _firebaseService.loans(groupId)
        .where('memberId', isEqualTo: member.id)
        .get();

    final allLoans = loansSnapshot.docs.map((doc) => Loan.fromJson(doc.data() as Map<String, dynamic>)).toList();
    
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
    double interestRate = 0.0;
    double interestAmount = 0.0;
    double principalRepaid = 0.0;
    double closingPrincipal = 0.0;

    if (targetLoan != null) {
      interestRate = targetLoan.interestRate;
      
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
          interestAmount = openingPrincipal * interestRate / 100;
        }
        closingPrincipal = openingPrincipal;
      }
    }

    final paidHafta = contribution?.paidAmount ?? 0.0;
    final expectedHafta = contribution?.expectedAmount ?? member.monthlyContribution;
    
    return MemberMonthlyReport(
      member: member,
      month: month,
      year: year,
      expectedHafta: expectedHafta,
      paidHafta: paidHafta,
      pendingHafta: (expectedHafta - paidHafta) > 0 ? expectedHafta - paidHafta : 0.0,
      loanId: targetLoan?.id,
      openingPrincipal: openingPrincipal,
      interestRate: interestRate,
      interestAmount: interestAmount,
      principalRepaid: principalRepaid,
      closingPrincipal: closingPrincipal,
      totalPaid: paidHafta + principalRepaid + interestAmount,
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

    double totalExpectedHafta = memberReports.fold(0, (val, r) => val + r.expectedHafta);
    double totalCollectedHafta = memberReports.fold(0, (val, r) => val + r.paidHafta);
    double totalPendingHafta = memberReports.fold(0, (val, r) => val + r.pendingHafta);
    
    double totalActiveLoans = memberReports.where((r) => r.openingPrincipal > 0).fold(0, (val, r) => val + r.openingPrincipal);
    double totalPrincipalRepaid = memberReports.fold(0, (val, r) => val + r.principalRepaid);
    double totalInterestCollected = memberReports.fold(0, (val, r) => val + r.interestAmount);
    double totalOutstandingLoan = memberReports.fold(0, (val, r) => val + r.closingPrincipal);
    
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
    );
  }
}
