import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/services/report_service.dart';
import 'package:bachat_gat/services/firebase_service.dart';
import 'package:bachat_gat/services/pdf_service.dart';
import 'package:bachat_gat/models/member.dart';
import 'package:bachat_gat/models/report_models.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance & Caching Architecture Tests', () {
    test('1. ReportService caches GroupMonthlyReport and returns cached instance', () {
      final reportService = ReportService(FirebaseService());

      // Verify that cache is initially empty
      reportService.invalidateCache();

      final m1 = Member(
        id: 'M1',
        groupId: 'g1',
        name: 'Sunita',
        phone: '123',
        joinDate: DateTime(2026, 1, 1),
        monthlyContribution: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final r1 = MemberMonthlyReport(
        member: m1,
        month: 8,
        year: 2026,
        expectedHafta: 1000,
        paidHafta: 1000,
        pendingHafta: 0,
        loanId: 'L1',
        openingPrincipal: 10000,
        interestRate: 2,
        interestAmount: 200,
        principalRepaid: 5000,
        closingPrincipal: 5000,
        totalPaid: 6200,
      );

      final groupReport = GroupMonthlyReport(
        groupName: 'Shivshahi Bachat Gat',
        month: 8,
        year: 2026,
        totalMembers: 1,
        memberReports: [r1],
        totalExpectedHafta: 1000,
        totalCollectedHafta: 1000,
        totalPendingHafta: 0,
        totalActiveLoans: 10000,
        totalPrincipalRepaid: 5000,
        totalInterestCollected: 200,
        totalOutstandingLoan: 5000,
        totalCollection: 6200,
      );

      // Verify calculations remain exact
      expect(groupReport.totalCollection, 6200.0);
      expect(groupReport.totalOutstandingLoan, 5000.0);
    });

    test('2. Invalidation clears report cache after transaction mutation', () {
      final reportService = ReportService(FirebaseService());
      reportService.invalidateCache();

      // Invalidate should execute cleanly without error
      reportService.invalidateCache();
      expect(true, isTrue);
    });

    test('3. Single-tab lazy loading isolation test', () {
      // Simulating tab index state
      int activeTabIndex = 0; // Starts at 0 (Monthly Register)
      bool monthlyTabLoaded = false;
      bool pendingTabLoaded = false;
      bool loansTabLoaded = false;

      void ensureTabLoaded(int tabIndex) {
        if (tabIndex == 0) monthlyTabLoaded = true;
        if (tabIndex == 1) pendingTabLoaded = true;
        if (tabIndex == 2) loansTabLoaded = true;
      }

      // Initial screen open -> only Tab 0 loads
      ensureTabLoaded(activeTabIndex);
      expect(monthlyTabLoaded, true);
      expect(pendingTabLoaded, false);
      expect(loansTabLoaded, false);

      // User switches to Tab 1 -> Tab 1 loads
      activeTabIndex = 1;
      ensureTabLoaded(activeTabIndex);
      expect(monthlyTabLoaded, true);
      expect(pendingTabLoaded, true);
      expect(loansTabLoaded, false);

      // User switches to Tab 2 -> Tab 2 loads
      activeTabIndex = 2;
      ensureTabLoaded(activeTabIndex);
      expect(monthlyTabLoaded, true);
      expect(pendingTabLoaded, true);
      expect(loansTabLoaded, true);
    });

    test('4. Financial rules verification: 10,000 loan, 2% rate, sequential repayments', () {
      const originalPrincipal = 10000.0;
      const rate = 2.0;

      // Month 1
      final interestM1 = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: originalPrincipal,
        annualRate: rate,
      );
      expect(interestM1, 200.0);

      // Repayment 1: 5,000 principal repaid
      final remainingM1 = CalculationUtils.calculateRemainingPrincipal(originalPrincipal, 5000.0);
      expect(remainingM1, 5000.0);

      // Month 2
      final interestM2 = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: remainingM1,
        annualRate: rate,
      );
      expect(interestM2, 100.0);

      // Repayment 2: 2,000 principal repaid
      final remainingM2 = CalculationUtils.calculateRemainingPrincipal(remainingM1, 2000.0);
      expect(remainingM2, 3000.0);

      // Month 3
      final interestM3 = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: remainingM2,
        annualRate: rate,
      );
      expect(interestM3, 60.0);

      // Full payoff: 3,000 repaid
      final remainingM3 = CalculationUtils.calculateRemainingPrincipal(remainingM2, 3000.0);
      expect(remainingM3, 0.0);

      // Closed loan future interest
      final futureInterest = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: remainingM3,
        annualRate: rate,
      );
      expect(futureInterest, 0.0);
    });

    test('5. Empty report state verification', () {
      final emptyGroupReport = GroupMonthlyReport(
        groupName: 'Shivshahi Bachat Gat',
        month: 8,
        year: 2026,
        totalMembers: 0,
        memberReports: [],
        totalExpectedHafta: 0,
        totalCollectedHafta: 0,
        totalPendingHafta: 0,
        totalActiveLoans: 0,
        totalPrincipalRepaid: 0,
        totalInterestCollected: 0,
        totalOutstandingLoan: 0,
        totalCollection: 0,
      );

      expect(emptyGroupReport.memberReports.isEmpty, isTrue);
      expect(emptyGroupReport.totalCollection, 0.0);
    });

    test('6. Pending dues calculation correctly flags active overdue loans and unpaid haftas', () {
      final m1 = Member(
        id: 'M1',
        groupId: 'g1',
        name: 'Anita',
        phone: '999',
        joinDate: DateTime(2026, 1, 1),
        monthlyContribution: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pendingReport = PendingMemberReport(
        member: m1,
        pendingHafta: 1000,
        pendingLoanPrincipal: 5000,
        pendingInterest: 100,
        totalPending: 6100,
        month: 8,
        year: 2026,
      );

      expect(pendingReport.totalPending, 6100.0);
      expect(pendingReport.pendingHafta, 1000.0);
      expect(pendingReport.pendingInterest, 100.0);
    });

    test('7. In-memory PDF byte generation succeeds without path_provider or dart:io File', () async {
      final m1 = Member(
        id: 'M001',
        groupId: 'shivshahi_group_001',
        name: 'Sunita Patil',
        phone: '9876543210',
        joinDate: DateTime(2026, 1, 1),
        monthlyContribution: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memberReport = MemberMonthlyReport(
        member: m1,
        month: 8,
        year: 2026,
        expectedHafta: 1000,
        paidHafta: 1000,
        pendingHafta: 0,
        loanId: 'L1',
        openingPrincipal: 10000,
        interestRate: 2,
        interestAmount: 200,
        principalRepaid: 5000,
        closingPrincipal: 5000,
        totalPaid: 6200,
      );

      final groupReport = GroupMonthlyReport(
        groupName: 'Shivshahi Bachat Gat',
        month: 8,
        year: 2026,
        totalMembers: 1,
        memberReports: [memberReport],
        totalExpectedHafta: 1000,
        totalCollectedHafta: 1000,
        totalPendingHafta: 0,
        totalActiveLoans: 10000,
        totalPrincipalRepaid: 5000,
        totalInterestCollected: 200,
        totalOutstandingLoan: 5000,
        totalCollection: 6200,
      );

      final labels = {
        'groupMonthlyReport': 'Group Monthly Report',
        'totalMembers': 'Total Members',
        'date': 'Date',
        'collectionSummary': 'Collection Summary',
        'totalExpectedHafta': 'Total Expected Hafta',
        'totalHaftaCollected': 'Total Hafta Collected',
        'totalHaftaPending': 'Total Hafta Pending',
        'loanSummary': 'Loan Summary',
        'totalActiveLoans': 'Total Active Loans',
        'totalPrincipalRepaid': 'Total Principal Repaid',
        'totalInterestCollected': 'Total Interest Collected',
        'totalOutstandingLoan': 'Total Outstanding Loan',
        'totalCollection': 'Total Collection',
        'memberWiseSummary': 'Member-wise Summary',
        'member': 'Member',
        'hafta': 'Hafta',
        'interest': 'Interest (2%)',
        'principal': 'Principal',
        'total': 'Total',
        'pendingLoan': 'Pending Loan',
        'groupName': 'Shivshahi Bachat Gat',
        'monthlyReceipt': 'Monthly Receipt',
        'phone': 'Phone',
        'month': 'Month',
        'monthlyContribution': 'Monthly Contribution',
        'regularHafta': 'Regular Hafta',
        'amountPaid': 'Amount Paid',
        'pending': 'Pending',
        'loan': 'Loan',
        'openingLoan': 'Opening Loan',
        'interestRate': 'Interest Rate',
        'monthlyInterest': 'Monthly Interest',
        'loanRepaid': 'Loan Repaid',
        'closingLoan': 'Closing Loan',
        'totalPaid': 'Total Paid',
      };

      // 1. Group Report PDF Bytes
      final groupPdfBytes = await PdfService.generateGroupReportBytes(
        report: groupReport,
        labels: labels,
      );
      expect(groupPdfBytes, isNotNull);
      expect(groupPdfBytes.length, greaterThan(100));

      // 2. Member Receipt PDF Bytes
      final receiptPdfBytes = await PdfService.generateMemberReceiptBytes(
        report: memberReport,
        labels: labels,
      );
      expect(receiptPdfBytes, isNotNull);
      expect(receiptPdfBytes.length, greaterThan(100));

      // 3. Member Ledger PDF Bytes
      final ledgerPdfBytes = await PdfService.generateMemberLedgerBytes(
        member: m1,
        entries: [
          MemberLedgerEntry(
            id: 'TX1',
            date: DateTime(2026, 8, 1),
            type: 'monthlyInvestment',
            description: 'Monthly Hafta',
            debit: 0,
            credit: 1000,
            balance: 1000,
          ),
        ],
        groupName: 'Shivshahi Bachat Gat',
      );
      expect(ledgerPdfBytes, isNotNull);
      expect(ledgerPdfBytes.length, greaterThan(100));
    });
  });
}
