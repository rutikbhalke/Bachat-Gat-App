import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';
import 'package:bachat_gat/models/group.dart';
import 'package:bachat_gat/models/loan.dart';
import 'package:bachat_gat/models/monthly_contribution.dart';
import 'package:bachat_gat/models/loan_repayment.dart';

void main() {
  group('Dashboard Fund & Financial Balance Verification (6 Test Cases)', () {
    // -------------------------------------------------------------
    // CASE 1:
    // Savings = ₹17,500, Active Loans = ₹25,000, Interest = ₹2,000, Available Cash = ₹5,500
    // Total Group Fund MUST be ₹30,500 (Available Cash + Active Loans), NOT ₹5,500
    // Available MUST be ₹5,500, NOT 17,500 - 25,000 = -7,500
    // -------------------------------------------------------------
    test('CASE 1: Savings 17,500, Active Loans 25,000, Available Cash 5,500 -> Total Group Fund is 30,500', () {
      final group = BachatGatGroup(
        id: 'G1',
        name: 'Shivshahi Bachat Gat',
        managerId: 'M1',
        monthlyTarget: 50000,
        monthlyContributionAmount: 1000,
        totalSavings: 17500.0,
        totalOutstandingLoans: 25000.0,
        totalInterestCollected: 2000.0,
        totalFund: 5500.0, // Persisted cash in group ledger
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 17),
      );

      final availableCash = CalculationUtils.calculateAvailableCash(group.totalFund);
      final totalGroupFund = CalculationUtils.calculateTotalGroupFund(
        availableCash: availableCash,
        outstandingLoans: group.totalOutstandingLoans,
      );

      expect(availableCash, 5500.0);
      expect(group.totalSavings, 17500.0);
      expect(group.totalOutstandingLoans, 25000.0);
      expect(group.totalInterestCollected, 2000.0);
      expect(totalGroupFund, 30500.0); // 5,500 + 25,000
      expect(group.totalGroupAssets, 30500.0);

      // Verify Available is NOT negative 7,500
      expect(availableCash, isNot(-7500.0));
    });

    // -------------------------------------------------------------
    // CASE 2:
    // Savings = ₹10,000, Active Loans = ₹15,000
    // Verify dashboard does NOT show Available = -₹5,000
    // -------------------------------------------------------------
    test('CASE 2: Savings 10,000, Active Loans 15,000 -> Available is NEVER negative', () {
      final group = BachatGatGroup(
        id: 'G1',
        name: 'Shivshahi Bachat Gat',
        managerId: 'M1',
        monthlyTarget: 50000,
        monthlyContributionAmount: 1000,
        totalSavings: 10000.0,
        totalOutstandingLoans: 15000.0,
        totalInterestCollected: 500.0,
        totalFund: 0.0, // Group disbursed all cash as loans
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 17),
      );

      final availableCash = CalculationUtils.calculateAvailableCash(group.totalFund);
      final totalGroupFund = CalculationUtils.calculateTotalGroupFund(
        availableCash: availableCash,
        outstandingLoans: group.totalOutstandingLoans,
      );

      expect(availableCash, 0.0);
      expect(availableCash, isNot(-5000.0));
      expect(totalGroupFund, 15000.0);
      expect(CalculationUtils.formatCurrency(availableCash), '₹0');
    });

    // -------------------------------------------------------------
    // CASE 3:
    // Savings = ₹10,000, Active Loans = ₹5,000
    // Verify Available is calculated correctly from actual ledger data
    // -------------------------------------------------------------
    test('CASE 3: Savings 10,000, Active Loans 5,000 -> Available is 5,000 cash and Total Group Fund is 10,000', () {
      final group = BachatGatGroup(
        id: 'G1',
        name: 'Shivshahi Bachat Gat',
        managerId: 'M1',
        monthlyTarget: 50000,
        monthlyContributionAmount: 1000,
        totalSavings: 10000.0,
        totalOutstandingLoans: 5000.0,
        totalInterestCollected: 0.0,
        totalFund: 5000.0, // Remaining cash
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 17),
      );

      final availableCash = CalculationUtils.calculateAvailableCash(group.totalFund);
      final totalGroupFund = CalculationUtils.calculateTotalGroupFund(
        availableCash: availableCash,
        outstandingLoans: group.totalOutstandingLoans,
      );

      expect(availableCash, 5000.0);
      expect(group.totalSavings, 10000.0);
      expect(group.totalOutstandingLoans, 5000.0);
      expect(totalGroupFund, 10000.0);
    });

    // -------------------------------------------------------------
    // CASE 4:
    // Loan ₹10,000, Principal repaid ₹5,000 -> Active Loan must display ₹5,000
    // -------------------------------------------------------------
    test('CASE 4: Loan 10,000 with 5,000 principal repaid -> Active Loan outstanding is exactly 5,000', () {
      final loan = Loan(
        id: 'L1',
        groupId: 'G1',
        memberId: 'M1',
        originalPrincipal: 10000.0,
        pendingPrincipal: 5000.0, // 5000 repaid
        interestRate: 2.0,
        loanDate: DateTime(2026, 1, 1),
        status: LoanStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      final activeLoans = [loan];
      final totalOutstanding = CalculationUtils.calculateActiveLoansOutstanding(activeLoans);

      expect(totalOutstanding, 5000.0);
      expect(CalculationUtils.formatCurrency(totalOutstanding), '₹5,000');
    });

    // -------------------------------------------------------------
    // CASE 5:
    // Loan completely repaid -> Active Loan must become ₹0
    // -------------------------------------------------------------
    test('CASE 5: Loan completely repaid -> Active Loan is exactly 0', () {
      final closedLoan = Loan(
        id: 'L1',
        groupId: 'G1',
        memberId: 'M1',
        originalPrincipal: 10000.0,
        pendingPrincipal: 0.0,
        interestRate: 2.0,
        loanDate: DateTime(2026, 1, 1),
        status: LoanStatus.closed,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 3, 1),
      );

      final loans = [closedLoan];
      final totalOutstanding = CalculationUtils.calculateActiveLoansOutstanding(loans);

      expect(totalOutstanding, 0.0);
      expect(CalculationUtils.formatCurrency(totalOutstanding), '₹0');
    });

    // -------------------------------------------------------------
    // CASE 6:
    // No available cash -> Available must display ₹0 (NOT -₹0, NOT negative)
    // -------------------------------------------------------------
    test('CASE 6: No available cash or negative raw balance -> Available displays ₹0', () {
      expect(CalculationUtils.calculateAvailableCash(0.0), 0.0);
      expect(CalculationUtils.calculateAvailableCash(-100.0), 0.0);
      expect(CalculationUtils.formatCurrency(CalculationUtils.calculateAvailableCash(0.0)), '₹0');
      expect(CalculationUtils.formatCurrency(CalculationUtils.calculateAvailableCash(-2500.0)), '₹0');
    });

    // -------------------------------------------------------------
    // Aggregation Utilities: Total Savings and Total Interest
    // -------------------------------------------------------------
    test('Aggregation Utilities: calculateTotalSavings & calculateTotalInterestCollected', () {
      final contribs = [
        MonthlyContribution(id: 'c1', memberId: 'm1', groupId: 'g1', month: 8, year: 2026, regularHaftaAmount: 1000, totalPaid: 1000, expectedAmount: 1000, paidAmount: 1000, status: ContributionStatus.paid, paymentDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()),
        MonthlyContribution(id: 'c2', memberId: 'm2', groupId: 'g1', month: 8, year: 2026, regularHaftaAmount: 1500, totalPaid: 1500, expectedAmount: 1500, paidAmount: 1500, status: ContributionStatus.paid, paymentDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final repayments = [
        LoanRepayment(id: 'r1', loanId: 'l1', groupId: 'g1', memberId: 'm1', month: 8, year: 2026, openingPrincipal: 10000, interestRate: 2, interestAmount: 200, regularContribution: 1000, principalRepaid: 2000, totalPaid: 3200, closingPrincipal: 8000, paymentDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()),
        LoanRepayment(id: 'r2', loanId: 'l2', groupId: 'g1', memberId: 'm2', month: 8, year: 2026, openingPrincipal: 5000, interestRate: 2, interestAmount: 100, regularContribution: 1500, principalRepaid: 1000, totalPaid: 2600, closingPrincipal: 4000, paymentDate: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      expect(CalculationUtils.calculateTotalSavings(contribs), 2500.0);
      expect(CalculationUtils.calculateTotalInterestCollected(repayments), 300.0);
    });
  });
}
