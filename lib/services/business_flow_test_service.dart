import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/transaction.dart';
import '../repositories/group_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/firebase_service.dart';
import '../core/utils/calculation_utils.dart';

class BusinessFlowTestService {
  static Future<Map<String, bool>> runFullBusinessFlowTest({
    required FirebaseService firebaseService,
    required GroupRepository groupRepo,
    required TransactionRepository txRepo,
  }) async {
    final results = <String, bool>{};
    final testGroupId = 'test_group_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('=====================================================');
    debugPrint('STARTING COMPREHENSIVE BUSINESS RULES & FIRESTORE TEST');
    debugPrint('=====================================================');

    try {
      // 0. Ensure Group Exists with initial funds (₹30,500 available fund)
      await groupRepo.ensureGroupExists(testGroupId);
      await firebaseService.groups.doc(testGroupId).set({
        'id': testGroupId,
        'name': 'Test Group Flow',
        'managerId': 'manager_test',
        'monthlyTarget': 5000.0,
        'monthlyContributionAmount': 1000.0,
        'totalFund': 30500.0,
        'totalSavings': 30500.0,
        'totalOutstandingLoans': 0.0,
        'totalInterestCollected': 0.0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      final groupDoc = await firebaseService.groups.doc(testGroupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group $testGroupId document was not found or created.');
      }
      debugPrint('STEP 0: Initialized group with available balance = ₹30,500');

      final testTimestamp = DateTime.now().millisecondsSinceEpoch;
      final memberAId = 'M_A_$testTimestamp';
      final memberBId = 'M_B_$testTimestamp';

      // -----------------------------------------------------------------
      // TEST 1: Member + Multiple Shares Creation
      // Member A: 3 shares @ 1000 = ₹3000
      // Member B: 2 shares @ 1000 = ₹2000
      // Total monthly = ₹5000
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 1: MEMBER + MULTIPLE SHARES CREATION ---');
      final memberA = Member(
        id: memberAId,
        groupId: testGroupId,
        name: 'Member A (3 Shares)',
        phone: '9888888881',
        joinDate: DateTime(2026, 8, 1),
        shares: 3,
        monthlyContributionPerShare: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final memberB = Member(
        id: memberBId,
        groupId: testGroupId,
        name: 'Member B (2 Shares)',
        phone: '9888888882',
        joinDate: DateTime(2026, 8, 1),
        shares: 2,
        monthlyContributionPerShare: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await groupRepo.addMember(memberA);
      await groupRepo.addMember(memberB);

      final mDocA = await firebaseService.members(testGroupId).doc(memberAId).get();
      final mDocB = await firebaseService.members(testGroupId).doc(memberBId).get();

      final dataA = mDocA.data() as Map<String, dynamic>;
      final dataB = mDocB.data() as Map<String, dynamic>;

      final isMultiShareValid = dataA['shares'] == 3 &&
          dataA['monthlyContribution'] == 3000.0 &&
          dataB['shares'] == 2 &&
          dataB['monthlyContribution'] == 2000.0 &&
          (dataA['monthlyContribution'] + dataB['monthlyContribution']) == 5000.0;

      results['multi_shares_validation'] = isMultiShareValid;
      debugPrint(isMultiShareValid
          ? 'TEST 1 PASSED: Member A (3 shares = ₹3000) & Member B (2 shares = ₹2000), Total = ₹5000'
          : 'TEST 1 FAILED: Multi-share calculations mismatch');

      // -----------------------------------------------------------------
      // TEST 2: Loan Issuance Under Sufficient Balance
      // Available = ₹30,500 -> Request Loan = ₹20,000 -> ALLOWED
      // New Available = ₹10,500, Active Loans = ₹20,000
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 2: LOAN ISSUANCE UNDER SUFFICIENT BALANCE ---');
      final loan1Id = 'L1_$testTimestamp';
      final loan1 = Loan(
        id: loan1Id,
        groupId: testGroupId,
        memberId: memberAId,
        originalPrincipal: 20000.0,
        pendingPrincipal: 20000.0,
        interestRate: 2.0,
        loanDate: DateTime.now(),
        purpose: 'Agriculture Support',
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txLoan1 = AppTransaction(
        id: 'T_${testTimestamp}_loan1',
        memberId: memberAId,
        memberName: 'Member A',
        type: TransactionType.loanIssue,
        amount: 20000.0,
        date: DateTime.now(),
        description: 'Loan Issued: ₹20,000',
        referenceId: loan1Id,
      );

      await txRepo.issueLoan(testGroupId, loan1, txLoan1);

      final gDocAfterLoan1 = await firebaseService.groups.doc(testGroupId).get();
      final gData1 = gDocAfterLoan1.data() as Map<String, dynamic>;
      final availableAfterLoan1 = (gData1['totalFund'] as num).toDouble();
      final outstandingAfterLoan1 = (gData1['totalOutstandingLoans'] as num).toDouble();

      final isLoan1Success = availableAfterLoan1 == 10500.0 && outstandingAfterLoan1 == 20000.0;
      results['loan_sufficient_balance'] = isLoan1Success;
      debugPrint(isLoan1Success
          ? 'TEST 2 PASSED: Loan ₹20,000 issued. Available Balance updated from ₹30,500 -> ₹10,500'
          : 'TEST 2 FAILED: Available balance after loan is ₹$availableAfterLoan1');

      // -----------------------------------------------------------------
      // TEST 3: Loan Issuance Rejection Under Insufficient Balance
      // Available = ₹10,500 -> Request Loan = ₹15,000 -> REJECTED
      // Balance must remain ₹10,500 (STRICT NO NEGATIVE RULE)
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 3: LOAN ISSUANCE REJECTION UNDER INSUFFICIENT BALANCE ---');
      final loan2Id = 'L2_$testTimestamp';
      final loan2 = Loan(
        id: loan2Id,
        groupId: testGroupId,
        memberId: memberBId,
        originalPrincipal: 15000.0,
        pendingPrincipal: 15000.0,
        interestRate: 2.0,
        loanDate: DateTime.now(),
        purpose: 'Small Shop',
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txLoan2 = AppTransaction(
        id: 'T_${testTimestamp}_loan2',
        memberId: memberBId,
        memberName: 'Member B',
        type: TransactionType.loanIssue,
        amount: 15000.0,
        date: DateTime.now(),
        description: 'Loan Issued: ₹15,000',
        referenceId: loan2Id,
      );

      bool loan2Rejected = false;
      try {
        await txRepo.issueLoan(testGroupId, loan2, txLoan2);
      } catch (e) {
        loan2Rejected = true;
        debugPrint('Loan ₹15,000 correctly rejected with: $e');
      }

      final gDocAfterLoan2 = await firebaseService.groups.doc(testGroupId).get();
      final gData2 = gDocAfterLoan2.data() as Map<String, dynamic>;
      final availableAfterLoan2 = (gData2['totalFund'] as num).toDouble();

      final isLoan2Handled = loan2Rejected && availableAfterLoan2 == 10500.0;
      results['loan_insufficient_balance_rejected'] = isLoan2Handled;
      results['strict_no_negative_rule'] = availableAfterLoan2 >= 0;
      debugPrint(isLoan2Handled
          ? 'TEST 3 PASSED: Insufficient loan rejected. Available balance strictly remains ₹10,500 (NOT negative)'
          : 'TEST 3 FAILED: Insufficient loan was allowed or balance corrupted');

      // -----------------------------------------------------------------
      // TEST 4: Loan Partial Repayment
      // Outstanding = ₹20,000 -> Principal Repay = ₹5,000 -> Outstanding = ₹15,000
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 4: LOAN PARTIAL REPAYMENT ---');
      final repayment1Id = 'R1_$testTimestamp';
      final interestAmount = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: 20000.0,
        annualRate: 2.0,
      ); // ₹400

      final repayment1 = LoanRepayment(
        id: repayment1Id,
        loanId: loan1Id,
        groupId: testGroupId,
        memberId: memberAId,
        month: 8,
        year: 2026,
        openingPrincipal: 20000.0,
        interestRate: 2.0,
        interestAmount: interestAmount,
        regularContribution: 3000.0,
        principalRepaid: 5000.0,
        totalPaid: 8400.0, // 3000 hafta + 400 interest + 5000 principal
        closingPrincipal: 15000.0,
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txRepay1 = AppTransaction(
        id: 'T_${testTimestamp}_repay1',
        memberId: memberAId,
        memberName: 'Member A',
        type: TransactionType.loanRepayment,
        amount: 8400.0,
        date: DateTime.now(),
        description: 'Repayment (Hafta: ₹3000, Interest: ₹400, Principal: ₹5000)',
        referenceId: repayment1Id,
      );

      await txRepo.recordLoanRepayment(
        groupId: testGroupId,
        loan: loan1,
        repayment: repayment1,
        tx: txRepay1,
      );

      final lDocAfterRepay1 = await firebaseService.loans(testGroupId).doc(loan1Id).get();
      final lData1 = lDocAfterRepay1.data() as Map<String, dynamic>;
      final pendingLoan1 = (lData1['pendingPrincipal'] as num).toDouble();

      final isRepay1Success = pendingLoan1 == 15000.0;
      results['loan_repayment_valid'] = isRepay1Success;
      debugPrint(isRepay1Success
          ? 'TEST 4 PASSED: Outstanding loan reduced from ₹20,000 -> ₹15,000'
          : 'TEST 4 FAILED: Pending loan is ₹$pendingLoan1');

      // -----------------------------------------------------------------
      // TEST 5: Over-Repayment Rejection
      // Outstanding = ₹15,000 -> Repay = ₹20,000 -> REJECTED
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 5: OVER-REPAYMENT REJECTION ---');
      final repayment2Id = 'R2_$testTimestamp';
      final currentLoanDoc = await firebaseService.loans(testGroupId).doc(loan1Id).get();
      final currentLoan = Loan.fromJson(currentLoanDoc.data() as Map<String, dynamic>);

      final overRepayment = LoanRepayment(
        id: repayment2Id,
        loanId: loan1Id,
        groupId: testGroupId,
        memberId: memberAId,
        month: 9,
        year: 2026,
        openingPrincipal: 15000.0,
        interestRate: 2.0,
        interestAmount: 300.0,
        regularContribution: 0.0,
        principalRepaid: 20000.0, // Exceeds 15,000 pending!
        totalPaid: 20300.0,
        closingPrincipal: 0.0,
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txOverRepay = AppTransaction(
        id: 'T_${testTimestamp}_over',
        memberId: memberAId,
        memberName: 'Member A',
        type: TransactionType.loanRepayment,
        amount: 20300.0,
        date: DateTime.now(),
        description: 'Over-repayment attempt',
        referenceId: repayment2Id,
      );

      bool overRepayRejected = false;
      try {
        await txRepo.recordLoanRepayment(
          groupId: testGroupId,
          loan: currentLoan,
          repayment: overRepayment,
          tx: txOverRepay,
        );
      } catch (e) {
        overRepayRejected = true;
        debugPrint('Over-repayment correctly rejected with: $e');
      }

      final lDocAfterOver = await firebaseService.loans(testGroupId).doc(loan1Id).get();
      final lDataAfterOver = lDocAfterOver.data() as Map<String, dynamic>;
      final pendingAfterOver = (lDataAfterOver['pendingPrincipal'] as num).toDouble();

      final isOverRepayHandled = overRepayRejected && pendingAfterOver == 15000.0;
      results['over_repayment_rejected'] = isOverRepayHandled;
      debugPrint(isOverRepayHandled
          ? 'TEST 5 PASSED: Over-repayment rejected. Pending principal strictly remains ₹15,000'
          : 'TEST 5 FAILED: Over-repayment was allowed');

      // -----------------------------------------------------------------
      // TEST 6: Soft Deactivate Member & Check History Preservation
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 6: MEMBER DEACTIVATION & HISTORY PRESERVATION ---');
      await groupRepo.deactivateMember(testGroupId, memberAId);
      final mDeactivated = await firebaseService.members(testGroupId).doc(memberAId).get();
      final isSoftDeactivated = mDeactivated.exists &&
          (mDeactivated.data() as Map<String, dynamic>)['status'] == MemberStatus.inactive.name;

      final historyLoans = await firebaseService.loans(testGroupId).where('memberId', isEqualTo: memberAId).get();
      final historyRepayments = await firebaseService.loanRepayments(testGroupId).where('memberId', isEqualTo: memberAId).get();

      final isHistoryPreserved = isSoftDeactivated && historyLoans.docs.isNotEmpty && historyRepayments.docs.isNotEmpty;
      results['member_deactivate_and_history_preserved'] = isHistoryPreserved;
      debugPrint(isHistoryPreserved
          ? 'TEST 6 PASSED: Member soft-deactivated. All historical loan and repayment records preserved.'
          : 'TEST 6 FAILED: Historical records missing after deactivation');

      // -----------------------------------------------------------------
      // TEST 7: Dashboard Calculation Scenario
      // Initial: ₹30,500 available -> Loan ₹3,000 (+₹3000 loan, ₹3000 active, ₹27,500 available)
      // -> Repay ₹1,000 (Outstanding ₹2,000, Active ₹2,000)
      // -> Over-Repay ₹3,000 (REJECTED, Outstanding remains ₹2,000)
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 7: DASHBOARD LOAN SCENARIO (₹3,000 LOAN, ₹1,000 REPAY) ---');
      final loanScenarioId = 'L_SCENARIO_$testTimestamp';
      final loanScenario = Loan(
        id: loanScenarioId,
        groupId: testGroupId,
        memberId: memberBId,
        originalPrincipal: 3000.0,
        pendingPrincipal: 3000.0,
        interestRate: 2.0,
        loanDate: DateTime.now(),
        purpose: 'Small Business',
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txScenario = AppTransaction(
        id: 'T_${testTimestamp}_scenario',
        memberId: memberBId,
        memberName: 'Member B',
        type: TransactionType.loanIssue,
        amount: 3000.0,
        date: DateTime.now(),
        description: 'Loan Issued: ₹3,000',
        referenceId: loanScenarioId,
      );

      await txRepo.issueLoan(testGroupId, loanScenario, txScenario);

      final lDocScenario = await firebaseService.loans(testGroupId).doc(loanScenarioId).get();
      final lDataScenario = lDocScenario.data() as Map<String, dynamic>;
      final isPositivePrincipal = (lDataScenario['originalPrincipal'] as num) == 3000.0 &&
          (lDataScenario['pendingPrincipal'] as num) == 3000.0;

      // Partial Repayment ₹1,000
      final repayScenarioId = 'R_SCENARIO_$testTimestamp';
      final repayScenario = LoanRepayment(
        id: repayScenarioId,
        loanId: loanScenarioId,
        groupId: testGroupId,
        memberId: memberBId,
        month: 10,
        year: 2026,
        openingPrincipal: 3000.0,
        interestRate: 2.0,
        interestAmount: 60.0,
        regularContribution: 0.0,
        principalRepaid: 1000.0,
        totalPaid: 1060.0,
        closingPrincipal: 2000.0,
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txRepayScenario = AppTransaction(
        id: 'T_${testTimestamp}_repayScenario',
        memberId: memberBId,
        memberName: 'Member B',
        type: TransactionType.loanRepayment,
        amount: 1060.0,
        date: DateTime.now(),
        description: 'Repayment (Principal: ₹1,000, Interest: ₹60)',
        referenceId: repayScenarioId,
      );

      await txRepo.recordLoanRepayment(
        groupId: testGroupId,
        loan: loanScenario,
        repayment: repayScenario,
        tx: txRepayScenario,
      );

      final lDocScenario2 = await firebaseService.loans(testGroupId).doc(loanScenarioId).get();
      final lDataScenario2 = lDocScenario2.data() as Map<String, dynamic>;
      final pendingScenario = (lDataScenario2['pendingPrincipal'] as num).toDouble();

      final isScenarioValid = isPositivePrincipal && pendingScenario == 2000.0;
      results['dashboard_loan_scenario_3000_1000'] = isScenarioValid;
      debugPrint(isScenarioValid
          ? 'TEST 7 PASSED: ₹3,000 loan stored as positive, repaid ₹1,000 -> Outstanding = ₹2,000'
          : 'TEST 7 FAILED: Pending principal is ₹$pendingScenario');

      // -----------------------------------------------------------------
      // TEST 8: Requirement 28 Lifecycle Test
      // 1 share = ₹1,000/mo, Loan = ₹10,000 @ 2%
      // Month 1: Interest = ₹200, Repay = ₹5,000 -> Total Due = ₹6,200
      // Pay ₹6,200 -> Savings +₹1,000, Interest +₹200, Loan Principal -₹5,000 -> Outstanding = ₹5,000
      // Month 2: Interest = ₹5,000 * 2% = ₹100 -> If ₹0 principal, Total Due = ₹1,100
      // If unpaid -> Overdue / Pending = ₹1,100
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 8: REQUIREMENT 28 LIFECYCLE (1 SHARE, 10K LOAN, 5K REPAY, M2 100 INT) ---');
      final memberCId = 'M_C_$testTimestamp';
      final memberC = Member(
        id: memberCId,
        groupId: testGroupId,
        name: 'Member C (Req 28)',
        phone: '9888888883',
        joinDate: DateTime(2026, 8, 1),
        shares: 1,
        monthlyContributionPerShare: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await groupRepo.addMember(memberC);

      final loan10kId = 'L_10K_$testTimestamp';
      final loan10k = Loan(
        id: loan10kId,
        groupId: testGroupId,
        memberId: memberCId,
        originalPrincipal: 10000.0,
        pendingPrincipal: 10000.0,
        interestRate: 2.0,
        loanDate: DateTime(2026, 8, 1),
        purpose: 'Agriculture',
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txLoan10k = AppTransaction(
        id: 'T_10K_$testTimestamp',
        memberId: memberCId,
        memberName: 'Member C',
        type: TransactionType.loanIssue,
        amount: 10000.0,
        date: DateTime(2026, 8, 1),
        description: 'Loan Issued: ₹10,000',
        referenceId: loan10kId,
      );

      await txRepo.issueLoan(testGroupId, loan10k, txLoan10k);

      // Month 1 calculations
      final m1Regular = memberC.monthlyContribution; // 1,000
      final m1Interest = CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: 10000.0, annualRate: 2.0); // 200
      const m1PrincipalRepay = 5000.0;
      final m1TotalDue = m1Regular + m1Interest + m1PrincipalRepay; // 6,200

      // Record Month 1 full payment of ₹6,200
      final repay10kId = 'R_10K_$testTimestamp';
      final repay10k = LoanRepayment(
        id: repay10kId,
        loanId: loan10kId,
        groupId: testGroupId,
        memberId: memberCId,
        month: 8,
        year: 2026,
        openingPrincipal: 10000.0,
        interestRate: 2.0,
        interestAmount: m1Interest,
        regularContribution: m1Regular,
        principalRepaid: m1PrincipalRepay,
        totalPaid: m1TotalDue,
        closingPrincipal: 5000.0,
        paymentDate: DateTime(2026, 8, 10),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txRepay10k = AppTransaction(
        id: 'T_REPAY_10K_$testTimestamp',
        memberId: memberCId,
        memberName: 'Member C',
        type: TransactionType.loanRepayment,
        amount: m1TotalDue,
        date: DateTime(2026, 8, 10),
        description: 'Month 1 Full Payment: Hafta ₹1,000 + Interest ₹200 + Principal ₹5,000 = ₹6,200',
        referenceId: repay10kId,
      );

      await txRepo.recordLoanRepayment(
        groupId: testGroupId,
        loan: loan10k,
        repayment: repay10k,
        tx: txRepay10k,
      );

      // Verify closing outstanding is strictly ₹5,000
      final lDocAfterM1 = await firebaseService.loans.doc(loan10kId).get();
      final lDataAfterM1 = lDocAfterM1.data() as Map<String, dynamic>;
      final closingM1 = (lDataAfterM1['pendingPrincipal'] as num).toDouble();

      // Month 2 calculations on reducing outstanding principal ₹5,000
      final m2Interest = CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: closingM1, annualRate: 2.0); // 100
      const m2PrincipalRepay = 0.0;
      final m2TotalDue = memberC.monthlyContribution + m2Interest + m2PrincipalRepay; // 1,100

      final isReq28Valid = m1TotalDue == 6200.0 &&
          closingM1 == 5000.0 &&
          m2Interest == 100.0 &&
          m2TotalDue == 1100.0;

      results['requirement_28_lifecycle'] = isReq28Valid;
      debugPrint(isReq28Valid
          ? 'TEST 8 PASSED: Month 1 Due = ₹6,200 -> Closing = ₹5,000 -> Month 2 Interest = ₹100 -> Month 2 Due = ₹1,100'
          : 'TEST 8 FAILED: M1=$m1TotalDue, Closing=$closingM1, M2Int=$m2Interest, M2Due=$m2TotalDue');

      // -----------------------------------------------------------------
      // TEST 9: Requirement 29 Multiple Shares + Loan Due Test
      // Member: 3 shares = ₹3,000/mo, Loan = ₹10,000, Interest = ₹200
      // With ₹5,000 principal: Due = ₹3,000 + ₹200 + ₹5,000 = ₹8,200
      // If principal skipped: Due = ₹3,000 + ₹200 = ₹3,200
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 9: REQUIREMENT 29 (3 SHARES + 10K LOAN -> 8,200 / 3,200 DUE) ---');
      final memberDId = 'M_D_$testTimestamp';
      final memberD = Member(
        id: memberDId,
        groupId: testGroupId,
        name: 'Member D (3 Shares Req 29)',
        phone: '9888888884',
        joinDate: DateTime(2026, 8, 1),
        shares: 3,
        monthlyContributionPerShare: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await groupRepo.addMember(memberD);

      const req29Outstanding = 10000.0;
      final req29Regular = memberD.monthlyContribution; // 3,000
      final req29Interest = CalculationUtils.calculateMonthlyInterest(outstandingPrincipal: req29Outstanding, annualRate: 2.0); // 200
      const req29PrincipalRepay = 5000.0;

      final req29DueWithPrincipal = req29Regular + req29Interest + req29PrincipalRepay; // 8,200
      final req29DueSkippedPrincipal = req29Regular + req29Interest; // 3,200

      final isReq29Valid = req29Regular == 3000.0 &&
          req29Interest == 200.0 &&
          req29DueWithPrincipal == 8200.0 &&
          req29DueSkippedPrincipal == 3200.0;

      results['requirement_29_multi_share_due'] = isReq29Valid;
      debugPrint(isReq29Valid
          ? 'TEST 9 PASSED: 3 Shares = ₹3,000 -> Total with ₹5,000 principal = ₹8,200, Skipped = ₹3,200'
          : 'TEST 9 FAILED: WithPrincipal=$req29DueWithPrincipal, Skipped=$req29DueSkippedPrincipal');

      debugPrint('\n=====================================================');
      debugPrint('ALL BUSINESS FLOW & FIRESTORE TESTS COMPLETED');
      debugPrint('=====================================================\n');

    } catch (e, stack) {
      debugPrint('ERROR IN BUSINESS FLOW TEST: $e\n$stack');
    }

    return results;
  }
}
