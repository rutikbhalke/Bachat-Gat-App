import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/transaction.dart';
import '../core/utils/perf_logger.dart';

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
      if (tx.amount <= 0) {
        throw Exception('Payment amount must be greater than zero.');
      }

      await _firebaseService.firestore.runTransaction((transaction) async {
        final groupRef = _firebaseService.groups.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Group $groupId does not exist.');
        }

        // 1. Record/Update Monthly Contribution
        // Use deterministic ID for reliability
        final docId = MonthlyContribution.generateId(
          memberId: contribution.memberId,
          month: contribution.month,
          year: contribution.year,
        );
        final contributionRef = _firebaseService.monthlyContributions(groupId).doc(docId);
        final existingContribDoc = await transaction.get(contributionRef);
        
        MonthlyContribution toSave;
        double incRegular = 0.0;
        double incInterest = 0.0;
        double incPrincipal = 0.0;

        if (repayment != null) {
          incRegular = repayment.regularContribution;
          incInterest = repayment.interestAmount;
          incPrincipal = repayment.principalRepaid;
        } else {
          incRegular = tx.amount;
        }

        if (existingContribDoc.exists) {
          final existing = MonthlyContribution.fromJson(existingContribDoc.data() as Map<String, dynamic>);
          
          final isAlreadyPaid = existing.status == ContributionStatus.paid ||
              (existing.expectedAmount > 0 && existing.paidAmount >= existing.expectedAmount);
          if (isAlreadyPaid && incRegular > 0) {
            throw Exception('या महिन्याचा हप्ता आधीच भरला गेला आहे (Payment for this month is already completed for this member).');
          }

          final totalPaidHaftaSoFar = existing.paidAmount + incRegular;
          final newStatus = totalPaidHaftaSoFar >= existing.expectedAmount ? ContributionStatus.paid : (totalPaidHaftaSoFar > 0 ? ContributionStatus.partial : ContributionStatus.pending);

          toSave = MonthlyContribution(
            id: docId,
            memberId: existing.memberId,
            groupId: groupId,
            month: existing.month,
            year: existing.year,
            regularHaftaAmount: existing.regularHaftaAmount,
            interestAmount: existing.interestAmount + incInterest,
            loanPrincipalPaid: existing.loanPrincipalPaid + incPrincipal,
            totalPaid: existing.totalPaid + tx.amount,
            expectedAmount: existing.expectedAmount,
            paidAmount: totalPaidHaftaSoFar,
            status: newStatus,
            paymentDate: tx.date,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          );
        } else {
          // Create new
          toSave = contribution.copyWith(
            id: docId,
            paidAmount: incRegular,
            interestAmount: incInterest,
            loanPrincipalPaid: incPrincipal,
            totalPaid: tx.amount,
            status: incRegular >= contribution.expectedAmount ? ContributionStatus.paid : (incRegular > 0 ? ContributionStatus.partial : ContributionStatus.pending),
          );
        }

        transaction.set(contributionRef, toSave.toJson());

        // 2. Record Loan Repayment if applicable
        if (loan != null && repayment != null) {
          final loanRef = _firebaseService.loans(groupId).doc(loan.id);
          final loanDoc = await transaction.get(loanRef);
          if (!loanDoc.exists) {
            throw Exception('Loan ${loan.id} does not exist.');
          }

          final currentLoan = Loan.fromJson(loanDoc.data() as Map<String, dynamic>);
          if (incPrincipal > currentLoan.pendingPrincipal) {
            throw Exception('Principal repayment (₹$incPrincipal) cannot exceed outstanding loan (₹${currentLoan.pendingPrincipal}).');
          }

          final repaymentRef = _firebaseService.loanRepayments(groupId).doc(repayment.id);
          transaction.set(repaymentRef, repayment.toJson());

          final newPending = currentLoan.pendingPrincipal - incPrincipal;
          final validNewPending = newPending > 0 ? newPending : 0.0;
          transaction.update(loanRef, {
            'pendingPrincipal': validNewPending,
            'status': validNewPending <= 0 ? LoanStatus.closed.name : LoanStatus.active.name,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }

        // 3. Record Activity
        final activityRef = _firebaseService.activities(groupId).doc(tx.id);
        transaction.set(activityRef, tx.toJson());

        // 4. Update Group totals
        transaction.update(groupRef, {
          'totalFund': FieldValue.increment(tx.amount),
          'totalSavings': FieldValue.increment(incRegular),
          'totalOutstandingLoans': FieldValue.increment(-incPrincipal),
          'totalInterestCollected': FieldValue.increment(incInterest),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    });
  }

  Future<void> issueLoan(String groupId, Loan loan, AppTransaction tx) async {
    return PerfLogger.traceAsync('issueLoan(${loan.id})', () async {
      if (loan.originalPrincipal <= 0 || tx.amount <= 0) {
        throw Exception('Loan amount must be greater than zero.');
      }

      final positivePrincipal = loan.originalPrincipal >= 0 ? loan.originalPrincipal : -loan.originalPrincipal;
      final sanitizedLoan = loan.copyWith(
        pendingPrincipal: positivePrincipal,
        status: LoanStatus.active,
      );

      await _firebaseService.firestore.runTransaction((transaction) async {
        final groupRef = _firebaseService.groups.doc(groupId);
        final groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group $groupId does not exist.');
        }

        final groupData = groupDoc.data() as Map<String, dynamic>;
        final totalSavings = (groupData['totalSavings'] as num?)?.toDouble() ?? 0.0;
        final totalInterest = (groupData['totalInterestCollected'] as num?)?.toDouble() ?? 0.0;
        final totalOutstandingLoans = (groupData['totalOutstandingLoans'] as num?)?.toDouble() ?? 0.0;
        
        final availableBalance = ((totalSavings + totalInterest) - totalOutstandingLoans) > 0
            ? ((totalSavings + totalInterest) - totalOutstandingLoans)
            : 0.0;

        if (positivePrincipal > availableBalance) {
          throw Exception('Insufficient available balance for this loan.');
        }

        transaction.set(_firebaseService.loans(groupId).doc(sanitizedLoan.id), sanitizedLoan.toJson());
        transaction.set(_firebaseService.activities(groupId).doc(tx.id), tx.toJson());
        
        // Update group totals atomically
        transaction.update(groupRef, {
          'totalFund': FieldValue.increment(-positivePrincipal),
          'totalOutstandingLoans': FieldValue.increment(positivePrincipal),
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
      if (repayment.totalPaid <= 0 || tx.amount <= 0) {
        throw Exception('Repayment amount must be greater than zero.');
      }
      if (repayment.principalRepaid < 0 || repayment.interestAmount < 0 || repayment.regularContribution < 0) {
        throw Exception('Repayment breakdown amounts cannot be negative.');
      }

      await _firebaseService.firestore.runTransaction((transaction) async {
        final loanRef = _firebaseService.loans(groupId).doc(loan.id);
        final loanDoc = await transaction.get(loanRef);
        if (!loanDoc.exists) {
          throw Exception('Loan ${loan.id} does not exist.');
        }

        final currentLoan = Loan.fromJson(loanDoc.data() as Map<String, dynamic>);
        
        final groupRef = _firebaseService.groups.doc(groupId);
        final groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Group $groupId does not exist.');
        }

        // 1. Record/Update the repayment event
        // Use deterministic ID: R_loanId_year_month
        final periodSuffix = '${repayment.year}_${repayment.month.toString().padLeft(2, '0')}';
        final repaymentDocId = 'R_${loan.id}_$periodSuffix';
        final repaymentRef = _firebaseService.loanRepayments(groupId).doc(repaymentDocId);
        final existingRepaymentDoc = await transaction.get(repaymentRef);

        LoanRepayment toSaveRepayment = repayment.copyWith(id: repaymentDocId);
        if (existingRepaymentDoc.exists) {
          final existing = LoanRepayment.fromJson(existingRepaymentDoc.data() as Map<String, dynamic>);
          toSaveRepayment = LoanRepayment(
            id: repaymentDocId,
            loanId: existing.loanId,
            groupId: existing.groupId,
            memberId: existing.memberId,
            month: existing.month,
            year: existing.year,
            openingPrincipal: existing.openingPrincipal, // Keep original opening
            interestRate: existing.interestRate,
            interestAmount: existing.interestAmount + repayment.interestAmount,
            regularContribution: existing.regularContribution + repayment.regularContribution,
            principalRepaid: existing.principalRepaid + repayment.principalRepaid,
            totalPaid: existing.totalPaid + repayment.totalPaid,
            closingPrincipal: existing.closingPrincipal - repayment.principalRepaid > 0 
                ? existing.closingPrincipal - repayment.principalRepaid 
                : 0.0,
            paymentDate: tx.date,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        transaction.set(repaymentRef, toSaveRepayment.toJson());

        // 2. Record/Update monthly contribution if regular payment included
        if (repayment.regularContribution > 0 || contribution != null) {
          final docId = MonthlyContribution.generateId(
            memberId: loan.memberId,
            month: repayment.month,
            year: repayment.year,
          );
          final contributionRef = _firebaseService.monthlyContributions(groupId).doc(docId);
          final existingContribDoc = await transaction.get(contributionRef);

          if (existingContribDoc.exists) {
            final existing = MonthlyContribution.fromJson(existingContribDoc.data() as Map<String, dynamic>);
            
            final isAlreadyPaid = existing.status == ContributionStatus.paid ||
                (existing.expectedAmount > 0 && existing.paidAmount >= existing.expectedAmount);
            if (isAlreadyPaid && repayment.regularContribution > 0) {
              throw Exception('या महिन्याचा हप्ता आधीच भरला गेला आहे (Payment for this month is already completed for this member).');
            }

            final newRegularPaid = existing.paidAmount + repayment.regularContribution;
            final newStatus = newRegularPaid >= existing.expectedAmount ? ContributionStatus.paid : (newRegularPaid > 0 ? ContributionStatus.partial : ContributionStatus.pending);

            final updatedContrib = MonthlyContribution(
              id: docId,
              memberId: existing.memberId,
              groupId: groupId,
              month: existing.month,
              year: existing.year,
              regularHaftaAmount: existing.regularHaftaAmount,
              interestAmount: existing.interestAmount + repayment.interestAmount,
              loanPrincipalPaid: existing.loanPrincipalPaid + repayment.principalRepaid,
              totalPaid: existing.totalPaid + tx.amount,
              expectedAmount: existing.expectedAmount,
              paidAmount: newRegularPaid,
              status: newStatus,
              paymentDate: tx.date,
              createdAt: existing.createdAt,
              updatedAt: DateTime.now(),
            );
            transaction.set(contributionRef, updatedContrib.toJson());
          } else if (contribution != null) {
            transaction.set(contributionRef, contribution.copyWith(id: docId).toJson());
          }
        }
        
        // 3. Record the activity
        final activityRef = _firebaseService.activities(groupId).doc(tx.id);
        transaction.set(activityRef, tx.toJson());
        
        // 4. Update Loan pending balance
        final newPending = currentLoan.pendingPrincipal - repayment.principalRepaid;
        final validNewPending = newPending > 0 ? newPending : 0.0;
        transaction.update(loanRef, {
          'pendingPrincipal': validNewPending,
          'status': validNewPending <= 0 ? LoanStatus.closed.name : LoanStatus.active.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // 5. Update Group totals
        transaction.update(groupRef, {
          'totalFund': FieldValue.increment(tx.amount),
          'totalSavings': FieldValue.increment(repayment.regularContribution),
          'totalOutstandingLoans': FieldValue.increment(-repayment.principalRepaid),
          'totalInterestCollected': FieldValue.increment(repayment.interestAmount),
          'updatedAt': DateTime.now().toIso8601String(),
        });
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
