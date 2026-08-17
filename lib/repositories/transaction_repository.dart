import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final FirebaseService _firebaseService;

  TransactionRepository(this._firebaseService);

  Stream<List<MonthlyContribution>> watchContributions(String groupId, {String? memberId}) {
    Query query = _firebaseService.monthlyContributions(groupId);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MonthlyContribution.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<Loan>> watchLoans(String groupId, {String? memberId}) {
    Query query = _firebaseService.loans(groupId);
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Loan.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<LoanRepayment>> watchRepayments(String groupId, {String? loanId, String? memberId}) {
    Query query = _firebaseService.loanRepayments(groupId);
    if (loanId != null) {
      query = query.where('loanId', isEqualTo: loanId);
    }
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LoanRepayment.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Stream<List<AppTransaction>> watchRecentActivities(String groupId, {int limit = 20}) {
    return _firebaseService.activities(groupId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppTransaction.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> recordContribution(
    String groupId,
    MonthlyContribution contribution,
    AppTransaction tx, {
    Loan? loan,
    LoanRepayment? repayment,
  }) async {
    await _firebaseService.firestore.runTransaction((transaction) async {
      // 1. Record Monthly Contribution
      final contributionRef = _firebaseService.monthlyContributions(groupId).doc(contribution.id);
      transaction.set(contributionRef, contribution.toJson());

      // 2. Record Loan Repayment if applicable
      if (loan != null && repayment != null) {
        final repaymentRef = _firebaseService.loanRepayments(groupId).doc(repayment.id);
        transaction.set(repaymentRef, repayment.toJson());

        final loanRef = _firebaseService.loans(groupId).doc(loan.id);
        final newPending = loan.pendingPrincipal - repayment.principalRepaid;
        transaction.update(loanRef, {
          'pendingPrincipal': newPending > 0 ? newPending : 0.0,
          'status': newPending <= 0 ? LoanStatus.closed.name : LoanStatus.active.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      // 3. Record Activity
      final activityRef = _firebaseService.activities(groupId).doc(tx.id);
      transaction.set(activityRef, tx.toJson());

      // 4. Update Group totals
      final groupRef = _firebaseService.groups.doc(groupId);
      final updates = <String, dynamic>{
        'totalFund': FieldValue.increment(tx.amount),
        'totalSavings': FieldValue.increment(contribution.regularHaftaAmount),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (repayment != null) {
        updates['totalOutstandingLoans'] = FieldValue.increment(-repayment.principalRepaid);
        updates['totalInterestCollected'] = FieldValue.increment(repayment.interestAmount);
      }

      transaction.update(groupRef, updates);
    });
  }

  Future<void> issueLoan(String groupId, Loan loan, AppTransaction tx) async {
    await _firebaseService.firestore.runTransaction((transaction) async {
      transaction.set(_firebaseService.loans(groupId).doc(loan.id), loan.toJson());
      transaction.set(_firebaseService.activities(groupId).doc(tx.id), tx.toJson());
      
      // Update group totals
      final groupRef = _firebaseService.groups.doc(groupId);
      transaction.update(groupRef, {
        'totalFund': FieldValue.increment(-tx.amount), // Loan reduces available fund
        'totalOutstandingLoans': FieldValue.increment(tx.amount),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> recordLoanRepayment({
    required String groupId,
    required Loan loan,
    required LoanRepayment repayment,
    required AppTransaction tx,
    MonthlyContribution? contribution,
  }) async {
    await _firebaseService.firestore.runTransaction((transaction) async {
      // 1. Record the repayment event
      transaction.set(_firebaseService.loanRepayments(groupId).doc(repayment.id), repayment.toJson());

      // 2. Record monthly contribution if provided
      if (contribution != null) {
        transaction.set(_firebaseService.monthlyContributions(groupId).doc(contribution.id), contribution.toJson());
      }
      
      // 3. Record the activity
      transaction.set(_firebaseService.activities(groupId).doc(tx.id), tx.toJson());
      
      // 4. Update Loan pending balance
      final loanRef = _firebaseService.loans(groupId).doc(loan.id);
      final newPending = loan.pendingPrincipal - repayment.principalRepaid;
      transaction.update(loanRef, {
        'pendingPrincipal': newPending > 0 ? newPending : 0.0,
        'status': newPending <= 0 ? LoanStatus.closed.name : LoanStatus.active.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 5. Update Group totals
      final groupRef = _firebaseService.groups.doc(groupId);
      final updates = <String, dynamic>{
        'totalFund': FieldValue.increment(tx.amount),
        'totalOutstandingLoans': FieldValue.increment(-repayment.principalRepaid),
        'totalInterestCollected': FieldValue.increment(repayment.interestAmount),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (repayment.regularContribution > 0) {
        updates['totalSavings'] = FieldValue.increment(repayment.regularContribution);
      }
      transaction.update(groupRef, updates);
    });
  }
}
