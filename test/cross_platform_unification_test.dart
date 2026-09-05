import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/firebase_options.dart';
import 'package:bachat_gat/models/group.dart';
import 'package:bachat_gat/models/member.dart';
import 'package:bachat_gat/models/monthly_contribution.dart';
import 'package:bachat_gat/models/loan.dart';
import 'package:bachat_gat/models/loan_repayment.dart';
import 'package:bachat_gat/models/transaction.dart';
import 'package:bachat_gat/models/report_models.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';

void main() {
  group('CROSS-PLATFORM UNIFICATION VERIFICATION SUITE', () {
    test('STEP 1 & 3: Web and Mobile point to the EXACT SAME Firebase project', () {
      expect(DefaultFirebaseOptions.web.projectId, equals('bachat-gat-app-9e38e'));
      expect(DefaultFirebaseOptions.android.projectId, equals('bachat-gat-app-9e38e'));
      expect(DefaultFirebaseOptions.ios.projectId, equals('bachat-gat-app-9e38e'));
      expect(DefaultFirebaseOptions.web.storageBucket, equals('bachat-gat-app-9e38e.firebasestorage.app'));
      expect(DefaultFirebaseOptions.android.storageBucket, equals('bachat-gat-app-9e38e.firebasestorage.app'));
      expect(DefaultFirebaseOptions.ios.storageBucket, equals('bachat-gat-app-9e38e.firebasestorage.app'));
    });

    test('STEP 4 & 5 & 6: Data contract - Member / User schema serialization and status standardization', () {
      final now = DateTime(2026, 8, 10, 10, 0, 0);
      final member = Member(
        id: 'M_101',
        groupId: 'shivshahi_group_001',
        name: 'अमोल पांडुरंग थोरात 1',
        phone: '9876543210',
        email: 'amol@example.com',
        role: 'MEMBER',
        memberCode: 'M_101',
        joinDate: now,
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final json = member.toJson();
      expect(json['uid'], equals('M_101'));
      expect(json['id'], equals('M_101'));
      expect(json['fullName'], equals('अमोल पांडुरंग थोरात 1'));
      expect(json['name'], equals('अमोल पांडुरंग थोरात 1'));
      expect(json['monthlyShare'], equals(1000.0));
      expect(json['monthlyContribution'], equals(1000.0));
      expect(json['status'], equals('ACTIVE'));
      expect(json['groupId'], equals('shivshahi_group_001'));

      // Deserialization from web schema format
      final fromWeb = Member.fromJson({
        'uid': 'M_101',
        'fullName': 'अमोल पांडुरंग थोरात 1',
        'email': 'amol@example.com',
        'phone': '9876543210',
        'role': 'MEMBER',
        'groupId': 'shivshahi_group_001',
        'memberCode': 'M_101',
        'monthlyShare': 1000,
        'status': 'ACTIVE',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(fromWeb.id, equals('M_101'));
      expect(fromWeb.name, equals('अमोल पांडुरंग थोरात 1'));
      expect(fromWeb.monthlyContribution, equals(1000.0));
      expect(fromWeb.shares, equals(1));
      expect(fromWeb.status, equals(MemberStatus.active));
    });

    test('STEP 10: MonthlyContribution Data Contract & Serialization', () {
      final now = DateTime(2026, 8, 10, 10, 30, 0);
      final contrib = MonthlyContribution(
        id: 'C_M_101_2026_08',
        memberId: 'M_101',
        groupId: 'shivshahi_group_001',
        month: 8,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 1000.0,
        expectedAmount: 1000.0,
        paidAmount: 1000.0,
        paymentDate: now,
        status: ContributionStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      final json = contrib.toJson();
      expect(json['groupId'], equals('shivshahi_group_001'));
      expect(json['memberId'], equals('M_101'));
      expect(json['month'], equals(8));
      expect(json['year'], equals(2026));
      expect(json['amount'], equals(1000.0));
      expect(json['status'], equals('PAID'));
      expect(json['paidAt'], equals(now.toIso8601String()));

      // Web format deserialization
      final fromWeb = MonthlyContribution.fromJson({
        'id': 'C_M_101_2026_08',
        'groupId': 'shivshahi_group_001',
        'memberId': 'M_101',
        'month': 8,
        'year': 2026,
        'amount': 1000,
        'status': 'PAID',
        'paidAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(fromWeb.id, equals('C_M_101_2026_08'));
      expect(fromWeb.paidAmount, equals(1000.0));
      expect(fromWeb.status, equals(ContributionStatus.paid));
    });

    test('STEP 11: Loan Data Contract & Serialization', () {
      final now = DateTime(2026, 8, 1, 12, 0, 0);
      final loan = Loan(
        id: 'L_101',
        groupId: 'shivshahi_group_001',
        memberId: 'M_101',
        originalPrincipal: 10000.0,
        pendingPrincipal: 10000.0,
        interestRate: 2.0,
        loanDate: now,
        status: LoanStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final json = loan.toJson();
      expect(json['groupId'], equals('shivshahi_group_001'));
      expect(json['memberId'], equals('M_101'));
      expect(json['principalAmount'], equals(10000.0));
      expect(json['remainingAmount'], equals(10000.0));
      expect(json['interestRate'], equals(2.0));
      expect(json['status'], equals('ACTIVE'));
      expect(json['issuedAt'], equals(now.toIso8601String()));

      // Web format deserialization
      final fromWeb = Loan.fromJson({
        'loanId': 'L_101',
        'groupId': 'shivshahi_group_001',
        'memberId': 'M_101',
        'principalAmount': 10000,
        'remainingAmount': 10000,
        'interestRate': 2.0,
        'status': 'ACTIVE',
        'issuedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(fromWeb.id, equals('L_101'));
      expect(fromWeb.originalPrincipal, equals(10000.0));
      expect(fromWeb.pendingPrincipal, equals(10000.0));
      expect(fromWeb.status, equals(LoanStatus.active));
    });

    test('STEP 12: LoanRepayment Data Contract & Serialization', () {
      final now = DateTime(2026, 8, 10, 11, 0, 0);
      final rep = LoanRepayment(
        id: 'R_L_101_2026_08',
        loanId: 'L_101',
        groupId: 'shivshahi_group_001',
        memberId: 'M_101',
        month: 8,
        year: 2026,
        openingPrincipal: 10000.0,
        interestRate: 2.0,
        interestAmount: 200.0,
        regularContribution: 1000.0,
        principalRepaid: 5000.0,
        totalPaid: 6200.0,
        closingPrincipal: 5000.0,
        paymentDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = rep.toJson();
      expect(json['groupId'], equals('shivshahi_group_001'));
      expect(json['loanId'], equals('L_101'));
      expect(json['memberId'], equals('M_101'));
      expect(json['amount'], equals(6200.0));
      expect(json['principalPaid'], equals(5000.0));
      expect(json['interestPaid'], equals(200.0));
      expect(json['paidAt'], equals(now.toIso8601String()));

      // Web format deserialization
      final fromWeb = LoanRepayment.fromJson({
        'repaymentId': 'R_L_101_2026_08',
        'groupId': 'shivshahi_group_001',
        'loanId': 'L_101',
        'memberId': 'M_101',
        'amount': 6200,
        'principalPaid': 5000,
        'interestPaid': 200,
        'paidAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      expect(fromWeb.id, equals('R_L_101_2026_08'));
      expect(fromWeb.principalRepaid, equals(5000.0));
      expect(fromWeb.interestAmount, equals(200.0));
      expect(fromWeb.totalPaid, equals(6200.0));
    });

    test('STEP 13: Dashboard Unification Calculations', () {
      const totalSavings = 50000.0;
      const totalInterest = 1200.0;
      const outstandingLoans = 15000.0;

      final availableFund = CalculationUtils.calculateAvailableFund(
        totalSavings: totalSavings,
        outstandingLoans: outstandingLoans,
        totalInterest: totalInterest,
      );
      expect(availableFund, equals(36200.0)); // (50,000 + 1,200) - 15,000 = 36,200

      final totalGroupFund = CalculationUtils.calculateTotalGroupFund(
        availableCash: availableFund,
        outstandingLoans: outstandingLoans,
      );
      expect(totalGroupFund, equals(51200.0)); // 36,200 + 15,000 = 51,200 (Total Assets)
    });

    test('CRITICAL FIX: ₹70 Loan Repayment does NOT reduce Monthly Savings Collection (₹5,000 vs ₹4,930 Mismatch Resolution)', () {
      final now = DateTime(2026, 8, 10);
      
      // 5 member contributions for August 2026 (₹1,000 each)
      final contrib1 = MonthlyContribution(
        id: 'C_M_1_2026_08',
        memberId: 'M_1',
        groupId: 'test_group',
        month: 8,
        year: 2026,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        totalPaid: 1000.0,
        status: ContributionStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      final contrib2 = MonthlyContribution(
        id: 'C_M_2_2026_08',
        memberId: 'M_2',
        groupId: 'test_group',
        month: 8,
        year: 2026,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        totalPaid: 1000.0,
        status: ContributionStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      final contrib3 = MonthlyContribution(
        id: 'C_M_3_2026_08',
        memberId: 'M_3',
        groupId: 'test_group',
        month: 8,
        year: 2026,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        totalPaid: 1000.0,
        status: ContributionStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      final contrib4 = MonthlyContribution(
        id: 'C_M_4_2026_08',
        memberId: 'M_4',
        groupId: 'test_group',
        month: 8,
        year: 2026,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        totalPaid: 1000.0,
        status: ContributionStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      // Member 5 paid ₹1,000 regular hafta AND had ₹50 principal + ₹20 interest repayment recorded
      final contrib5 = MonthlyContribution(
        id: 'C_M_5_2026_08',
        memberId: 'M_5',
        groupId: 'test_group',
        month: 8,
        year: 2026,
        paidAmount: 1000.0,
        expectedAmount: 1000.0,
        regularHaftaAmount: 1000.0,
        interestAmount: 20.0,
        loanPrincipalPaid: 50.0,
        totalPaid: 1000.0,
        status: ContributionStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      // Verify Member 5 actualRegularPaid is strictly ₹1,000 (NOT ₹930)
      expect(contrib5.actualRegularPaid, equals(1000.0));

      final allContribs = [contrib1, contrib2, contrib3, contrib4, contrib5];

      final collected = CalculationUtils.calculateCurrentMonthCollectedSavings(
        allContribs,
        month: 8,
        year: 2026,
      );

      // Total collected amount MUST be strictly ₹5,000 (Matching Web exactly, NOT ₹4,930)
      expect(collected, equals(5000.0));

      final totalSavings = CalculationUtils.calculateTotalSavings(allContribs);
      expect(totalSavings, equals(5000.0));
    });
  });
}

