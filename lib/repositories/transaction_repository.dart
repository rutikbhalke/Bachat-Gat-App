import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/transaction.dart';
import '../core/utils/perf_logger.dart';
import '../core/utils/calculation_utils.dart';

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

  Future<List<MonthlyContribution>> getContributions(String groupId, {String? memberId, int? month, int? year}) async {
    return PerfLogger.traceAsync('getContributions($groupId, memberId=$memberId, $month/$year)', () async {
      Query query = _firebaseService.monthlyContributions(groupId);
      if (memberId != null) {
        query = query.where('memberId', isEqualTo: memberId);
      }
      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      final snapshot = await query.get();
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

  Future<List<Loan>> getLoans(String groupId, {String? memberId, LoanStatus? status}) async {
    return PerfLogger.traceAsync('getLoans($groupId, memberId=$memberId, status=$status)', () async {
      Query query = _firebaseService.loans(groupId);
      if (memberId != null) {
        query = query.where('memberId', isEqualTo: memberId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      final snapshot = await query.get();
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

  Future<List<LoanRepayment>> getRepayments(String groupId, {String? loanId, String? memberId, int? month, int? year}) async {
    return PerfLogger.traceAsync('getRepayments($groupId, loanId=$loanId, memberId=$memberId, $month/$year)', () async {
      Query query = _firebaseService.loanRepayments(groupId);
      if (loanId != null) {
        query = query.where('loanId', isEqualTo: loanId);
      }
      if (memberId != null) {
        query = query.where('memberId', isEqualTo: memberId);
      }
      if (month != null) {
        query = query.where('month', isEqualTo: month);
      }
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      final snapshot = await query.get();
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

  Future<List<AppTransaction>> getMemberTransactions(String groupId, String memberId) async {
    return PerfLogger.traceAsync('getMemberTransactions($groupId, $memberId)', () async {
      final snapshot = await _firebaseService.activities(groupId)
          .where('memberId', isEqualTo: memberId)
          .get();
      final list = snapshot.docs.map((doc) => AppTransaction.fromJson(doc.data() as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }

  Future<void> recordContribution(
    String groupId,
    MonthlyContribution contribution,
    AppTransaction tx, {
    Loan? loan,
    LoanRepayment? repayment,
  }) async {
    return PerfLogger.traceAsync('recordContribution(${contribution.id})', () async {
      // 1. Prevent duplicate collection for same member, month, year
      final existingContribs = await _firebaseService.monthlyContributions(groupId)
          .where('memberId', isEqualTo: contribution.memberId)
          .where('month', isEqualTo: contribution.month)
          .where('year', isEqualTo: contribution.year)
          .get();

      if (existingContribs.docs.isNotEmpty && existingContribs.docs.first.id != contribution.id) {
        throw Exception('A contribution for member ${contribution.memberId} for ${contribution.month}/${contribution.year} already exists.');
      }

      if (loan != null && repayment != null) {
        final existingRepayments = await _firebaseService.loanRepayments(groupId)
            .where('loanId', isEqualTo: loan.id)
            .where('month', isEqualTo: repayment.month)
            .where('year', isEqualTo: repayment.year)
            .get();

        if (existingRepayments.docs.isNotEmpty && existingRepayments.docs.first.id != repayment.id) {
          throw Exception('A loan repayment for loan ${loan.id} for ${repayment.month}/${repayment.year} already exists.');
        }
      }

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
    });
  }

  Future<void> issueLoan(String groupId, Loan loan, AppTransaction tx) async {
    return PerfLogger.traceAsync('issueLoan(${loan.id})', () async {
      await _firebaseService.firestore.runTransaction((transaction) async {
        final groupRef = _firebaseService.groups.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group $groupId does not exist.');
        }

        final groupData = groupDoc.data() as Map<String, dynamic>;
        final totalSavings = (groupData['totalSavings'] as num?)?.toDouble() ?? 0.0;
        final totalOutstandingLoans = (groupData['totalOutstandingLoans'] as num?)?.toDouble() ?? 0.0;
        final availableFund = CalculationUtils.calculateAvailableFund(
          totalSavings: totalSavings,
          outstandingLoans: totalOutstandingLoans,
        );

        if (loan.originalPrincipal <= 0) {
          throw Exception('Loan amount must be greater than zero.');
        }

        if (loan.originalPrincipal > availableFund) {
          if (availableFund <= 0) {
            throw Exception('No available group fund for a new loan.');
          }
          throw Exception(
            'Available group fund is ${CalculationUtils.formatCurrency(availableFund)}. Maximum loan amount allowed is ${CalculationUtils.formatCurrency(availableFund)}.',
          );
        }

        transaction.set(_firebaseService.loans(groupId).doc(loan.id), loan.toJson());
        transaction.set(_firebaseService.activities(groupId).doc(tx.id), tx.toJson());
        
        // Update group totals
        transaction.update(groupRef, {
          'totalFund': FieldValue.increment(-tx.amount), // Loan reduces available fund
          'totalOutstandingLoans': FieldValue.increment(tx.amount),
          'updatedAt': DateTime.now().toIso8601String(),
        });
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
    return PerfLogger.traceAsync('recordLoanRepayment(${loan.id})', () async {
      final existingRepayments = await _firebaseService.loanRepayments(groupId)
          .where('loanId', isEqualTo: loan.id)
          .where('month', isEqualTo: repayment.month)
          .where('year', isEqualTo: repayment.year)
          .get();

      if (existingRepayments.docs.isNotEmpty && existingRepayments.docs.first.id != repayment.id) {
        throw Exception('A repayment for loan ${loan.id} for ${repayment.month}/${repayment.year} already exists.');
      }

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
    });
  }

  Future<void> reverseContribution({
    required String groupId,
    required String contributionId,
    String? repaymentId,
    String? loanId,
  }) async {
    return PerfLogger.traceAsync('reverseContribution($contributionId)', () async {
      await _firebaseService.firestore.runTransaction((transaction) async {
        final contribRef = _firebaseService.monthlyContributions(groupId).doc(contributionId);
        final contribDoc = await transaction.get(contribRef);
        if (!contribDoc.exists) return;

        final contrib = MonthlyContribution.fromJson(contribDoc.data() as Map<String, dynamic>);
        transaction.delete(contribRef);

        double principalToRestore = 0.0;
        double interestToRemove = 0.0;

        if (repaymentId != null && loanId != null) {
          final repaymentRef = _firebaseService.loanRepayments(groupId).doc(repaymentId);
          final repaymentDoc = await transaction.get(repaymentRef);
          if (repaymentDoc.exists) {
            final repayment = LoanRepayment.fromJson(repaymentDoc.data() as Map<String, dynamic>);
            principalToRestore = repayment.principalRepaid;
            interestToRemove = repayment.interestAmount;
            transaction.delete(repaymentRef);

            final loanRef = _firebaseService.loans(groupId).doc(loanId);
            final loanDoc = await transaction.get(loanRef);
            if (loanDoc.exists) {
              final loan = Loan.fromJson(loanDoc.data() as Map<String, dynamic>);
              final restoredPending = loan.pendingPrincipal + principalToRestore;
              transaction.update(loanRef, {
                'pendingPrincipal': restoredPending,
                'status': restoredPending > 0 ? LoanStatus.active.name : LoanStatus.closed.name,
                'updatedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // Group totals reversal
        final groupRef = _firebaseService.groups.doc(groupId);
        transaction.update(groupRef, {
          'totalFund': FieldValue.increment(-contrib.totalPaid),
          'totalSavings': FieldValue.increment(-contrib.regularHaftaAmount),
          'totalOutstandingLoans': FieldValue.increment(principalToRestore),
          'totalInterestCollected': FieldValue.increment(-interestToRemove),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Log reversal activity
        final now = DateTime.now();
        final revTx = AppTransaction(
          id: 'REV_${now.millisecondsSinceEpoch}',
          memberId: contrib.memberId,
          memberName: 'Reversal',
          type: TransactionType.adjustment,
          amount: -contrib.totalPaid,
          date: now,
          description: 'Reversed payment for ${contrib.month}/${contrib.year}',
          referenceId: contributionId,
        );
        transaction.set(_firebaseService.activities(groupId).doc(revTx.id), revTx.toJson());
      });
    });
  }
}
