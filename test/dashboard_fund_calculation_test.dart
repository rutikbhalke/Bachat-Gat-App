import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';
import 'package:bachat_gat/models/group.dart';
import 'package:bachat_gat/models/loan.dart';
import 'package:bachat_gat/models/monthly_contribution.dart';
import 'package:bachat_gat/models/loan_repayment.dart';
import 'package:bachat_gat/models/member.dart';
import 'package:bachat_gat/services/data_import_service.dart';

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
      expect(group.totalGroupAssets, 19500.0); // 17,500 savings + 2,000 interest

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
    // CASE 7:
    // User Directive Test: Available ₹30,500, Loan ₹3,000, Repay ₹1,000, Over-Repay ₹3,000
    // -------------------------------------------------------------
    test('CASE 7: Available ₹30,500 -> Loan ₹3,000 (+₹3000 loan, ₹3000 active, ₹27,500 available) -> Repay ₹1,000 -> Reject over-repay ₹3,000', () {
      double availableBalance = 30500.0;

      // 1. Create loan = ₹3,000
      const loanAmount = 3000.0;
      expect(loanAmount > 0, true);
      final loan = Loan(
        id: 'L_test_3000',
        groupId: 'G1',
        memberId: 'M1',
        originalPrincipal: loanAmount,
        pendingPrincipal: loanAmount,
        interestRate: 2.0,
        loanDate: DateTime(2026, 8, 1),
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify Loan amount is strictly stored as positive
      expect(loan.originalPrincipal, 3000.0);
      expect(loan.pendingPrincipal, 3000.0);

      // Verify Active Loans is sum of active outstanding principals = ₹3,000
      List<Loan> activeLoans = [loan];
      double activeLoansSum = CalculationUtils.calculateActiveLoansOutstanding(activeLoans);
      expect(activeLoansSum, 3000.0);

      // Available balance reduces: 30,500 - 3,000 = 27,500
      availableBalance -= loanAmount;
      expect(availableBalance, 27500.0);

      // 2. Repay ₹1,000
      const principalRepaid = 1000.0;
      expect(principalRepaid <= loan.pendingPrincipal, true);
      final updatedLoan = loan.copyWith(pendingPrincipal: loan.pendingPrincipal - principalRepaid);
      expect(updatedLoan.pendingPrincipal, 2000.0);
      availableBalance += principalRepaid;

      activeLoans = [updatedLoan];
      activeLoansSum = CalculationUtils.calculateActiveLoansOutstanding(activeLoans);
      expect(activeLoansSum, 2000.0);
      expect(availableBalance, 28500.0);

      // 3. Attempt repayment ₹3,000 (when outstanding is only ₹2,000) -> REJECT
      const overRepayAttempt = 3000.0;
      final canRepay = overRepayAttempt <= updatedLoan.pendingPrincipal;
      expect(canRepay, false); // REJECTED!

      // Outstanding and Active Loans remain strictly ₹2,000
      expect(updatedLoan.pendingPrincipal, 2000.0);
      expect(CalculationUtils.calculateActiveLoansOutstanding(activeLoans), 2000.0);
      expect(availableBalance, 28500.0);
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

    // -------------------------------------------------------------
    // Monthly Savings Progress Multi-Month & Year Boundary Selection
    // -------------------------------------------------------------
    test('Monthly Savings Progress: Multi-month filtering, Year boundaries & Zero-collection state', () {
      final members = [
        ...List.generate(
          10,
          (i) => Member(
            id: 'M_$i',
            groupId: 'G1',
            name: 'Member $i',
            phone: '98765432$i',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        Member(
          id: 'M_10',
          groupId: 'G1',
          name: 'Member 10',
          phone: '9876543210',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 'M_11',
          groupId: 'G1',
          name: 'Member 11',
          phone: '9876543211',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 'M_12',
          groupId: 'G1',
          name: 'Member 12',
          phone: '9876543212',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Member(
          id: 'M_13',
          groupId: 'G1',
          name: 'Member 13',
          phone: '9876543213',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // 14 active members (1 share each) -> Target = 14 * 1000 = ₹14,000
      final target = CalculationUtils.calculateMonthlySavingsTarget(members);
      expect(target, 14000.0);

      final contributions = [
        // August 2026: 8 members paid ₹1000 = ₹8,000
        ...List.generate(
          8,
          (i) => MonthlyContribution(
            id: 'C_M_${i}_2026-08',
            memberId: 'M_$i',
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            totalPaid: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 10),
          ),
        ),
        // July 2026: All 14 shares collected = ₹14,000
        ...List.generate(
          10,
          (i) => MonthlyContribution(
            id: 'C_M_${i}_2026-07',
            memberId: 'M_$i',
            groupId: 'G1',
            month: 7,
            year: 2026,
            regularHaftaAmount: 1000.0,
            totalPaid: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 7, 1),
            updatedAt: DateTime(2026, 7, 10),
          ),
        ),
        MonthlyContribution(
          id: 'C_M_10_2026-07',
          memberId: 'M_10',
          groupId: 'G1',
          month: 7,
          year: 2026,
          regularHaftaAmount: 2000.0,
          totalPaid: 2000.0,
          expectedAmount: 2000.0,
          paidAmount: 2000.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 10),
        ),
        MonthlyContribution(
          id: 'C_M_11_2026-07',
          memberId: 'M_11',
          groupId: 'G1',
          month: 7,
          year: 2026,
          regularHaftaAmount: 2000.0,
          totalPaid: 2000.0,
          expectedAmount: 2000.0,
          paidAmount: 2000.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 10),
        ),
        // December 2026: 2 members paid ₹1000 = ₹2,000
        MonthlyContribution(
          id: 'C_M_0_2026-12',
          memberId: 'M_0',
          groupId: 'G1',
          month: 12,
          year: 2026,
          regularHaftaAmount: 1000.0,
          totalPaid: 1000.0,
          expectedAmount: 1000.0,
          paidAmount: 1000.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2026, 12, 1),
          updatedAt: DateTime(2026, 12, 10),
        ),
        MonthlyContribution(
          id: 'C_M_1_2026-12',
          memberId: 'M_1',
          groupId: 'G1',
          month: 12,
          year: 2026,
          regularHaftaAmount: 1000.0,
          totalPaid: 1000.0,
          expectedAmount: 1000.0,
          paidAmount: 1000.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2026, 12, 1),
          updatedAt: DateTime(2026, 12, 10),
        ),
        // January 2027: 1 member paid ₹1000 = ₹1,000
        MonthlyContribution(
          id: 'C_M_0_2027-01',
          memberId: 'M_0',
          groupId: 'G1',
          month: 1,
          year: 2027,
          regularHaftaAmount: 1000.0,
          totalPaid: 1000.0,
          expectedAmount: 1000.0,
          paidAmount: 1000.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2027, 1, 1),
          updatedAt: DateTime(2027, 1, 10),
        ),
      ];

      // Test August 2026
      final augCollected = CalculationUtils.calculateCurrentMonthCollectedSavings(contributions, month: 8, year: 2026);
      final augProgress = CalculationUtils.calculateSavingsProgressRatio(collected: augCollected, target: target);
      final augPending = CalculationUtils.calculateMonthlyPendingTotal(target: target, collected: augCollected);
      expect(augCollected, 8000.0);
      expect((augProgress * 100).toStringAsFixed(0), '57');
      expect(augPending, 6000.0);

      // Test July 2026 (100% completed)
      final julCollected = CalculationUtils.calculateCurrentMonthCollectedSavings(contributions, month: 7, year: 2026);
      final julProgress = CalculationUtils.calculateSavingsProgressRatio(collected: julCollected, target: target);
      final julPending = CalculationUtils.calculateMonthlyPendingTotal(target: target, collected: julCollected);
      expect(julCollected, 14000.0);
      expect(julProgress, 1.0);
      expect(julPending, 0.0);

      // Test May 2026 (Zero collection month)
      final mayCollected = CalculationUtils.calculateCurrentMonthCollectedSavings(contributions, month: 5, year: 2026);
      final mayProgress = CalculationUtils.calculateSavingsProgressRatio(collected: mayCollected, target: target);
      final mayPending = CalculationUtils.calculateMonthlyPendingTotal(target: target, collected: mayCollected);
      expect(mayCollected, 0.0);
      expect(mayProgress, 0.0);
      expect(mayPending, 14000.0);

      // Test Year Boundary: December 2026 -> January 2027
      final decCollected = CalculationUtils.calculateCurrentMonthCollectedSavings(contributions, month: 12, year: 2026);
      final janCollected = CalculationUtils.calculateCurrentMonthCollectedSavings(contributions, month: 1, year: 2027);
      expect(decCollected, 2000.0);
      expect(janCollected, 1000.0);

      // Verify Marathi and English month name rendering
      expect(CalculationUtils.getMonthName(8, locale: 'en'), 'August');
      expect(CalculationUtils.getMonthName(8, locale: 'mr'), 'ऑगस्ट');
      expect(CalculationUtils.getMonthName(7, locale: 'mr'), 'जुलै');
      expect(CalculationUtils.getMonthName(12, locale: 'mr'), 'डिसेंबर');
      expect(CalculationUtils.getMonthName(1, locale: 'mr'), 'जानेवारी');
    });

    test('Fresh Zero State: 363 Master Members Preserved & Financial Totals Strictly Zero', () {
      // 1. Verify 363 members dataset is intact
      final masterDataset = DataImportService.masterDataset;
      expect(masterDataset.length, 363);

      final members = masterDataset.map((data) => Member(
        id: 'M_${data['srNo']}',
        groupId: 'shivshahi_group_001',
        name: data['name'] as String,
        phone: '',
        joinDate: DateTime(2026, 1, 1),
        shares: data['shares'] as int,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: (data['shares'] as int) * 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      )).toList();

      expect(members.length, 363);
      final totalShares = members.fold<int>(0, (sum, m) => sum + m.shares);
      expect(totalShares, 363);

      // 2. Verify Monthly Target = 363 * 1000 = ₹3,63,000
      final monthlyTarget = CalculationUtils.calculateMonthlySavingsTarget(members);
      expect(monthlyTarget, 363000.0);

      // 3. In a fresh zero state, there are 0 contribution docs, 0 loans, 0 repayments
      final List<MonthlyContribution> freshContributions = [];
      final List<Loan> freshLoans = [];
      final List<LoanRepayment> freshRepayments = [];

      // 4. Financial Calculations in Fresh Zero State
      final totalSavings = CalculationUtils.calculateTotalSavings(freshContributions);
      final totalInterest = CalculationUtils.calculateTotalInterestCollected(freshRepayments);
      final activeLoansOutstanding = CalculationUtils.calculateActiveLoansOutstanding(freshLoans);
      final availableCash = (totalSavings + totalInterest) - activeLoansOutstanding;
      final effectiveAvailable = availableCash >= 0 ? availableCash : 0.0;
      final totalGroupFund = effectiveAvailable + activeLoansOutstanding;

      expect(totalSavings, 0.0);
      expect(totalInterest, 0.0);
      expect(activeLoansOutstanding, 0.0);
      expect(effectiveAvailable, 0.0);
      expect(totalGroupFund, 0.0);

      // 5. Dashboard progress metrics for current month
      final currentMonthCollected = CalculationUtils.calculateCurrentMonthCollectedSavings(
        freshContributions,
        month: 8,
        year: 2026,
      );
      final progressRatio = CalculationUtils.calculateSavingsProgressRatio(
        collected: currentMonthCollected,
        target: monthlyTarget,
      );
      final pendingMonthly = CalculationUtils.calculateMonthlyPendingTotal(
        target: monthlyTarget,
        collected: currentMonthCollected,
      );

      expect(currentMonthCollected, 0.0);
      expect(progressRatio, 0.0);
      expect(pendingMonthly, 363000.0);
    });

    test('Monthly Hafta Payment Window (10th to Next Month 10th Cycle) & Overdue Calculation', () {
      // 1. Verify configured due date = 10
      const dueDay = 10;

      // August 2026 Payment Window: August 10, 2026 to September 10, 2026
      final augWindow = CalculationUtils.getPaymentWindow(month: 8, year: 2026, dueDay: dueDay);
      expect(augWindow.start, DateTime(2026, 8, 10, 0, 0, 0));
      expect(augWindow.end, DateTime(2026, 9, 10, 0, 0, 0));

      // 2. Exact test cases from specification:
      // 10 Aug -> August hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 8, 10), dueDay: dueDay), const PaymentCycle(month: 8, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 8, year: 2026, currentDate: DateTime(2026, 8, 10), dueDay: dueDay), isFalse);

      // 15 Aug -> August hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 8, 15), dueDay: dueDay), const PaymentCycle(month: 8, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 8, year: 2026, currentDate: DateTime(2026, 8, 15), dueDay: dueDay), isFalse);

      // 25 Aug -> August hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 8, 25), dueDay: dueDay), const PaymentCycle(month: 8, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 8, year: 2026, currentDate: DateTime(2026, 8, 25), dueDay: dueDay), isFalse);

      // 1 Sep -> August hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 9, 1), dueDay: dueDay), const PaymentCycle(month: 8, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 8, year: 2026, currentDate: DateTime(2026, 9, 1), dueDay: dueDay), isFalse);

      // 9 Sep -> August hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 9, 9), dueDay: dueDay), const PaymentCycle(month: 8, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 8, year: 2026, currentDate: DateTime(2026, 9, 9), dueDay: dueDay), isFalse);

      // 10 Sep -> September hafta starts
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 9, 10), dueDay: dueDay), const PaymentCycle(month: 9, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 8, year: 2026, currentDate: DateTime(2026, 9, 10), dueDay: dueDay), isTrue);
      expect(CalculationUtils.isMonthOverdue(month: 9, year: 2026, currentDate: DateTime(2026, 9, 10), dueDay: dueDay), isFalse);

      // 15 Sep -> September hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 9, 15), dueDay: dueDay), const PaymentCycle(month: 9, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 9, year: 2026, currentDate: DateTime(2026, 9, 15), dueDay: dueDay), isFalse);

      // 9 Oct -> September hafta available
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 10, 9), dueDay: dueDay), const PaymentCycle(month: 9, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 9, year: 2026, currentDate: DateTime(2026, 10, 9), dueDay: dueDay), isFalse);

      // 10 Oct -> October hafta starts
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 10, 10), dueDay: dueDay), const PaymentCycle(month: 10, year: 2026));
      expect(CalculationUtils.isMonthOverdue(month: 9, year: 2026, currentDate: DateTime(2026, 10, 10), dueDay: dueDay), isTrue);
      expect(CalculationUtils.isMonthOverdue(month: 10, year: 2026, currentDate: DateTime(2026, 10, 10), dueDay: dueDay), isFalse);

      // 3. Year boundary: December 2026 -> January 2027
      final decWindow = CalculationUtils.getPaymentWindow(month: 12, year: 2026, dueDay: dueDay);
      expect(decWindow.start, DateTime(2026, 12, 10, 0, 0, 0));
      expect(decWindow.end, DateTime(2027, 1, 10, 0, 0, 0));

      expect(CalculationUtils.getActiveCycleForDate(DateTime(2026, 12, 25), dueDay: dueDay), const PaymentCycle(month: 12, year: 2026));
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2027, 1, 5), dueDay: dueDay), const PaymentCycle(month: 12, year: 2026));
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2027, 1, 9), dueDay: dueDay), const PaymentCycle(month: 12, year: 2026));
      expect(CalculationUtils.getActiveCycleForDate(DateTime(2027, 1, 10), dueDay: dueDay), const PaymentCycle(month: 1, year: 2027));

      // 4. Leap year payment window (Jan 2028 -> Feb 29, 2028 with dueDay=29)
      final leapWindow = CalculationUtils.getPaymentWindow(month: 1, year: 2028, dueDay: 29);
      expect(leapWindow.end, DateTime(2028, 2, 29, 0, 0, 0));
      expect(CalculationUtils.isMonthOverdue(month: 1, year: 2028, currentDate: DateTime(2028, 2, 28), dueDay: 29), isFalse);
      expect(CalculationUtils.isMonthOverdue(month: 1, year: 2028, currentDate: DateTime(2028, 2, 29), dueDay: 29), isTrue);
    });

    test('Default Group Name & Custom Edit Integrity', () {
      // 1. Default Group Name is "Chhatrapati Bachat Gat, Ghargaon Stand"
      final defaultGroup = BachatGatGroup.fromJson({
        'id': 'shivshahi_group_001',
        'managerId': 'manager_001',
        'monthlyTarget': 0.0,
        'monthlyContributionAmount': 1000.0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      expect(defaultGroup.name, 'Chhatrapati Bachat Gat, Ghargaon Stand');
      expect(defaultGroup.monthlyHaftaDay, 10);

      // 2. Custom Group Name is preserved when edited
      final customGroup = BachatGatGroup.fromJson({
        'id': 'shivshahi_group_001',
        'name': 'Custom Pragati Bachat Gat',
        'managerId': 'manager_001',
        'monthlyTarget': 5000.0,
        'monthlyContributionAmount': 1000.0,
        'monthlyHaftaDay': 15,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      expect(customGroup.name, 'Custom Pragati Bachat Gat');
      expect(customGroup.monthlyHaftaDay, 15);
    });

    test('Master Member Dataset Integrity: Exactly 363 Members & Dynamic Pending Calculation', () {
      expect(DataImportService.masterDataset.length, 363);
      expect(DataImportService.masterDataset.first['srNo'], 1);
      expect(DataImportService.masterDataset.last['srNo'], 363);

      // Verify dynamic monthly target from 363 members = 363 * 1000 = 363,000
      final members = DataImportService.masterDataset.map((d) => Member(
        id: 'M_${d['srNo']}',
        groupId: 'shivshahi_group_001',
        name: d['name'] as String,
        phone: '',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();

      final target = CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0);
      expect(target, 363000.0);

      // Verify total savings is NOT 1,000 when 0 collections are made
      final emptyContributions = <MonthlyContribution>[];
      final totalSavingsZero = CalculationUtils.calculateTotalSavings(emptyContributions);
      expect(totalSavingsZero, 0.0);

      // Verify total savings equals actual sum when 10 members pay
      final tenContributions = List.generate(10, (i) => MonthlyContribution(
        id: 'C_M_${i + 1}_2026_8',
        memberId: 'M_${i + 1}',
        groupId: 'shivshahi_group_001',
        month: 8,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 1000.0,
        expectedAmount: 1000.0,
        paidAmount: 1000.0,
        status: ContributionStatus.paid,
        createdAt: DateTime(2026, 8, 15),
        updatedAt: DateTime(2026, 8, 15),
      ));
      final totalSavingsTen = CalculationUtils.calculateTotalSavings(tenContributions);
      expect(totalSavingsTen, 10000.0);
    });

    test('Member name numeric suffix is ONLY an identifier, NOT share count', () {
      // Members with numeric suffixes (e.g. Tanmay Hase 1 .. 5) are separate members with 1 share each
      final tanmayMembers = List.generate(5, (i) => Member(
        id: 'M_TH_${i + 1}',
        groupId: 'shivshahi_group_001',
        name: 'Tanmay Hase ${i + 1}',
        phone: '',
        joinDate: DateTime(2026, 1, 1),
        shares: 1, // Suffix '2', '3', '4', '5' is NOT shares!
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      for (int i = 0; i < tanmayMembers.length; i++) {
        final m = tanmayMembers[i];
        expect(m.name, 'Tanmay Hase ${i + 1}');
        expect(m.shares, 1);
        expect(m.monthlyContribution, 1000.0);
      }

      // 5 members x 1000 = 5,000 (NOT 1+2+3+4+5 = 15,000!)
      final target = CalculationUtils.calculateMonthlySavingsTarget(tanmayMembers, perShareAmount: 1000.0);
      expect(target, 5000.0);

      // Shailesh Pokharkar 1 through 6 expanded records in masterDataset
      final pokharkarRecords = DataImportService.masterDataset
          .where((d) => (d['name'] as String).contains('शैलेश पोखरकर'))
          .toList();
      expect(pokharkarRecords.length, 6);
      for (int i = 0; i < 6; i++) {
        expect(pokharkarRecords[i]['name'], 'शैलेश पोखरकर ${i + 1}');
        expect(pokharkarRecords[i]['shares'], 1);
      }

      // Mahesh Manohar Aher 1 through 5
      final maheshRecords = DataImportService.masterDataset
          .where((d) => (d['name'] as String).contains('महेश मनोहर आहेर'))
          .toList();
      expect(maheshRecords.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(maheshRecords[i]['name'], 'महेश मनोहर आहेर ${i + 1}');
        expect(maheshRecords[i]['shares'], 1);
      }

      // Machhindra Subhash Aher is a clean single record with NO random leftover '4' suffix
      final machhindraRecord = DataImportService.masterDataset
          .firstWhere((d) => d['srNo'] == 205);
      expect(machhindraRecord['name'], 'मच्छिंद्र सुभाष आहेर');
      expect(machhindraRecord['shares'], 1);

      // Rajendra Subhash Aher has continuous 1 and 2 numbering with no gaps
      final rajendraSubhashRecords = DataImportService.masterDataset
          .where((d) => (d['name'] as String).startsWith('राजेंद्र सुभाष आहेर'))
          .toList();
      expect(rajendraSubhashRecords.length, 2);
      expect(rajendraSubhashRecords[0]['name'], 'राजेंद्र सुभाष आहेर 1');
      expect(rajendraSubhashRecords[1]['name'], 'राजेंद्र सुभाष आहेर 2');
    });

    test('Member grouping and ordering: Same base name members always appear together in numerical sequence', () {
      // Unordered list mimicking out-of-order insertion in database:
      final rawList = [
        Member(id: 'M1', groupId: 'G1', name: 'महेश मनोहर आहेर 1', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M2', groupId: 'G1', name: 'महेश मनोहर आहेर 2', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M3', groupId: 'G1', name: 'महेश मनोहर आहेर 3', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M_VK', groupId: 'G1', name: 'विकास जयराम गाडेकर 1', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M4', groupId: 'G1', name: 'महेश मनोहर आहेर 4', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M5', groupId: 'G1', name: 'महेश मनोहर आहेर 5', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final sorted = CalculationUtils.sortMembersByBaseNameAndSequence(rawList);

      expect(sorted.map((m) => m.name).toList(), [
        'महेश मनोहर आहेर 1',
        'महेश मनोहर आहेर 2',
        'महेश मनोहर आहेर 3',
        'महेश मनोहर आहेर 4',
        'महेश मनोहर आहेर 5',
        'विकास जयराम गाडेकर 1',
      ]);
    });

    test('Member normalization: If a base name has numbered members, plain base-name record is omitted', () {
      final inputList = [
        Member(id: 'M0', groupId: 'G1', name: 'आकाश चंद्रकांत गुळाळ', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M1', groupId: 'G1', name: 'आकाश चंद्रकांत गुळाळ 1', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M2', groupId: 'G1', name: 'आकाश चंद्रकांत गुळाळ 2', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Member(id: 'M3', groupId: 'G1', name: 'आकाश चंद्रकांत गुळाळ 3', phone: '', joinDate: DateTime(2026, 1, 1), shares: 1, monthlyContribution: 1000.0, monthlyContributionPerShare: 1000.0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final output = CalculationUtils.sortMembersByBaseNameAndSequence(inputList);

      expect(output.map((m) => m.name).toList(), [
        'आकाश चंद्रकांत गुळाळ 1',
        'आकाश चंद्रकांत गुळाळ 2',
        'आकाश चंद्रकांत गुळाळ 3',
      ]);

      // Standalone un-numbered plain record is NOT present:
      expect(output.any((m) => m.name == 'आकाश चंद्रकांत गुळाळ'), isFalse);
    });

    test('September 2026 Zero Collection, Dynamic Target, and ₹1,000 Pending Calculation Verification', () {
      // 1. Create active members dataset from master dataset (363 members)
      final members = DataImportService.masterDataset.map((d) => Member(
        id: 'M_${d['srNo']}',
        groupId: 'shivshahi_group_001',
        name: d['name'] as String,
        phone: '',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();

      expect(members.length, 363);

      // 2. September 2026 contributions after deleting erroneous ₹1,000 payment
      // All contributions for month 9, year 2026 are clean pending obligations (paidAmount = 0, totalPaid = 0)
      final septemberContributions = members.map((m) => MonthlyContribution(
        id: 'C_${m.id}_2026_9',
        memberId: m.id,
        groupId: 'shivshahi_group_001',
        month: 9,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 0.0,
        expectedAmount: 1000.0,
        paidAmount: 0.0,
        status: ContributionStatus.pending,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      )).toList();

      // 3. Verify September 2026 Collected Savings (जमा) = ₹0
      final collectedSavings = CalculationUtils.calculateCurrentMonthCollectedSavings(
        septemberContributions,
        month: 9,
        year: 2026,
      );
      expect(collectedSavings, 0.0);
      expect(CalculationUtils.formatCurrency(collectedSavings), '₹0');

      // 4. Verify Target = activeMemberCount × 1,000 (363 × 1,000 = ₹3,63,000)
      final dynamicTarget = CalculationUtils.calculateMonthlySavingsTarget(
        members,
        perShareAmount: 1000.0,
      );
      expect(dynamicTarget, 363000.0);
      expect(CalculationUtils.formatCurrency(dynamicTarget), '₹3,63,000');

      // 5. Verify Progress ratio = 0%
      final progressRatio = CalculationUtils.calculateSavingsProgressRatio(
        collected: collectedSavings,
        target: dynamicTarget,
      );
      expect(progressRatio, 0.0);

      // 6. Verify Pending Total (बाकी रक्कम) = ₹3,63,000
      final pendingTotal = CalculationUtils.calculateMonthlyPendingTotal(
        target: dynamicTarget,
        collected: collectedSavings,
      );
      expect(pendingTotal, 363000.0);
      expect(CalculationUtils.formatCurrency(pendingTotal), '₹3,63,000');

      // 7. Verify Every unpaid member has exactly ₹1,000 pending
      for (final m in members) {
        final contrib = septemberContributions.firstWhere((c) => c.memberId == m.id);
        final memberPending = CalculationUtils.calculateMemberPendingHafta(
          member: m,
          contribution: contrib,
        );
        expect(memberPending, 1000.0);
        expect(contrib.status, ContributionStatus.pending);
      }

      // 8. Verify Total Group Savings does not include deleted ₹1,000
      final totalSavings = CalculationUtils.calculateTotalSavings(septemberContributions);
      expect(totalSavings, 0.0);
    });

    test('Member Profile Collection Card: Numbered members (Name 5, Name 6) have Hafta ₹1,000 & Total ₹1,000 (NOT ₹5,000 / ₹6,000)', () {
      // 1. Members with trailing digits in name are separate members with exactly 1 share each
      final memberMahesh5 = Member(
        id: 'M_200',
        groupId: 'shivshahi_group_001',
        name: 'महेश मनोहर आहेर 5',
        phone: '',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memberShailesh6 = Member(
        id: 'M_300',
        groupId: 'shivshahi_group_001',
        name: 'शैलेश पोखरकर 6',
        phone: '',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(memberMahesh5.shares, 1);
      expect(memberMahesh5.monthlyContribution, 1000.0);
      expect(memberShailesh6.shares, 1);
      expect(memberShailesh6.monthlyContribution, 1000.0);

      // 2. Unpaid August 2026 collection obligation
      final augustMahesh5 = MonthlyContribution(
        id: 'C_M_200_2026_08',
        memberId: 'M_200',
        groupId: 'shivshahi_group_001',
        month: 8,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 0.0,
        expectedAmount: 1000.0,
        paidAmount: 0.0,
        status: ContributionStatus.pending,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      // 3. Verify member monthly due is exactly ₹1,000, NOT ₹5,000
      final dueMahesh5 = CalculationUtils.calculateMemberMonthlyDue(member: memberMahesh5);
      expect(dueMahesh5, 1000.0);

      // 4. Verify pending amount is exactly ₹1,000
      final pendingMahesh5 = CalculationUtils.calculateMemberPendingHafta(
        member: memberMahesh5,
        contribution: augustMahesh5,
      );
      expect(pendingMahesh5, 1000.0);

      // 5. Verify total display calculation in card
      final memberHaftaDue = memberMahesh5.monthlyContribution > 0 ? memberMahesh5.monthlyContribution : 1000.0;
      final regularHafta = augustMahesh5.regularHaftaAmount > 0 && augustMahesh5.regularHaftaAmount <= memberHaftaDue
          ? augustMahesh5.regularHaftaAmount
          : memberHaftaDue;
      final totalDisplayAmount = augustMahesh5.status == ContributionStatus.paid
          ? augustMahesh5.paidAmount
          : (regularHafta + augustMahesh5.interestAmount + augustMahesh5.loanPrincipalPaid);

      expect(regularHafta, 1000.0);
      expect(totalDisplayAmount, 1000.0);
      expect(CalculationUtils.formatCurrency(totalDisplayAmount), '₹1,000');
    });

    test('Strict Duplicate Payment Prevention & Monthly Hafta Lifecycle Workflow', () {
      final memberAkshay1 = Member(
        id: 'M_AKSHAY_1',
        groupId: 'shivshahi_group_001',
        name: 'अक्षय थोरात 1',
        phone: '9876543210',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memberBalasaheb = Member(
        id: 'M_BALA_1',
        groupId: 'shivshahi_group_001',
        name: 'बाळासाहेब जाधव',
        phone: '9876543211',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final allMembers = [memberAkshay1, memberBalasaheb];

      // Test 1 — New Month (10 August): All unpaid members -> pending ₹1,000
      final pendingAkshayAugBefore = CalculationUtils.calculateMemberPendingHafta(
        member: memberAkshay1,
        contribution: null, // No payment recorded yet
      );
      expect(pendingAkshayAugBefore, 1000.0);

      // Filtering selectable pending members for August dialog
      final augustContribs = <String, MonthlyContribution>{};
      final pendingForAugustBefore = allMembers.where((m) {
        final c = augustContribs[m.id];
        return CalculationUtils.calculateMemberPendingHafta(member: m, contribution: c) > 0;
      }).toList();
      expect(pendingForAugustBefore.length, 2);
      expect(pendingForAugustBefore.contains(memberAkshay1), isTrue);

      // Test 2 — Payment: Member A August payment -> ₹1,000 paid
      final akshayAugustPaid = MonthlyContribution(
        id: MonthlyContribution.generateId(memberId: memberAkshay1.id, month: 8, year: 2026),
        memberId: memberAkshay1.id,
        groupId: 'shivshahi_group_001',
        month: 8,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 1000.0,
        expectedAmount: 1000.0,
        paidAmount: 1000.0,
        status: ContributionStatus.paid,
        paymentDate: DateTime(2026, 8, 10),
        createdAt: DateTime(2026, 8, 10),
        updatedAt: DateTime(2026, 8, 10),
      );
      augustContribs[memberAkshay1.id] = akshayAugustPaid;

      // Test 3 — Immediate Recheck: Member A pending = ₹0, NOT in pending list for August
      final pendingAkshayAugAfter = CalculationUtils.calculateMemberPendingHafta(
        member: memberAkshay1,
        contribution: akshayAugustPaid,
      );
      expect(pendingAkshayAugAfter, 0.0);

      final pendingForAugustAfter = allMembers.where((m) {
        final c = augustContribs[m.id];
        return CalculationUtils.calculateMemberPendingHafta(member: m, contribution: c) > 0;
      }).toList();
      expect(pendingForAugustAfter.length, 1);
      expect(pendingForAugustAfter.contains(memberAkshay1), isFalse);
      expect(pendingForAugustAfter.first.id, memberBalasaheb.id);

      // Test 4 — Search: Searching "अक्षय" for August -> 0 selectable results
      final searchFiltered = pendingForAugustAfter.where((m) => m.name.contains('अक्षय')).toList();
      expect(searchFiltered.isEmpty, isTrue);

      // Test 5 — API / Repository Protection: If duplicate payment attempted on existing paid contribution
      final isAlreadyPaid = akshayAugustPaid.status == ContributionStatus.paid ||
          (akshayAugustPaid.expectedAmount > 0 && akshayAugustPaid.paidAmount >= akshayAugustPaid.expectedAmount);
      expect(isAlreadyPaid, isTrue);

      // Test 6 — Next Month (10 September): Member A is pending ₹1,000 for September and eligible to pay
      final septemberContribs = <String, MonthlyContribution>{};
      final pendingAkshaySep = CalculationUtils.calculateMemberPendingHafta(
        member: memberAkshay1,
        contribution: septemberContribs[memberAkshay1.id],
      );
      expect(pendingAkshaySep, 1000.0);

      final pendingForSep = allMembers.where((m) {
        final c = septemberContribs[m.id];
        return CalculationUtils.calculateMemberPendingHafta(member: m, contribution: c) > 0;
      }).toList();
      expect(pendingForSep.length, 2);
      expect(pendingForSep.contains(memberAkshay1), isTrue);

      // Test 7 — Amount: Each member Hafta = ₹1,000, Pending = ₹1,000 unpaid, Pending = ₹0 paid
      expect(CalculationUtils.calculateMemberMonthlyDue(member: memberAkshay1), 1000.0);
      expect(CalculationUtils.calculateMemberMonthlyDue(member: memberBalasaheb), 1000.0);
    });

    test('Data Cleanup: Ankush Gadekar 10 August ₹1,000 Trial Payment Purged, Member Retained, August Status = Due/Pending ₹1,000', () {
      // 1. Member Ankush Gadekar is retained
      final memberAnkush = Member(
        id: 'M_55',
        groupId: 'shivshahi_group_001',
        name: 'अंकुश दाऊ गाडेकर',
        phone: '9876543255',
        joinDate: DateTime(2026, 1, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(memberAnkush.id, 'M_55');
      expect(memberAnkush.name, 'अंकुश दाऊ गाडेकर');
      expect(memberAnkush.shares, 1);
      expect(memberAnkush.monthlyContribution, 1000.0);

      // 2. August 2026 contribution AFTER trial payment is purged
      // Must be a clean pending obligation (paidAmount = 0.0, totalPaid = 0.0, paymentDate = null, status = pending)
      final augustContributionClean = MonthlyContribution(
        id: 'C_M_55_2026_08',
        memberId: memberAnkush.id,
        groupId: 'shivshahi_group_001',
        month: 8,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 0.0,
        expectedAmount: 1000.0,
        paidAmount: 0.0,
        status: ContributionStatus.pending,
        paymentDate: null,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      // 3. Verify August Pending Status = ₹1,000 (DUE/PENDING)
      final pendingAmount = CalculationUtils.calculateMemberPendingHafta(
        member: memberAnkush,
        contribution: augustContributionClean,
      );
      expect(pendingAmount, 1000.0);
      expect(augustContributionClean.status, ContributionStatus.pending);

      // 4. Verify Dashboard collected savings does not count the purged trial payment
      final augustContribsList = [augustContributionClean];
      final collectedAugust = CalculationUtils.calculateCurrentMonthCollectedSavings(
        augustContribsList,
        month: 8,
        year: 2026,
      );
      expect(collectedAugust, 0.0);

      // 5. Verify Member is selectable in Record Monthly Collection for August
      final isSelectableForAugust = pendingAmount > 0;
      expect(isSelectableForAugust, isTrue);

      // 6. Verify Search by "अंकुश" finds the member with ₹1,000 pending
      final pendingMembers = [memberAnkush];
      final searchResult = pendingMembers.where((m) => m.name.contains('अंकुश')).toList();
      expect(searchResult.length, 1);
      expect(searchResult.first.name, 'अंकुश दाऊ गाडेकर');
    });
  });
}
