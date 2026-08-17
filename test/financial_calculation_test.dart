import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';
import 'package:bachat_gat/models/member.dart';
import 'package:bachat_gat/models/loan.dart';
import 'package:bachat_gat/models/report_models.dart';

void main() {
  group('Bachat-Gat Financial & Loan Calculation Tests', () {
    test('1. Default 2% Monthly Interest on 50,000 Loan', () {
      final interest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: 50000.0,
        annualRate: 2.0,
      );
      // 50,000 * 2 / 100 = 1,000
      expect(interest, 1000.0);
    });

    test('2. 2% Interest on 10,000 Loan is 200', () {
      final interest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: 10000.0,
        annualRate: 2.0,
      );
      expect(interest, 200.0);
    });

    test('3. Interest recalculation on reduced principal after 10,000 repayment on 50,000', () {
      const initialPrincipal = 50000.0;
      const principalRepaid = 10000.0;
      final newPrincipal = CalculationUtils.calculateRemainingPrincipal(initialPrincipal, principalRepaid);
      expect(newPrincipal, 40000.0);

      // Next month interest @ 2% on 40,000 should be 800
      final nextMonthInterest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: newPrincipal,
        annualRate: 2.0,
      );
      expect(nextMonthInterest, 800.0);
    });

    test('4. Interest-only payment does not change outstanding principal', () {
      const initialPrincipal = 25000.0;
      final monthlyInterest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: initialPrincipal,
        annualRate: 2.0,
      );
      expect(monthlyInterest, 500.0);

      const principalPaid = 0.0;
      final remaining = CalculationUtils.calculateRemainingPrincipal(initialPrincipal, principalPaid);
      expect(remaining, 25000.0);

      // Next month interest still 500
      final nextInterest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: remaining,
        annualRate: 2.0,
      );
      expect(nextInterest, 500.0);
    });

    test('5. Total payment breakdown calculation: Hafta + Principal + Interest', () {
      const regularHafta = 1000.0;
      const principalRepaid = 5000.0;
      const interestPaid = 400.0;

      final total = CalculationUtils.calculateTotalPayment(
        regularHafta: regularHafta,
        principalRepaid: principalRepaid,
        interestPaid: interestPaid,
      );
      expect(total, 6400.0);
    });

    test('6. Pending Hafta calculation for full, partial, and zero payment', () {
      // Full payment
      expect(CalculationUtils.calculatePendingHafta(1000.0, 1000.0), 0.0);
      // Partial payment
      expect(CalculationUtils.calculatePendingHafta(1000.0, 600.0), 400.0);
      // Zero payment
      expect(CalculationUtils.calculatePendingHafta(1000.0, 0.0), 1000.0);
      // Overpayment does not produce negative pending
      expect(CalculationUtils.calculatePendingHafta(1000.0, 1500.0), 0.0);
    });

    test('7. Loan Full Payoff marks loan closed with 0 closing balance', () {
      const loanAmount = 15000.0;
      final loan = Loan(
        id: 'L1',
        groupId: 'G1',
        memberId: 'M1',
        originalPrincipal: loanAmount,
        pendingPrincipal: loanAmount,
        interestRate: 2.0,
        loanDate: DateTime(2026, 1, 1),
        status: LoanStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final closing = CalculationUtils.calculateRemainingPrincipal(loan.pendingPrincipal, 15000.0);
      expect(closing, 0.0);

      final updatedLoan = loan.copyWith(
        pendingPrincipal: closing,
        status: closing <= 0 ? LoanStatus.closed : LoanStatus.active,
      );
      expect(updatedLoan.status, LoanStatus.closed);
      expect(updatedLoan.pendingPrincipal, 0.0);
    });

    test('8. MemberMonthlyReport correctly reports total paid and pending breakdown', () {
      final member = Member(
        id: 'M1',
        groupId: 'G1',
        name: 'Sunita Sharma',
        phone: '9876543210',
        joinDate: DateTime(2025, 1, 1),
        monthlyContribution: 1000.0,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final report = MemberMonthlyReport(
        member: member,
        month: 8,
        year: 2026,
        expectedHafta: 1000.0,
        paidHafta: 1000.0,
        pendingHafta: 0.0,
        loanId: 'L1',
        openingPrincipal: 20000.0,
        interestRate: 2.0,
        interestAmount: 400.0,
        principalRepaid: 5000.0,
        closingPrincipal: 15000.0,
        totalPaid: 6400.0, // 1000 + 400 + 5000
      );

      expect(report.totalPaid, 6400.0);
      expect(report.pendingLoanPrincipal, 15000.0);
      expect(report.totalPending, 15000.0);
      expect(report.hasPendingDues, true);
    });

    test('9. GroupMonthlyReport aggregates all member collections and outstanding balances', () {
      final m1 = Member(id: 'M1', groupId: 'G1', name: 'Member 1', phone: '111', joinDate: DateTime(2026, 1, 1), monthlyContribution: 1000, createdAt: DateTime.now(), updatedAt: DateTime.now());
      final m2 = Member(id: 'M2', groupId: 'G1', name: 'Member 2', phone: '222', joinDate: DateTime(2026, 1, 1), monthlyContribution: 1000, createdAt: DateTime.now(), updatedAt: DateTime.now());

      final r1 = MemberMonthlyReport(
        member: m1,
        month: 8,
        year: 2026,
        expectedHafta: 1000.0,
        paidHafta: 1000.0,
        pendingHafta: 0.0,
        loanId: 'L1',
        openingPrincipal: 10000.0,
        interestRate: 2.0,
        interestAmount: 200.0,
        principalRepaid: 2000.0,
        closingPrincipal: 8000.0,
        totalPaid: 3200.0,
      );

      final r2 = MemberMonthlyReport(
        member: m2,
        month: 8,
        year: 2026,
        expectedHafta: 1000.0,
        paidHafta: 1000.0,
        pendingHafta: 0.0,
        openingPrincipal: 0.0,
        interestRate: 0.0,
        interestAmount: 0.0,
        principalRepaid: 0.0,
        closingPrincipal: 0.0,
        totalPaid: 1000.0,
      );

      final groupReport = GroupMonthlyReport(
        groupName: 'Shivshahi Bachat Gat',
        month: 8,
        year: 2026,
        totalMembers: 2,
        memberReports: [r1, r2],
        totalExpectedHafta: 2000.0,
        totalCollectedHafta: 2000.0,
        totalPendingHafta: 0.0,
        totalActiveLoans: 10000.0,
        totalPrincipalRepaid: 2000.0,
        totalInterestCollected: 200.0,
        totalOutstandingLoan: 8000.0,
        totalCollection: 4200.0, // 2000 hafta + 2000 principal + 200 interest
      );

      expect(groupReport.totalMembers, 2);
      expect(groupReport.totalCollectedHafta, 2000.0);
      expect(groupReport.totalPrincipalRepaid, 2000.0);
      expect(groupReport.totalCollection, 4200.0);
      expect(groupReport.totalOutstandingLoan, 8000.0);
    });

    test('10. Currency Formatting handles Rupee symbol without decimals', () {
      expect(CalculationUtils.formatCurrency(50000), '₹50,000');
      expect(CalculationUtils.formatCurrency(1200), '₹1,200');
      expect(CalculationUtils.formatCurrency(0), '₹0');
    });
  });
}
