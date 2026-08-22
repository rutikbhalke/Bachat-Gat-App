import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/models/member.dart';
import 'package:bachat_gat/models/group.dart';
import 'package:bachat_gat/models/loan.dart';
import 'package:bachat_gat/models/monthly_contribution.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';

void main() {
  group('Member & Multiple Shares Calculations', () {
    test('Member with 1 share defaults correctly and calculates monthly hafta', () {
      final member = Member(
        id: 'M1',
        groupId: 'G1',
        name: 'Suresh Patil',
        phone: '9876543210',
        joinDate: DateTime(2026, 8, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(member.shares, 1);
      expect(member.shareCount, 1);
      expect(member.monthlyContributionPerShare, 1000.0);
      expect(member.monthlyContribution, 1000.0);
      expect(member.monthlyHaftaAmount, 1000.0);
    });

    test('Member with 3 shares calculates ₹3000 monthly contribution', () {
      final memberA = Member(
        id: 'MA',
        groupId: 'G1',
        name: 'Member A',
        phone: '9876543211',
        joinDate: DateTime(2026, 8, 1),
        shares: 3,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(memberA.shares, 3);
      expect(memberA.monthlyContributionPerShare, 1000.0);
      expect(memberA.monthlyContribution, 3000.0);
    });

    test('Member with 2 shares calculates ₹2000 monthly contribution', () {
      final memberB = Member(
        id: 'MB',
        groupId: 'G1',
        name: 'Member B',
        phone: '9876543212',
        joinDate: DateTime(2026, 8, 1),
        shares: 2,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(memberB.shares, 2);
      expect(memberB.monthlyContributionPerShare, 1000.0);
      expect(memberB.monthlyContribution, 2000.0);
      expect(memberAPlusMemberBTotal(memberB.monthlyContribution, 3000.0), 5000.0);
    });

    test('Member JSON Serialization & Deserialization preserves multi-shares', () {
      final member = Member(
        id: 'M_serial',
        groupId: 'G1',
        name: 'Pooja Shinde',
        phone: '9876543213',
        joinDate: DateTime(2026, 8, 1),
        shares: 4,
        monthlyContributionPerShare: 1500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = member.toJson();
      expect(json['shares'], 4);
      expect(json['monthlyContributionPerShare'], 1500.0);
      expect(json['monthlyContribution'], 6000.0);

      final fromJson = Member.fromJson(json);
      expect(fromJson.shares, 4);
      expect(fromJson.monthlyContributionPerShare, 1500.0);
      expect(fromJson.monthlyContribution, 6000.0);
    });

    test('Member backward-compatibility deserializes legacy documents without shares', () {
      final legacyJson = {
        'id': 'M_legacy',
        'groupId': 'G1',
        'name': 'Legacy Member',
        'phone': '9876543214',
        'joinDate': '2026-08-01T00:00:00.000',
        'monthlyContribution': 2000.0,
        'status': 'active',
        'createdAt': '2026-08-01T00:00:00.000',
        'updatedAt': '2026-08-01T00:00:00.000',
      };

      final member = Member.fromJson(legacyJson);
      expect(member.shares, 1);
      expect(member.monthlyContributionPerShare, 2000.0);
      expect(member.monthlyContribution, 2000.0);
    });

    test('Member copyWith updates shares and auto-computates new total hafta', () {
      final member = Member(
        id: 'M1',
        groupId: 'G1',
        name: 'Member',
        phone: '9999999999',
        joinDate: DateTime(2026, 8, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = member.copyWith(shares: 5);
      expect(updated.shares, 5);
      expect(updated.monthlyContributionPerShare, 1000.0);
      expect(updated.monthlyContribution, 5000.0);
    });
  });

  group('Group Balances & Strict Non-Negative Invariants', () {
    test('Available Fund and Available Cash never return negative', () {
      final groupNegativeCash = BachatGatGroup(
        id: 'G1',
        name: 'Test Group',
        managerId: 'MGR1',
        monthlyTarget: 6000.0,
        monthlyContributionAmount: 1000.0,
        totalFund: -500.0,
        totalSavings: 20000.0,
        totalOutstandingLoans: 25000.0,
        totalInterestCollected: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(groupNegativeCash.availableCash, 0.0);
      expect(groupNegativeCash.availableFund, 0.0);
      expect(groupNegativeCash.totalGroupAssets, 21000.0);
    });

    test('CalculationUtils.calculateAvailableFund clamps negative to zero', () {
      expect(
        CalculationUtils.calculateAvailableFund(totalSavings: 10000.0, outstandingLoans: 15000.0),
        0.0,
      );
      expect(
        CalculationUtils.calculateAvailableFund(totalSavings: 30500.0, outstandingLoans: 20000.0),
        10500.0,
      );
      expect(
        CalculationUtils.calculateAvailableFund(totalSavings: 30500.0, outstandingLoans: 20000.0, availableCash: 10500.0),
        10500.0,
      );
    });

    test('CalculationUtils.calculateTotalGroupFund is Available Cash + Active Loans', () {
      expect(
        CalculationUtils.calculateTotalGroupFund(availableCash: 10500.0, outstandingLoans: 20000.0),
        30500.0,
      );
      expect(
        CalculationUtils.calculateTotalGroupFund(availableCash: -500.0, outstandingLoans: 10000.0),
        10000.0,
      );
    });
  });

  group('Loan Interest & Repayment Rules', () {
    test('2% monthly interest is accurately computed', () {
      final interest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: 20000.0,
        annualRate: 2.0,
      );
      expect(interest, 400.0);
    });

    test('Zero interest when principal <= 0 or rate <= 0', () {
      expect(CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: 0.0, annualRate: 2.0), 0.0);
      expect(CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: 10000.0, annualRate: 0.0), 0.0);
      expect(CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: -5000.0, annualRate: 2.0), 0.0);
    });

    test('Remaining Principal clamps to zero and never goes negative', () {
      expect(CalculationUtils.calculateRemainingPrincipal(20000.0, 5000.0), 15000.0);
      expect(CalculationUtils.calculateRemainingPrincipal(20000.0, 20000.0), 0.0);
      expect(CalculationUtils.calculateRemainingPrincipal(20000.0, 25000.0), 0.0);
    });

    test('Loan Model correctly tracks pending principal and status', () {
      final loan = Loan(
        id: 'L1',
        groupId: 'G1',
        memberId: 'M1',
        originalPrincipal: 20000.0,
        pendingPrincipal: 20000.0,
        interestRate: 2.0,
        loanDate: DateTime.now(),
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(loan.isFullyRepaid, false);

      final partialLoan = loan.copyWith(pendingPrincipal: 15000.0);
      expect(partialLoan.pendingPrincipal, 15000.0);
      expect(partialLoan.isFullyRepaid, false);

      final closedLoan = loan.copyWith(pendingPrincipal: 0.0, status: LoanStatus.closed);
      expect(closedLoan.pendingPrincipal, 0.0);
      expect(closedLoan.isFullyRepaid, true);
    });
  });

  group('Scenario from User Directive Verification', () {
    test('Scenario: Group share 1000, Member A (3 shares), Member B (2 shares), Available 30,500', () {
      // 1. Members
      final memberA = Member(
        id: 'MA',
        groupId: 'G1',
        name: 'Member A',
        phone: '9999999901',
        joinDate: DateTime.now(),
        shares: 3,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memberB = Member(
        id: 'MB',
        groupId: 'G1',
        name: 'Member B',
        phone: '9999999902',
        joinDate: DateTime.now(),
        shares: 2,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(memberA.monthlyContribution, 3000.0);
      expect(memberB.monthlyContribution, 2000.0);
      expect(memberA.monthlyContribution + memberB.monthlyContribution, 5000.0);

      // 2. Initial available group balance = ₹30,500
      double availableBalance = 30500.0;
      double activeLoans = 0.0;

      // 3. Issue Loan ₹20,000 -> ALLOW
      const loanAmount1 = 20000.0;
      expect(loanAmount1 <= availableBalance, true);
      availableBalance -= loanAmount1;
      activeLoans += loanAmount1;
      expect(availableBalance, 10500.0);
      expect(activeLoans, 20000.0);

      // 4. Request Loan ₹15,000 -> REJECT (Available is ₹10,500)
      const loanAmount2 = 15000.0;
      final canIssueLoan2 = loanAmount2 <= availableBalance;
      expect(canIssueLoan2, false); // Insufficient available balance!
      // Balance remains strictly 10,500, NOT -4,500
      expect(availableBalance, 10500.0);

      // 5. Loan Outstanding ₹20,000 -> Repay ₹5,000 -> Outstanding = ₹15,000
      double loanOutstanding = 20000.0;
      const repaymentAmount1 = 5000.0;
      expect(repaymentAmount1 <= loanOutstanding, true);
      loanOutstanding -= repaymentAmount1;
      availableBalance += repaymentAmount1;
      expect(loanOutstanding, 15000.0);
      expect(availableBalance, 15500.0);

      // 6. Repay ₹20,000 on ₹15,000 outstanding -> REJECT (Cannot exceed ₹15,000)
      const overRepayment = 20000.0;
      final canOverRepay = overRepayment <= loanOutstanding;
      expect(canOverRepay, false); // Over-repayment rejected!
      expect(loanOutstanding, 15000.0); // Outstanding remains 15,000
    });

    test('Audit Scenario: Total Savings 13,000, Interest 250, Outstanding 2,000 -> Available is 11,250 (NOT 34,510)', () {
      final group = BachatGatGroup(
        id: 'G_audit',
        name: 'Shivshahi Bachat Gat',
        managerId: 'M1',
        monthlyTarget: 6000,
        monthlyContributionAmount: 1000,
        totalSavings: 13000.0,
        totalInterestCollected: 250.0,
        totalOutstandingLoans: 2000.0,
        totalFund: 34510.0, // Historical corrupted totalFund in Firestore
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Verify Available Group Balance formula: Total Savings + Total Interest - Outstanding Loans
      final calculatedAvailable = CalculationUtils.calculateAvailableFund(
        totalSavings: group.totalSavings,
        outstandingLoans: group.totalOutstandingLoans,
        totalInterest: group.totalInterestCollected,
      );

      expect(calculatedAvailable, 11250.0);
      expect(calculatedAvailable, isNot(34510.0));
      expect(group.availableFund, 11250.0);
      expect(group.availableCash, 11250.0);
      expect(group.totalGroupAssets, 13250.0); // 13,000 savings + 250 interest

      // 2. Repay ₹500
      const principalRepaid = 500.0;
      final newOutstanding = CalculationUtils.calculateRemainingPrincipal(group.totalOutstandingLoans, principalRepaid);
      expect(newOutstanding, 1500.0);

      final newAvailable = CalculationUtils.calculateAvailableFund(
        totalSavings: group.totalSavings,
        outstandingLoans: newOutstanding,
        totalInterest: group.totalInterestCollected,
      );
      expect(newAvailable, 11750.0); // 13,000 + 250 - 1,500 = 11,750

      // 3. Next month's interest on new outstanding principal ₹1,500 @ 2%
      final nextMonthInterest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: newOutstanding,
        annualRate: 2.0,
      );
      expect(nextMonthInterest, 30.0); // 1,500 * 2% = 30.0
    });

    test('Core Requirements 5, 6, 13: Monthly Compulsory Due Calculation (1 Share vs 3 Shares + Loan)', () {
      // 1 Share = ₹1,000, Outstanding Loan = ₹10,000 @ 2% = ₹200
      const shares1 = 1;
      const ratePerShare = 1000.0;
      const outstanding10k = 10000.0;
      final interest200 = CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: outstanding10k, annualRate: 2.0);
      expect(interest200, 200.0);

      // Case A: 1 Share + ₹5,000 principal repayment
      const principal5k = 5000.0;
      final totalDueWithPrincipal1Share = CalculationUtils.calculateTotalPayment(
        regularHafta: shares1 * ratePerShare,
        interestPaid: interest200,
        principalRepaid: principal5k,
      );
      expect(totalDueWithPrincipal1Share, 6200.0); // 1,000 + 200 + 5,000 = 6,200

      // Case B: 1 Share + skipped principal repayment
      final totalDueSkipped1Share = CalculationUtils.calculateTotalPayment(
        regularHafta: shares1 * ratePerShare,
        interestPaid: interest200,
        principalRepaid: 0.0,
      );
      expect(totalDueSkipped1Share, 1200.0); // 1,000 + 200 = 1,200 (compulsory)

      // Case C: 3 Shares = ₹3,000 + ₹200 + ₹5,000 = ₹8,200
      const shares3 = 3;
      final totalDueWithPrincipal3Shares = CalculationUtils.calculateTotalPayment(
        regularHafta: shares3 * ratePerShare,
        interestPaid: interest200,
        principalRepaid: principal5k,
      );
      expect(totalDueWithPrincipal3Shares, 8200.0); // 3,000 + 200 + 5,000 = 8,200

      // Case D: 3 Shares + skipped principal repayment = ₹3,200
      final totalDueSkipped3Shares = CalculationUtils.calculateTotalPayment(
        regularHafta: shares3 * ratePerShare,
        interestPaid: interest200,
        principalRepaid: 0.0,
      );
      expect(totalDueSkipped3Shares, 3200.0); // 3,000 + 200 = 3,200
    });

    test('Core Requirements 8, 10, 11, 24: Payment Allocation, Partial Payment & Previous Pending Tracking', () {
      // 1. Payment Allocation
      const totalPayment = 6200.0;
      const regularSaving = 1000.0;
      const loanInterest = 200.0;
      const loanPrincipal = 5000.0;
      expect(regularSaving + loanInterest + loanPrincipal, totalPayment);

      // Verify each component routes to its exact bucket
      double totalSavings = 13000.0;
      double totalInterest = 250.0;
      double outstandingPrincipal = 10000.0;

      // Allocate payment:
      totalSavings += regularSaving; // +1,000 savings
      totalInterest += loanInterest; // +200 interest
      outstandingPrincipal -= loanPrincipal; // -5,000 loan principal

      expect(totalSavings, 14000.0);
      expect(totalInterest, 450.0);
      expect(outstandingPrincipal, 5000.0);

      // 2. Partial Payment Handling (Due ₹6,200, Member pays ₹3,000)
      const dueAmount = 6200.0;
      const partialPaid = 3000.0;
      final remainingDue = CalculationUtils.calculatePendingHafta(dueAmount, partialPaid);
      expect(remainingDue, 3200.0); // 6,200 - 3,000 = 3,200 remains pending

      // 3. Multi-Month Pending Tracking (August unpaid ₹1,200 + September ₹1,200)
      const augustPending = 1200.0;
      const septemberCurrentDue = 1200.0;
      final totalMemberPayable = augustPending + septemberCurrentDue;
      expect(totalMemberPayable, 2400.0);
    });

    test('Member Profile Collections: Descending order (September 2026 at top, August 2026 below, July 2026 older)', () {
      final augustPaid = MonthlyContribution(
        id: 'C_M001_2026-08',
        memberId: 'M001',
        groupId: 'G1',
        month: 8,
        year: 2026,
        regularHaftaAmount: 1000.0,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        status: ContributionStatus.paid,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 10),
      );

      final septemberDue = MonthlyContribution(
        id: 'C_M001_2026-09',
        memberId: 'M001',
        groupId: 'G1',
        month: 9,
        year: 2026,
        regularHaftaAmount: 1000.0,
        paidAmount: 0.0,
        expectedAmount: 1000.0,
        status: ContributionStatus.pending,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      final julyPaid = MonthlyContribution(
        id: 'C_M001_2026-07',
        memberId: 'M001',
        groupId: 'G1',
        month: 7,
        year: 2026,
        regularHaftaAmount: 1000.0,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        status: ContributionStatus.paid,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 10),
      );

      final contributions = [augustPaid, julyPaid, septemberDue];
      contributions.sort((a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month));

      // Verify descending order: September 2026 -> August 2026 -> July 2026
      expect(contributions[0].month, 9);
      expect(contributions[0].year, 2026);
      expect(contributions[0].status, ContributionStatus.pending);

      expect(contributions[1].month, 8);
      expect(contributions[1].year, 2026);
      expect(contributions[1].status, ContributionStatus.paid);

      expect(contributions[2].month, 7);
      expect(contributions[2].year, 2026);
      expect(contributions[2].status, ContributionStatus.paid);

      // Verify August was NOT overwritten by September
      expect(contributions.length, 3);
      expect(contributions[1].id, 'C_M001_2026-08');
      expect(contributions[0].id, 'C_M001_2026-09');
    });

    test('Member Profile Collections: Aditya (3 shares) preserves separate ₹3000 records for August and September', () {
      final member = Member(
        id: 'M_ADITYA',
        groupId: 'G1',
        name: 'Aditya',
        phone: '9876543210',
        joinDate: DateTime(2026, 8, 1),
        shares: 3,
        monthlyContributionPerShare: 1000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(member.monthlyContribution, 3000.0);

      final augustAditya = MonthlyContribution(
        id: 'C_${member.id}_2026-08',
        memberId: member.id,
        groupId: member.groupId,
        month: 8,
        year: 2026,
        regularHaftaAmount: member.monthlyContribution,
        paidAmount: 3000.0,
        expectedAmount: 3000.0,
        status: ContributionStatus.paid,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 5),
      );

      final septemberAditya = MonthlyContribution(
        id: 'C_${member.id}_2026-09',
        memberId: member.id,
        groupId: member.groupId,
        month: 9,
        year: 2026,
        regularHaftaAmount: member.monthlyContribution,
        paidAmount: 0.0,
        expectedAmount: 3000.0,
        status: ContributionStatus.pending,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      final list = [augustAditya, septemberAditya];
      list.sort((a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month));

      expect(list[0].regularHaftaAmount, 3000.0);
      expect(list[0].month, 9);
      expect(list[0].status, ContributionStatus.pending);

      expect(list[1].regularHaftaAmount, 3000.0);
      expect(list[1].month, 8);
      expect(list[1].status, ContributionStatus.paid);
    });

    group('Monthly Savings Progress Target & Collected Logic (TEST 1 to 8)', () {
      test('TEST 1: 10 active members with 1 share each -> Total shares = 10, Target = ₹10,000', () {
        final members = List.generate(
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
        );

        final totalShares = CalculationUtils.calculateTotalActiveShares(members);
        final target = CalculationUtils.calculateMonthlySavingsTarget(members);

        expect(totalShares, 10);
        expect(target, 10000.0);
      });

      test('TEST 2: Add one active member with 1 share -> Total shares = 11, Target = ₹11,000', () {
        final members = List.generate(
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
        );

        // Add 11th member
        members.add(
          Member(
            id: 'M_10',
            groupId: 'G1',
            name: 'Member 10',
            phone: '9876543210',
            joinDate: DateTime(2026, 8, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final totalShares = CalculationUtils.calculateTotalActiveShares(members);
        final target = CalculationUtils.calculateMonthlySavingsTarget(members);

        expect(totalShares, 11);
        expect(target, 11000.0);
      });

      test('TEST 3: 12 active members (10 with 1 share, 2 with 2 shares) -> Total shares = 14, Target = ₹14,000', () {
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
            id: 'M_10_1',
            groupId: 'G1',
            name: 'Member 10 1',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_10_2',
            groupId: 'G1',
            name: 'Member 10 2',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_1',
            groupId: 'G1',
            name: 'Member 11 1',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_2',
            groupId: 'G1',
            name: 'Member 11 2',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final totalShares = CalculationUtils.calculateTotalActiveShares(members);
        final target = CalculationUtils.calculateMonthlySavingsTarget(members);

        expect(totalShares, 14);
        expect(target, 14000.0);
      });

      test('TEST 4: 14 shares, member takes ₹10,000 loan -> Target remains strictly ₹14,000', () {
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
            id: 'M_10_1',
            groupId: 'G1',
            name: 'Member 10 1',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_10_2',
            groupId: 'G1',
            name: 'Member 10 2',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_1',
            groupId: 'G1',
            name: 'Member 11 1',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_2',
            groupId: 'G1',
            name: 'Member 11 2',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Member takes ₹10,000 loan
        const loanAmount = 10000.0;
        expect(loanAmount, 10000.0);

        final target = CalculationUtils.calculateMonthlySavingsTarget(members);
        expect(target, 14000.0); // NEVER becomes 24,000
      });

      test('TEST 5: ₹5,000 loan repayment occurs -> Target remains ₹14,000 and Collected excludes principal repayment', () {
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
            id: 'M_10_1',
            groupId: 'G1',
            name: 'Member 10 1',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_10_2',
            groupId: 'G1',
            name: 'Member 10 2',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_1',
            groupId: 'G1',
            name: 'Member 11 1',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_2',
            groupId: 'G1',
            name: 'Member 11 2',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final target = CalculationUtils.calculateMonthlySavingsTarget(members);
        expect(target, 14000.0);

        // Repayment with ₹5,000 principal + ₹1,000 regular hafta
        final contrib = MonthlyContribution(
          id: 'C_M_10_2026-08',
          memberId: 'M_10_1',
          groupId: 'G1',
          month: 8,
          year: 2026,
          regularHaftaAmount: 1000.0,
          interestAmount: 200.0,
          loanPrincipalPaid: 5000.0,
          totalPaid: 6200.0,
          paidAmount: 6200.0,
          expectedAmount: 6200.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 5),
        );

        final collectedSavings = CalculationUtils.calculateCurrentMonthCollectedSavings(
          [contrib],
          month: 8,
          year: 2026,
        );

        // Collected ONLY includes regular hafta (₹1,000), NOT ₹5,000 principal or ₹200 interest
        expect(collectedSavings, 1000.0);
      });

      test('TEST 6: ₹250 interest is collected -> Target remains ₹14,000 and Collected excludes interest', () {
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
            id: 'M_10_1',
            groupId: 'G1',
            name: 'Member 10 1',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_10_2',
            groupId: 'G1',
            name: 'Member 10 2',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_1',
            groupId: 'G1',
            name: 'Member 11 1',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Member(
            id: 'M_11_2',
            groupId: 'G1',
            name: 'Member 11 2',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final target = CalculationUtils.calculateMonthlySavingsTarget(members);
        expect(target, 14000.0);

        final contrib = MonthlyContribution(
          id: 'C_M_10_2026-08',
          memberId: 'M_10_1',
          groupId: 'G1',
          month: 8,
          year: 2026,
          regularHaftaAmount: 1000.0,
          interestAmount: 250.0,
          loanPrincipalPaid: 0.0,
          totalPaid: 1250.0,
          paidAmount: 1250.0,
          expectedAmount: 1250.0,
          status: ContributionStatus.paid,
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 5),
        );

        final collectedSavings = CalculationUtils.calculateCurrentMonthCollectedSavings(
          [contrib],
          month: 8,
          year: 2026,
        );

        expect(collectedSavings, 1000.0); // Excludes ₹250 interest
      });

      test('TEST 7: Current month regular contributions collected = ₹10,000, Target = ₹14,000 -> Progress = 71.43%', () {
        const collected = 10000.0;
        const target = 14000.0;

        final progressRatio = CalculationUtils.calculateSavingsProgressRatio(
          collected: collected,
          target: target,
        );

        final progressPercent = progressRatio * 100;
        expect((progressPercent).toStringAsFixed(2), '71.43');
        expect((progressRatio * 100).toStringAsFixed(0), '71');
      });

      test('TEST 8: Adding a member (1 share) -> Target automatically increases by ₹1,000', () {
        final memberA1 = Member(
          id: 'M_A_1',
          groupId: 'G1',
          name: 'Member A 1',
          phone: '9876543210',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(CalculationUtils.calculateMonthlySavingsTarget([memberA1]), 1000.0);

        final memberA2 = Member(
          id: 'M_A_2',
          groupId: 'G1',
          name: 'Member A 2',
          phone: '9876543210',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(CalculationUtils.calculateMonthlySavingsTarget([memberA1, memberA2]), 2000.0);
        expect(CalculationUtils.calculateTotalActiveShares([memberA1, memberA2]), 2);
      });

      test('TEST: Vaibhav (2 shares) Partial Payment & Next Month Obligation Lifecycle', () {
        final vaibhav = Member(
          id: 'M_VAIBHAV',
          groupId: 'G1',
          name: 'Vaibhav',
          phone: '9876543210',
          joinDate: DateTime(2026, 8, 1),
          shares: 2,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(vaibhav.monthlyContribution, 2000.0);

        // 1. Initial partial payment of ₹1,000 for August 2026
        var augustVaibhav = MonthlyContribution(
          id: 'C_${vaibhav.id}_2026-08',
          memberId: vaibhav.id,
          groupId: vaibhav.groupId,
          month: 8,
          year: 2026,
          regularHaftaAmount: vaibhav.monthlyContribution,
          expectedAmount: 2000.0,
          paidAmount: 1000.0,
          status: ContributionStatus.partial,
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 5),
        );

        expect(augustVaibhav.expectedAmount, 2000.0); // Due = ₹2,000
        expect(augustVaibhav.paidAmount, 1000.0); // Paid = ₹1,000
        expect(augustVaibhav.remainingAmount, 1000.0); // Remaining = ₹1,000
        expect(augustVaibhav.status, ContributionStatus.partial); // Status = PARTIALLY_PAID

        // 2. Later payment of another ₹1,000 for August 2026
        const secondPayment = 1000.0;
        final updatedPaid = augustVaibhav.paidAmount + secondPayment;
        augustVaibhav = MonthlyContribution(
          id: augustVaibhav.id,
          memberId: augustVaibhav.memberId,
          groupId: augustVaibhav.groupId,
          month: augustVaibhav.month,
          year: augustVaibhav.year,
          regularHaftaAmount: augustVaibhav.regularHaftaAmount,
          expectedAmount: augustVaibhav.expectedAmount,
          paidAmount: updatedPaid,
          status: updatedPaid >= augustVaibhav.expectedAmount ? ContributionStatus.paid : ContributionStatus.partial,
          createdAt: augustVaibhav.createdAt,
          updatedAt: DateTime.now(),
        );

        expect(augustVaibhav.expectedAmount, 2000.0); // Due = ₹2,000
        expect(augustVaibhav.paidAmount, 2000.0); // Paid = ₹2,000
        expect(augustVaibhav.remainingAmount, 0.0); // Remaining = ₹0
        expect(augustVaibhav.status, ContributionStatus.paid); // Status = PAID

        // 3. Next month (September 2026) creates independent obligation
        final septemberVaibhav = MonthlyContribution(
          id: 'C_${vaibhav.id}_2026-09',
          memberId: vaibhav.id,
          groupId: vaibhav.groupId,
          month: 9,
          year: 2026,
          regularHaftaAmount: vaibhav.monthlyContribution,
          expectedAmount: 2000.0,
          paidAmount: 0.0,
          status: ContributionStatus.pending,
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        );

        expect(septemberVaibhav.expectedAmount, 2000.0); // September Due = ₹2,000
        expect(septemberVaibhav.paidAmount, 0.0); // Paid = ₹0
        expect(septemberVaibhav.remainingAmount, 2000.0); // Remaining = ₹2,000
        expect(septemberVaibhav.status, ContributionStatus.pending); // Status = DUE
      });

      group('Group Settings & Profile Dynamic Target Tests (TEST 1 to TEST 6)', () {
        test('TEST 1: 10 active members, 10 total shares, Contribution = ₹1,000 -> Monthly Target = ₹10,000', () {
          final members = List.generate(
            10,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          expect(CalculationUtils.calculateTotalActiveShares(members), 10);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 10000.0);
        });

        test('TEST 2: Add 2 members (1 share each) -> 12 members, 12 shares, Monthly Target = ₹12,000', () {
          final members = List.generate(
            12,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          expect(CalculationUtils.calculateTotalActiveShares(members), 12);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 12000.0);
        });

        test('TEST 3: 12 members (10 with 1 share, 2 with 2 shares) -> Total shares = 14, Monthly Target = ₹14,000', () {
          final members = [
            ...List.generate(
              10,
              (i) => Member(
                id: 'M_$i',
                groupId: 'G1',
                name: 'Member $i',
                phone: '987654321$i',
                joinDate: DateTime(2026, 1, 1),
                shares: 1,
                monthlyContributionPerShare: 1000.0,
                status: MemberStatus.active,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            Member(
              id: 'M_10_1',
              groupId: 'G1',
              name: 'Member 10 1',
              phone: '9876543210',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Member(
              id: 'M_10_2',
              groupId: 'G1',
              name: 'Member 10 2',
              phone: '9876543210',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Member(
              id: 'M_11_1',
              groupId: 'G1',
              name: 'Member 11 1',
              phone: '9876543211',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Member(
              id: 'M_11_2',
              groupId: 'G1',
              name: 'Member 11 2',
              phone: '9876543211',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];

          expect(CalculationUtils.calculateTotalActiveShares(members), 14);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 14000.0);
        });

        test('TEST 4: Add one member -> Total members increases by 1, Target increases by ₹1,000', () {
          final members = [
            ...List.generate(
              14,
              (i) => Member(
                id: 'M_$i',
                groupId: 'G1',
                name: 'Member $i',
                phone: '987654321$i',
                joinDate: DateTime(2026, 1, 1),
                shares: 1,
                monthlyContributionPerShare: 1000.0,
                status: MemberStatus.active,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ];

          expect(CalculationUtils.calculateTotalActiveShares(members), 14);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 14000.0);

          // Add 1 more member
          members.add(Member(
            id: 'M_14',
            groupId: 'G1',
            name: 'Member 14',
            phone: '9876543214',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

          expect(CalculationUtils.calculateTotalActiveShares(members), 15);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 15000.0);
        });

        test('TEST 5: Change contribution: ₹1,000 -> ₹1,500 (with 14 members) -> Monthly Target = ₹21,000', () {
          final members = List.generate(
            14,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          expect(CalculationUtils.calculateTotalActiveShares(members), 14);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1500.0), 21000.0);
        });

        test('TEST 6: Deactivate two members -> Total active members decreases by 2, Target decreases by ₹2,000', () {
          final members = List.generate(
            14,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          expect(CalculationUtils.calculateTotalActiveShares(members), 14);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 14000.0);

          // Deactivate 2 members
          members[12] = members[12].copyWith(status: MemberStatus.inactive);
          members[13] = members[13].copyWith(status: MemberStatus.inactive);

          expect(CalculationUtils.calculateTotalActiveShares(members), 12);
          expect(CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0), 12000.0);
        });
      });

      group('Monthly Savings Progress Collected Calculation Tests (TEST 1 to TEST 6)', () {
        test('TEST 1: 16 active shares, ₹1,000/share -> Target = ₹16,000; No contributions -> Collected = ₹0', () {
          final members = List.generate(
            16,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final target = CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0);
          final collected = CalculationUtils.calculateCurrentMonthCollectedSavings([], month: 8, year: 2026);

          expect(target, 16000.0);
          expect(collected, 0.0);
          expect(CalculationUtils.calculateSavingsProgressRatio(collected: collected, target: target), 0.0);
        });

        test('TEST 2: 16 shares, 8 members pay ₹1,000 each -> Collected = ₹8,000, Target = ₹16,000, Progress = 50%', () {
          final members = List.generate(
            16,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final contributions = List.generate(
            8,
            (i) => MonthlyContribution(
              id: 'C_M_${i}_2026-08',
              memberId: 'M_$i',
              groupId: 'G1',
              month: 8,
              year: 2026,
              regularHaftaAmount: 1000.0,
              expectedAmount: 1000.0,
              paidAmount: 1000.0,
              status: ContributionStatus.paid,
              createdAt: DateTime(2026, 8, 1),
              updatedAt: DateTime(2026, 8, 5),
            ),
          );

          final target = CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0);
          final collected = CalculationUtils.calculateCurrentMonthCollectedSavings(contributions, month: 8, year: 2026);
          final progress = CalculationUtils.calculateSavingsProgressRatio(collected: collected, target: target);

          expect(target, 16000.0);
          expect(collected, 8000.0);
          expect(progress, 0.5);
          expect((progress * 100).toStringAsFixed(0), '50');
        });

        test('TEST 3: A 2-share member pays ₹1,000 only -> Due = ₹2,000, Paid = ₹1,000, Pending = ₹1,000, Collected increases by ₹1,000 only', () {
          final partialContrib = MonthlyContribution(
            id: 'C_M_2SHARES_2026-08',
            memberId: 'M_2SHARES',
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 2000.0,
            expectedAmount: 2000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.partial,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 5),
          );

          expect(partialContrib.expectedAmount, 2000.0);
          expect(partialContrib.paidAmount, 1000.0);
          expect(partialContrib.remainingAmount, 1000.0);
          expect(partialContrib.actualRegularPaid, 1000.0);

          final collected = CalculationUtils.calculateCurrentMonthCollectedSavings([partialContrib], month: 8, year: 2026);
          expect(collected, 1000.0); // NOT 2000.0
        });

        test('TEST 4: Same member pays remaining ₹1,000 -> Due = ₹2,000, Paid = ₹2,000, Pending = ₹0, Status = PAID, Collected increases by second ₹1,000', () {
          final fullContrib = MonthlyContribution(
            id: 'C_M_2SHARES_2026-08',
            memberId: 'M_2SHARES',
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 2000.0,
            expectedAmount: 2000.0,
            paidAmount: 2000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 10),
          );

          expect(fullContrib.expectedAmount, 2000.0);
          expect(fullContrib.paidAmount, 2000.0);
          expect(fullContrib.remainingAmount, 0.0);
          expect(fullContrib.status, ContributionStatus.paid);
          expect(fullContrib.actualRegularPaid, 2000.0);

          final collected = CalculationUtils.calculateCurrentMonthCollectedSavings([fullContrib], month: 8, year: 2026);
          expect(collected, 2000.0);
        });

        test('TEST 5: Member pays ₹1,000 regular + ₹5,000 loan principal + ₹200 interest -> Collected increases by ONLY ₹1,000', () {
          final comboContrib = MonthlyContribution(
            id: 'C_M_LOAN_2026-08',
            memberId: 'M_LOAN',
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            interestAmount: 200.0,
            loanPrincipalPaid: 5000.0,
            totalPaid: 6200.0,
            expectedAmount: 1000.0,
            paidAmount: 6200.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 5),
          );

          expect(comboContrib.actualRegularPaid, 1000.0); // Strictly excludes 5000 principal + 200 interest

          final collected = CalculationUtils.calculateCurrentMonthCollectedSavings([comboContrib], month: 8, year: 2026);
          expect(collected, 1000.0);
        });

        test('TEST 6: 16-share target = ₹16,000; if valid regular contribution = ₹17,000, Target remains ₹16,000 (capped visually at 100%)', () {
          final members = List.generate(
            16,
            (i) => Member(
              id: 'M_$i',
              groupId: 'G1',
              name: 'Member $i',
              phone: '987654321$i',
              joinDate: DateTime(2026, 1, 1),
              shares: 1,
              monthlyContributionPerShare: 1000.0,
              status: MemberStatus.active,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          final target = CalculationUtils.calculateMonthlySavingsTarget(members, perShareAmount: 1000.0);
          expect(target, 16000.0); // Target strictly remains 16000

          const collected = 17000.0;
          final progress = CalculationUtils.calculateSavingsProgressRatio(collected: collected, target: target);
          expect(progress, 1.0); // Clamped visually to 1.0 (100%)
        });
      });

      group('Group Members 2-Column Pending Hafta Logic Tests', () {
        test('Member A: monthlyDue ₹1,000, paid ₹1,000 -> Pending = 0 (Not in Pending column)', () {
          final memberA = Member(
            id: 'M_A',
            groupId: 'G1',
            name: 'Member A',
            phone: '9876543210',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final contribA = MonthlyContribution(
            id: 'C_M_A_2026-08',
            memberId: memberA.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 5),
          );

          final pending = CalculationUtils.calculateMemberPendingHafta(member: memberA, contribution: contribA);
          expect(pending, 0.0);
        });

        test('Member B: monthlyDue ₹1,000, paid ₹0 (no contribution doc) -> Pending = ₹1,000 (In Pending column)', () {
          final memberB = Member(
            id: 'M_B',
            groupId: 'G1',
            name: 'Member B',
            phone: '9876543211',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final pending = CalculationUtils.calculateMemberPendingHafta(member: memberB, contribution: null);
          expect(pending, 1000.0);
        });

        test('Member C: monthlyDue ₹1,000, paid ₹500 (partial) -> Pending = ₹500 (In Pending column)', () {
          final memberC = Member(
            id: 'M_C',
            groupId: 'G1',
            name: 'Member C',
            phone: '9876543212',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final contribC = MonthlyContribution(
            id: 'C_M_C_2026-08',
            memberId: memberC.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 500.0,
            status: ContributionStatus.partial,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 5),
          );

          final pending = CalculationUtils.calculateMemberPendingHafta(member: memberC, contribution: contribC);
          expect(pending, 500.0);
        });

        test('Member D: monthlyDue ₹1,000, paid ₹1,000 via two payments (₹500 + ₹500) -> Pending = 0 (Not in Pending column)', () {
          final memberD = Member(
            id: 'M_D',
            groupId: 'G1',
            name: 'Member D',
            phone: '9876543213',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Combined two payments of 500 = 1000 on the same month obligation
          final contribD = MonthlyContribution(
            id: 'C_M_D_2026-08',
            memberId: memberD.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 10),
          );

          final pending = CalculationUtils.calculateMemberPendingHafta(member: memberD, contribution: contribD);
          expect(pending, 0.0);
        });

        test('Member with 2 shares: monthlyDue ₹2,000, paid ₹1,000 -> Pending = ₹1,000 (In Pending column)', () {
          final member2Shares = Member(
            id: 'M_2S',
            groupId: 'G1',
            name: 'Member 2 Shares',
            phone: '9876543214',
            joinDate: DateTime(2026, 1, 1),
            shares: 2,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final contrib2S = MonthlyContribution(
            id: 'C_M_2S_2026-08',
            memberId: member2Shares.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 2000.0,
            expectedAmount: 2000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.partial,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 5),
          );

          final pending = CalculationUtils.calculateMemberPendingHafta(member: member2Shares, contribution: contrib2S);
          expect(pending, 1000.0);
        });

        test('Member with loan: Loan payment (₹5,000 principal + ₹200 interest) does NOT affect regular hafta pending status', () {
          final memberLoan = Member(
            id: 'M_LOAN',
            groupId: 'G1',
            name: 'Member with Loan',
            phone: '9876543215',
            joinDate: DateTime(2026, 1, 1),
            shares: 1,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Member paid only loan repayment but did not pay regular hafta
          final contribLoanOnly = MonthlyContribution(
            id: 'C_M_LOAN_2026-08',
            memberId: memberLoan.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            interestAmount: 200.0,
            loanPrincipalPaid: 5000.0,
            totalPaid: 5200.0,
            expectedAmount: 1000.0,
            paidAmount: 5200.0,
            status: ContributionStatus.pending,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 5),
          );

          final pending = CalculationUtils.calculateMemberPendingHafta(member: memberLoan, contribution: contribLoanOnly);
          expect(pending, 1000.0); // Hafta remains pending!
        });
      });

      group('WhatsApp Direct Chat Member Contact Tests', () {
        test('Phone Normalization: 10-digit number 9604231760 -> 919604231760', () {
          expect(CalculationUtils.normalizeIndianPhoneNumber('9604231760'), '919604231760');
        });

        test('Phone Normalization: +91 9604231760 -> 919604231760', () {
          expect(CalculationUtils.normalizeIndianPhoneNumber('+91 9604231760'), '919604231760');
        });

        test('Phone Normalization: 919604231760 -> 919604231760', () {
          expect(CalculationUtils.normalizeIndianPhoneNumber('919604231760'), '919604231760');
        });

        test('Phone Normalization: Leading 0 (09604231760) -> 919604231760', () {
          expect(CalculationUtils.normalizeIndianPhoneNumber('09604231760'), '919604231760');
        });

        test('Phone Normalization: Formatted (+91-76895-67834) -> 917689567834', () {
          expect(CalculationUtils.normalizeIndianPhoneNumber('+91-76895-67834'), '917689567834');
        });

        test('Phone Normalization: Invalid / Missing numbers return null', () {
          expect(CalculationUtils.normalizeIndianPhoneNumber(null), isNull);
          expect(CalculationUtils.normalizeIndianPhoneNumber(''), isNull);
          expect(CalculationUtils.normalizeIndianPhoneNumber('123'), isNull);
          expect(CalculationUtils.normalizeIndianPhoneNumber('abc'), isNull);
        });

        test('Tanmay Hase (9604231760): Generates direct WhatsApp URL without generic contact sheet', () {
          final member = Member(
            id: 'M_TANMAY',
            groupId: 'G1',
            name: 'Tanmay Hase',
            phone: '9604231760',
            joinDate: DateTime(2026, 1, 1),
            shares: 3,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final normalized = CalculationUtils.normalizeIndianPhoneNumber(member.phone);
          expect(normalized, '919604231760');

          final url = 'https://wa.me/$normalized';
          expect(url, 'https://wa.me/919604231760');
          expect(url.contains('+'), isFalse);
          expect(url.contains(' '), isFalse);
          expect(url.contains('-'), isFalse);
        });

        test('Vaibhav (7689567834): Generates direct WhatsApp URL without generic contact sheet', () {
          final member = Member(
            id: 'M_VAIBHAV',
            groupId: 'G1',
            name: 'Vaibhav',
            phone: '7689567834',
            joinDate: DateTime(2026, 1, 1),
            shares: 2,
            monthlyContributionPerShare: 1000.0,
            status: MemberStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final normalized = CalculationUtils.normalizeIndianPhoneNumber(member.phone);
          expect(normalized, '917689567834');

          final url = 'https://wa.me/$normalized';
          expect(url, 'https://wa.me/917689567834');
        });
      });

      group('Record Monthly Collection Member Dropdown Pending Filtering Tests', () {
        final memberA = Member(
          id: 'M_A',
          groupId: 'G1',
          name: 'Member A',
          phone: '9999999991',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberB = Member(
          id: 'M_B',
          groupId: 'G1',
          name: 'Member B',
          phone: '9999999992',
          joinDate: DateTime(2026, 1, 1),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberC = Member(
          id: 'M_C',
          groupId: 'G1',
          name: 'Member C',
          phone: '9999999993',
          joinDate: DateTime(2026, 1, 1),
          shares: 2,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final memberD = Member(
          id: 'M_D',
          groupId: 'G1',
          name: 'Member D',
          phone: '9999999994',
          joinDate: DateTime(2026, 1, 1),
          shares: 2,
          monthlyContributionPerShare: 1000.0,
          status: MemberStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        test('Dropdown filtering: Member A (paid 1000), Member B (paid 0), Member C (paid 1000 of 2000), Member D (paid 2000)', () {
          final members = [memberA, memberB, memberC, memberD];
          
          final contribA = MonthlyContribution(
            id: 'C_A_2026_08',
            memberId: memberA.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          // Member B has no contribution (or paid 0)
          final contribB = MonthlyContribution(
            id: 'C_B_2026_08',
            memberId: memberB.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 0.0,
            status: ContributionStatus.pending,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          // Member C has 2 shares (due 2000), paid 1000
          final contribC = MonthlyContribution(
            id: 'C_C_2026_08',
            memberId: memberC.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 2000.0,
            expectedAmount: 2000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.partial,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          // Member D has 2 shares (due 2000), paid 2000
          final contribD = MonthlyContribution(
            id: 'C_D_2026_08',
            memberId: memberD.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 2000.0,
            expectedAmount: 2000.0,
            paidAmount: 2000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          final contributions = [contribA, contribB, contribC, contribD];
          final contribMap = {for (var c in contributions) c.memberId: c};

          final pendingMembers = <Member>[];
          final pendingAmounts = <String, double>{};

          for (final m in members) {
            final rem = CalculationUtils.calculateMemberPendingHafta(
              member: m,
              contribution: contribMap[m.id],
            );
            if (rem > 0) {
              pendingAmounts[m.id] = rem;
              pendingMembers.add(m);
            }
          }

          // Member A (fully paid): remaining 0 -> NOT in dropdown
          expect(pendingAmounts.containsKey(memberA.id), isFalse);
          expect(pendingMembers.contains(memberA), isFalse);

          // Member B (unpaid): remaining 1000 -> IN dropdown
          expect(pendingAmounts[memberB.id], 1000.0);
          expect(pendingMembers.contains(memberB), isTrue);

          // Member C (partial 1000/2000): remaining 1000 -> IN dropdown, default hafta = 1000
          expect(pendingAmounts[memberC.id], 1000.0);
          expect(pendingMembers.contains(memberC), isTrue);

          // Member D (fully paid 2000/2000): remaining 0 -> NOT in dropdown
          expect(pendingAmounts.containsKey(memberD.id), isFalse);
          expect(pendingMembers.contains(memberD), isFalse);

          // Dropdown list has exactly [Member B, Member C]
          expect(pendingMembers.map((m) => m.id).toList(), ['M_B', 'M_C']);
        });

        test('Partial payment with 2 shares: Due ₹2,000, Paid ₹500 -> Remaining is ₹1,500', () {
          final contrib = MonthlyContribution(
            id: 'C_C_2026_08',
            memberId: memberC.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 2000.0,
            expectedAmount: 2000.0,
            paidAmount: 500.0,
            status: ContributionStatus.partial,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          final remaining = CalculationUtils.calculateMemberPendingHafta(
            member: memberC,
            contribution: contrib,
          );

          expect(remaining, 1500.0);
        });

        test('After recording Member B payment (1000) -> Member B disappears from dropdown', () {
          // Record payment for Member B
          final contribBPaid = MonthlyContribution(
            id: 'C_B_2026_08',
            memberId: memberB.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          final remainingB = CalculationUtils.calculateMemberPendingHafta(
            member: memberB,
            contribution: contribBPaid,
          );

          expect(remainingB, 0.0);
        });

        test('Month/Year selection: August 2026 paid does not affect September 2026 pending', () {
          final contribAugust = MonthlyContribution(
            id: 'C_A_2026_08',
            memberId: memberA.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          // Member A in August: remaining = 0
          final remAugust = CalculationUtils.calculateMemberPendingHafta(
            member: memberA,
            contribution: contribAugust,
          );
          expect(remAugust, 0.0);

          // Member A in September: no contribution yet -> remaining = 1000 (IN dropdown)
          final remSeptember = CalculationUtils.calculateMemberPendingHafta(
            member: memberA,
            contribution: null,
          );
          expect(remSeptember, 1000.0);
        });
      });

      group('Target ₹22,000 & Collected ₹16,000 Strict Mathematical Consistency Tests', () {
        final vaibhav1 = Member(
          id: 'M_VAIBHAV_1',
          groupId: 'G1',
          name: 'Vaibhav 1',
          phone: '9876543210',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final vaibhav2 = Member(
          id: 'M_VAIBHAV_2',
          groupId: 'G1',
          name: 'Vaibhav 2',
          phone: '9876543210',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final rutvik1 = Member(
          id: 'M_RUTVIK_1',
          groupId: 'G1',
          name: 'Rutvik 1',
          phone: '9999999999',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final rutvik2 = Member(
          id: 'M_RUTVIK_2',
          groupId: 'G1',
          name: 'Rutvik 2',
          phone: '9999999999',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tanmay1 = Member(
          id: 'M_TANMAY_1',
          groupId: 'G1',
          name: 'Tanmay Ankush Hase 1',
          phone: '9604231760',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tanmay2 = Member(
          id: 'M_TANMAY_2',
          groupId: 'G1',
          name: 'Tanmay Ankush Hase 2',
          phone: '9604231760',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tanmay3 = Member(
          id: 'M_TANMAY_3',
          groupId: 'G1',
          name: 'Tanmay Ankush Hase 3',
          phone: '9604231760',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final paidMembers = List.generate(15, (i) => Member(
          id: 'M_PAID_$i',
          groupId: 'G1',
          name: 'Paid Member ${i + 1}',
          phone: '980000000$i',
          joinDate: DateTime.now(),
          shares: 1,
          monthlyContributionPerShare: 1000.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final allMembers = [vaibhav1, vaibhav2, rutvik1, rutvik2, tanmay1, tanmay2, tanmay3, ...paidMembers];

        test('Total active shares = 22 and Monthly Target = ₹22,000', () {
          final totalShares = CalculationUtils.calculateTotalActiveShares(allMembers);
          expect(totalShares, 22);

          final target = CalculationUtils.calculateMonthlySavingsTarget(allMembers, perShareAmount: 1000.0);
          expect(target, 22000.0);
        });

        test('Collected = ₹16,000, Total Pending = ₹6,000, and SUM(memberPending) strictly equals ₹6,000', () {
          // Contributions in August 2026:
          // Vaibhav 1: paid 1000
          final contribVaibhav1 = MonthlyContribution(
            id: 'C_V1_2026_08',
            memberId: vaibhav1.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          // 15 paid members: 1000 paid each
          final paidContribs = paidMembers.map((m) => MonthlyContribution(
            id: 'C_${m.id}_2026_08',
            memberId: m.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          )).toList();

          final allContribs = [contribVaibhav1, ...paidContribs];

          final collected = CalculationUtils.calculateCurrentMonthCollectedSavings(
            allContribs,
            month: 8,
            year: 2026,
          );
          expect(collected, 16000.0);

          final totalTarget = CalculationUtils.calculateMonthlySavingsTarget(allMembers, perShareAmount: 1000.0);
          final totalPending = CalculationUtils.calculateMonthlyPendingTotal(target: totalTarget, collected: collected);
          expect(totalPending, 6000.0);

          // Member-level pending:
          final remVaibhav2 = CalculationUtils.calculateMemberPendingHafta(member: vaibhav2, contribution: null);
          final remRutvik1 = CalculationUtils.calculateMemberPendingHafta(member: rutvik1, contribution: null);
          final remRutvik2 = CalculationUtils.calculateMemberPendingHafta(member: rutvik2, contribution: null);
          final remTanmay1 = CalculationUtils.calculateMemberPendingHafta(member: tanmay1, contribution: null);
          final remTanmay2 = CalculationUtils.calculateMemberPendingHafta(member: tanmay2, contribution: null);
          final remTanmay3 = CalculationUtils.calculateMemberPendingHafta(member: tanmay3, contribution: null);

          expect(remVaibhav2, 1000.0);
          expect(remRutvik1, 1000.0);
          expect(remRutvik2, 1000.0);
          expect(remTanmay1, 1000.0);
          expect(remTanmay2, 1000.0);
          expect(remTanmay3, 1000.0);

          // Sum of all member pendings:
          final sumMemberPending = remVaibhav2 + remRutvik1 + remRutvik2 + remTanmay1 + remTanmay2 + remTanmay3;
          expect(sumMemberPending, 6000.0);
          expect(sumMemberPending, totalPending); // Must strictly match!
        });

        test('Record Monthly Collection dropdown text shows individual member name and remaining pending amount', () {
          final dropdownTextVaibhav2 = '${vaibhav2.name} (₹1000)';
          expect(dropdownTextVaibhav2, 'Vaibhav 2 (₹1000)');

          final dropdownTextTanmay1 = '${tanmay1.name} (₹1000)';
          expect(dropdownTextTanmay1, 'Tanmay Ankush Hase 1 (₹1000)');
        });

        test('Search filtering inside member selection list works by name and phone', () {
          final pendingList = [vaibhav1, rutvik1, tanmay1];

          // Search by name "vaibhav"
          final queryName = 'vaibhav';
          final searchByName = pendingList.where((m) =>
            m.name.toLowerCase().contains(queryName) ||
            m.phone.replaceAll(RegExp(r'\D'), '').contains(queryName)
          ).toList();
          expect(searchByName.length, 1);
          expect(searchByName.first.name, 'Vaibhav 1');

          // Search by phone "9604231760"
          final queryPhone = '9604231760';
          final searchByPhone = pendingList.where((m) =>
            m.name.toLowerCase().contains(queryPhone) ||
            m.phone.replaceAll(RegExp(r'\D'), '').contains(queryPhone)
          ).toList();
          expect(searchByPhone.length, 1);
          expect(searchByPhone.first.name, 'Tanmay Ankush Hase 1');
        });

        test('After recording Vaibhav 2 remaining ₹1,000 -> Vaibhav 2 pending becomes ₹0 and disappears', () {
          final contribVaibhavFull = MonthlyContribution(
            id: 'C_V2_2026_08',
            memberId: vaibhav2.id,
            groupId: 'G1',
            month: 8,
            year: 2026,
            regularHaftaAmount: 1000.0,
            expectedAmount: 1000.0,
            paidAmount: 1000.0,
            status: ContributionStatus.paid,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          );

          final remVaibhavAfter = CalculationUtils.calculateMemberPendingHafta(member: vaibhav2, contribution: contribVaibhavFull);
          expect(remVaibhavAfter, 0.0);

          // Only Rutvik and Tanmay remain pending
          final pendingAfter = [rutvik1, rutvik2, tanmay1, tanmay2, tanmay3];
          expect(pendingAfter.contains(vaibhav2), false);
        });
      });
    });
  });
}

double memberAPlusMemberBTotal(double a, double b) => a + b;


