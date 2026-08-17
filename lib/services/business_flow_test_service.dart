import 'package:flutter/foundation.dart';
import '../models/member.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/monthly_contribution.dart';
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
    const groupId = 'shivshahi_group_001';

    debugPrint('=====================================================');
    debugPrint('STARTING REAL FIRESTORE BUSINESS DATA FLOW TEST');
    debugPrint('=====================================================');

    try {
      // 0. Ensure Group Exists
      await groupRepo.ensureGroupExists(groupId);
      final groupDoc = await firebaseService.groups.doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group $groupId document was not found or created.');
      }
      debugPrint('STEP 0: Group document verified: ${groupDoc.id}');

      final testTimestamp = DateTime.now().millisecondsSinceEpoch;
      final testMemberId = 'M_test_$testTimestamp';

      // -----------------------------------------------------------------
      // TEST 1: Create / Add Member
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 1: CREATE/ADD MEMBER ---');
      final member1 = Member(
        id: testMemberId,
        groupId: groupId,
        name: 'Firebase Test Member',
        phone: '9999999999',
        joinDate: DateTime(2026, 8, 1),
        monthlyContribution: 1000.0,
        status: MemberStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await groupRepo.addMember(member1);

      // Verify in Firestore
      final mDoc = await firebaseService.members(groupId).doc(testMemberId).get();
      if (mDoc.exists &&
          mDoc.data() != null &&
          (mDoc.data() as Map<String, dynamic>)['name'] == 'Firebase Test Member' &&
          (mDoc.data() as Map<String, dynamic>)['monthlyContribution'] == 1000.0) {
        results['member_create'] = true;
        debugPrint('TEST 1 PASSED: Member created in Firestore: $testMemberId');
      } else {
        results['member_create'] = false;
        debugPrint('TEST 1 FAILED: Member doc not matching in Firestore');
      }

      // -----------------------------------------------------------------
      // TEST 2: Edit member's monthly hafta (1000 -> 1500)
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 2: EDIT MEMBER MONTHLY HAFTA ---');
      final updatedMember = member1.copyWith(
        monthlyContribution: 1500.0,
        updatedAt: DateTime.now(),
      );

      await groupRepo.updateMember(updatedMember);

      final mDocUpdated = await firebaseService.members(groupId).doc(testMemberId).get();
      if (mDocUpdated.exists &&
          (mDocUpdated.data() as Map<String, dynamic>)['monthlyContribution'] == 1500.0) {
        results['member_update'] = true;
        debugPrint('TEST 2 PASSED: Member monthly hafta updated to 1500 in Firestore');
      } else {
        results['member_update'] = false;
        debugPrint('TEST 2 FAILED: Member update not reflected');
      }

      // -----------------------------------------------------------------
      // TEST 3: Record monthly contribution (August 2026)
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 3: RECORD MONTHLY CONTRIBUTION ---');
      final contribId1 = 'C_${testTimestamp}_aug';
      final contrib1 = MonthlyContribution(
        id: contribId1,
        memberId: testMemberId,
        groupId: groupId,
        month: 8,
        year: 2026,
        regularHaftaAmount: 1500.0,
        interestAmount: 0.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 1500.0,
        expectedAmount: 1500.0,
        paidAmount: 1500.0,
        status: ContributionStatus.paid,
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tx1 = AppTransaction(
        id: 'T_${testTimestamp}_aug',
        memberId: testMemberId,
        memberName: 'Firebase Test Member',
        type: TransactionType.monthlyInvestment,
        amount: 1500.0,
        date: DateTime.now(),
        description: 'Monthly Contribution - August 2026',
        referenceId: contribId1,
      );

      await txRepo.recordContribution(groupId, contrib1, tx1);

      final cDoc = await firebaseService.monthlyContributions(groupId).doc(contribId1).get();
      if (cDoc.exists &&
          (cDoc.data() as Map<String, dynamic>)['month'] == 8 &&
          (cDoc.data() as Map<String, dynamic>)['year'] == 2026 &&
          (cDoc.data() as Map<String, dynamic>)['regularHaftaAmount'] == 1500.0) {
        results['monthly_contribution_write'] = true;
        debugPrint('TEST 3 PASSED: Monthly contribution recorded in monthly_contributions');
      } else {
        results['monthly_contribution_write'] = false;
        debugPrint('TEST 3 FAILED: Monthly contribution doc missing or incorrect');
      }

      // -----------------------------------------------------------------
      // TEST 4: Issue 10,000 Loan @ 2%
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 4: ISSUE 10,000 LOAN @ 2% ---');
      final loanId = 'L_$testTimestamp';
      final loan = Loan(
        id: loanId,
        groupId: groupId,
        memberId: testMemberId,
        originalPrincipal: 10000.0,
        pendingPrincipal: 10000.0,
        interestRate: 2.0,
        loanDate: DateTime.now(),
        purpose: 'Business Investment',
        status: LoanStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final txLoan = AppTransaction(
        id: 'T_${testTimestamp}_loan',
        memberId: testMemberId,
        memberName: 'Firebase Test Member',
        type: TransactionType.loanIssue,
        amount: 10000.0,
        date: DateTime.now(),
        description: 'Loan Issued: 10000',
        referenceId: loanId,
      );

      await txRepo.issueLoan(groupId, loan, txLoan);

      final loanDoc = await firebaseService.loans(groupId).doc(loanId).get();
      if (loanDoc.exists &&
          (loanDoc.data() as Map<String, dynamic>)['originalPrincipal'] == 10000.0 &&
          (loanDoc.data() as Map<String, dynamic>)['pendingPrincipal'] == 10000.0 &&
          (loanDoc.data() as Map<String, dynamic>)['interestRate'] == 2.0) {
        results['loan_create'] = true;
        debugPrint('TEST 4 PASSED: Loan created: originalPrincipal=10000, pendingPrincipal=10000, interestRate=2');
      } else {
        results['loan_create'] = false;
        debugPrint('TEST 4 FAILED: Loan doc missing or incorrect in Firestore');
      }

      // -----------------------------------------------------------------
      // TEST 5: Record Payment: ONLY regular hafta + interest (Principal = 0)
      // Regular = 1000, Interest = 200 (2% of 10000), Principal = 0, Total = 1200
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 5: PAYMENT: REGULAR (1000) + INTEREST (200) + PRINCIPAL (0) = 1200 ---');
      final interest5 = CalculationUtils.calculateMonthlyInterest(
        outstandingPrincipal: 10000.0,
        annualRate: 2.0,
      ); // 200.0
      
      final repaymentId1 = 'R_${testTimestamp}_sep';
      final contribId2 = 'C_${testTimestamp}_sep';
      final now5 = DateTime.now();

      final repayment1 = LoanRepayment(
        id: repaymentId1,
        loanId: loanId,
        groupId: groupId,
        memberId: testMemberId,
        month: 9,
        year: 2026,
        openingPrincipal: 10000.0,
        interestRate: 2.0,
        interestAmount: interest5,
        regularContribution: 1000.0,
        principalRepaid: 0.0,
        totalPaid: 1200.0,
        closingPrincipal: 10000.0,
        paymentDate: now5,
        createdAt: now5,
        updatedAt: now5,
      );

      final contrib2 = MonthlyContribution(
        id: contribId2,
        memberId: testMemberId,
        groupId: groupId,
        month: 9,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 200.0,
        loanPrincipalPaid: 0.0,
        totalPaid: 1200.0,
        expectedAmount: 1000.0,
        paidAmount: 1200.0,
        status: ContributionStatus.paid,
        paymentDate: now5,
        createdAt: now5,
        updatedAt: now5,
      );

      final tx5 = AppTransaction(
        id: 'T_${testTimestamp}_sep',
        memberId: testMemberId,
        memberName: 'Firebase Test Member',
        type: TransactionType.loanRepayment,
        amount: 1200.0,
        date: now5,
        description: 'September 2026 Repayment (H: 1000, I: 200, P: 0)',
        referenceId: repaymentId1,
      );

      await txRepo.recordContribution(
        groupId,
        contrib2,
        tx5,
        loan: loan,
        repayment: repayment1,
      );

      final loanDoc5 = await firebaseService.loans(groupId).doc(loanId).get();
      final rDoc1 = await firebaseService.loanRepayments(groupId).doc(repaymentId1).get();

      final pendingAfter5 = (loanDoc5.data() as Map<String, dynamic>)['pendingPrincipal'];
      final originalAfter5 = (loanDoc5.data() as Map<String, dynamic>)['originalPrincipal'];

      if (pendingAfter5 == 10000.0 &&
          originalAfter5 == 10000.0 &&
          rDoc1.exists &&
          (rDoc1.data() as Map<String, dynamic>)['interestAmount'] == 200.0 &&
          (rDoc1.data() as Map<String, dynamic>)['principalRepaid'] == 0.0) {
        results['interest_calculation'] = true;
        results['pending_loan_calculation_test5'] = true;
        debugPrint('TEST 5 PASSED: pendingPrincipal remains 10,000, interest stored separately (200)');
      } else {
        results['interest_calculation'] = false;
        results['pending_loan_calculation_test5'] = false;
        debugPrint('TEST 5 FAILED: loan pendingPrincipal changed or interest not stored properly');
      }

      // -----------------------------------------------------------------
      // TEST 6: Record Repayment: Regular=1000, Interest=200, Principal=5000, Total=6200
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 6: REPAYMENT: REGULAR (1000) + INTEREST (200) + PRINCIPAL (5000) = 6200 ---');
      final repaymentId2 = 'R_${testTimestamp}_oct';
      final contribId3 = 'C_${testTimestamp}_oct';
      final now6 = DateTime.now();

      final currentLoanDoc = await firebaseService.loans(groupId).doc(loanId).get();
      final currentLoan = Loan.fromJson(currentLoanDoc.data() as Map<String, dynamic>);

      final repayment2 = LoanRepayment(
        id: repaymentId2,
        loanId: loanId,
        groupId: groupId,
        memberId: testMemberId,
        month: 10,
        year: 2026,
        openingPrincipal: currentLoan.pendingPrincipal,
        interestRate: 2.0,
        interestAmount: 200.0,
        regularContribution: 1000.0,
        principalRepaid: 5000.0,
        totalPaid: 6200.0,
        closingPrincipal: currentLoan.pendingPrincipal - 5000.0, // 5000.0
        paymentDate: now6,
        createdAt: now6,
        updatedAt: now6,
      );

      final contrib3 = MonthlyContribution(
        id: contribId3,
        memberId: testMemberId,
        groupId: groupId,
        month: 10,
        year: 2026,
        regularHaftaAmount: 1000.0,
        interestAmount: 200.0,
        loanPrincipalPaid: 5000.0,
        totalPaid: 6200.0,
        expectedAmount: 1000.0,
        paidAmount: 6200.0,
        status: ContributionStatus.paid,
        paymentDate: now6,
        createdAt: now6,
        updatedAt: now6,
      );

      final tx6 = AppTransaction(
        id: 'T_${testTimestamp}_oct',
        memberId: testMemberId,
        memberName: 'Firebase Test Member',
        type: TransactionType.loanRepayment,
        amount: 6200.0,
        date: now6,
        description: 'October 2026 Repayment (H: 1000, I: 200, P: 5000)',
        referenceId: repaymentId2,
      );

      await txRepo.recordContribution(
        groupId,
        contrib3,
        tx6,
        loan: currentLoan,
        repayment: repayment2,
      );

      final loanDoc6 = await firebaseService.loans(groupId).doc(loanId).get();
      final rDoc2 = await firebaseService.loanRepayments(groupId).doc(repaymentId2).get();

      final pendingAfter6 = (loanDoc6.data() as Map<String, dynamic>)['pendingPrincipal'];
      final originalAfter6 = (loanDoc6.data() as Map<String, dynamic>)['originalPrincipal'];

      if (pendingAfter6 == 5000.0 &&
          originalAfter6 == 10000.0 &&
          rDoc2.exists &&
          (rDoc2.data() as Map<String, dynamic>)['principalRepaid'] == 5000.0) {
        results['loan_repayment_write'] = true;
        results['pending_loan_calculation'] = true;
        debugPrint('TEST 6 PASSED: originalPrincipal=10000, pendingPrincipal=5000, repayment recorded');
      } else {
        results['loan_repayment_write'] = false;
        results['pending_loan_calculation'] = false;
        debugPrint('TEST 6 FAILED: Loan calculation or repayment record incorrect');
      }

      // -----------------------------------------------------------------
      // TEST 7: Verify previous records were NOT overwritten
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 7: VERIFY NON-OVERWRITING REPAYMENT / CONTRIBUTION HISTORY ---');
      final allContribs = await firebaseService.monthlyContributions(groupId)
          .where('memberId', isEqualTo: testMemberId)
          .get();

      final allRepayments = await firebaseService.loanRepayments(groupId)
          .where('loanId', isEqualTo: loanId)
          .get();

      if (allContribs.docs.length >= 3 && allRepayments.docs.length >= 2) {
        results['repayment_history'] = true;
        debugPrint('TEST 7 PASSED: Contributions count=${allContribs.docs.length}, Repayments count=${allRepayments.docs.length}. No overwrites!');
      } else {
        results['repayment_history'] = false;
        debugPrint('TEST 7 FAILED: Missing previous records in history');
      }

      // -----------------------------------------------------------------
      // TEST 8: Verify all 5 Firestore sub-collections + groups doc
      // -----------------------------------------------------------------
      debugPrint('\n--- TEST 8: VERIFY ALL FIRESTORE COLLECTIONS EXIST AND VALID ---');
      final membersSnap = await firebaseService.members(groupId).get();
      final contribsSnap = await firebaseService.monthlyContributions(groupId).get();
      final loansSnap = await firebaseService.loans(groupId).get();
      final repaymentsSnap = await firebaseService.loanRepayments(groupId).get();
      final activitiesSnap = await firebaseService.activities(groupId).get();

      debugPrint('   📁 groups: 1 ($groupId)');
      debugPrint('   📁 members: ${membersSnap.docs.length} docs');
      debugPrint('   📁 monthly_contributions: ${contribsSnap.docs.length} docs');
      debugPrint('   📁 loans: ${loansSnap.docs.length} docs');
      debugPrint('   📁 loan_repayments: ${repaymentsSnap.docs.length} docs');
      debugPrint('   📁 activities: ${activitiesSnap.docs.length} docs');

      if (membersSnap.docs.isNotEmpty &&
          contribsSnap.docs.isNotEmpty &&
          loansSnap.docs.isNotEmpty &&
          repaymentsSnap.docs.isNotEmpty &&
          activitiesSnap.docs.isNotEmpty) {
        results['collections_verified'] = true;
        debugPrint('TEST 8 PASSED: All 5 Firestore sub-collections exist and contain live documents');
      } else {
        results['collections_verified'] = false;
        debugPrint('TEST 8 FAILED: Some collections are empty');
      }

      // -----------------------------------------------------------------
      // Member Deactivate Test
      // -----------------------------------------------------------------
      debugPrint('\n--- MEMBER DEACTIVATE TEST ---');
      await groupRepo.deactivateMember(groupId, testMemberId);
      final mDeactivated = await firebaseService.members(groupId).doc(testMemberId).get();
      if (mDeactivated.exists &&
          (mDeactivated.data() as Map<String, dynamic>)['status'] == MemberStatus.inactive.name) {
        results['member_deactivate'] = true;
        debugPrint('MEMBER DEACTIVATE PASSED: Member status is now inactive in Firestore');
      } else {
        results['member_deactivate'] = false;
        debugPrint('MEMBER DEACTIVATE FAILED');
      }

      debugPrint('\n=====================================================');
      debugPrint('ALL REAL FIRESTORE BUSINESS FLOW TESTS COMPLETED');
      debugPrint('=====================================================\n');

    } catch (e, stack) {
      debugPrint('ERROR IN BUSINESS FLOW TEST: $e\n$stack');
    }

    return results;
  }
}
