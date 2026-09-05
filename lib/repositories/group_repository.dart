import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/data_import_service.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/transaction.dart';
import '../core/utils/calculation_utils.dart';
import '../core/utils/perf_logger.dart';

class GroupRepository {
  final FirebaseService _firebaseService;

  GroupRepository(this._firebaseService);

  Future<void> ensureGroupExists(String groupId, {String name = 'Chhatrapati Bachat Gat, Ghargaon Stand'}) async {
    final groupRef = _firebaseService.groups.doc(groupId);
    final doc = await groupRef.get();
    if (!doc.exists) {
      final now = DateTime.now();
      await groupRef.set({
        'id': groupId,
        'name': name,
        'managerId': 'manager_001',
        'monthlyTarget': 0.0,
        'monthlyContributionAmount': 1000.0,
        'monthlyHaftaDay': 10,
        'totalFund': 0.0,
        'totalSavings': 0.0,
        'totalOutstandingLoans': 0.0,
        'totalInterestCollected': 0.0,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final currentName = data['name'] as String?;
      if (currentName == null ||
          currentName.trim().isEmpty ||
          currentName == 'Shivshahi' ||
          currentName == 'Shivshahi Bachat Gat' ||
          currentName == 'shivshahi_group_001') {
        await groupRef.update({
          'name': name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }

    // Ensure member master data exists (preserves all 363 members)
    await DataImportService.ensureAllMasterMembersSeeded(this, groupId: groupId);

    await reconcileAndMigrateFinancialData(groupId);
  }

  /// Inspects and repairs any historical negative values in Firestore documents
  /// (e.g. legacy negative loans, repayments, or group total counters) and
  /// ensures group totals match the actual active loan balances and contributions.
  Future<void> reconcileAndMigrateFinancialData(String groupId) async {
    return PerfLogger.traceAsync('reconcileAndMigrateFinancialData($groupId)', () async {
      final batch = _firebaseService.firestore.batch();
      bool needsCommit = false;

      // 0. Inspect and normalize seeded members (M_1 to M_363) to have exactly shares: 1 and monthlyContribution: 1000.0
      final validMasterIds = DataImportService.masterDataset.map((d) => 'M_${d['srNo']}').toSet();
      final membersSnap = await _firebaseService.members(groupId).get();
      for (final doc in membersSnap.docs) {
        final docId = doc.id;
        final data = doc.data() as Map<String, dynamic>;
        if (docId.startsWith('M_')) {
          final rawShares = (data['shares'] as num?)?.toInt() ?? 1;
          final rawPerShare = (data['monthlyContributionPerShare'] as num?)?.toDouble() ?? 1000.0;
          final rawMonthly = (data['monthlyContribution'] as num?)?.toDouble() ?? 1000.0;
          if (rawShares != 1 || rawPerShare != 1000.0 || rawMonthly != 1000.0) {
            batch.update(doc.reference, {
              'shares': 1,
              'shareCount': 1,
              'monthlyContributionPerShare': 1000.0,
              'monthlyContribution': 1000.0,
              'monthlyHaftaAmount': 1000.0,
              'updatedAt': DateTime.now().toIso8601String(),
            });
            needsCommit = true;
          }
        } else if (!validMasterIds.contains(docId)) {
          final rawShares = (data['shares'] as num?)?.toInt() ?? 1;
          if (rawShares > 1) {
            batch.delete(doc.reference);
            needsCommit = true;
          }
        }
      }

      // 1. Inspect and repair all loans in groups/{groupId}/loans
      final loansSnapshot = await _firebaseService.loansByGroup(groupId).get();
      double trueOutstandingLoans = 0.0;

      for (final doc in loansSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rawOriginal = (data['originalPrincipal'] as num?)?.toDouble() ?? 0.0;
        final rawPending = (data['pendingPrincipal'] as num?)?.toDouble() ?? 0.0;
        final rawStatus = data['status'] as String? ?? 'active';

        bool docNeedsRepair = false;
        double positiveOriginal = rawOriginal;
        double positivePending = rawPending;

        if (rawOriginal < 0) {
          positiveOriginal = -rawOriginal;
          docNeedsRepair = true;
        }
        if (rawPending < 0) {
          positivePending = (rawPending == rawOriginal) ? positiveOriginal : 0.0;
          docNeedsRepair = true;
        }

        String updatedStatus = rawStatus;
        if (positivePending <= 0 && rawStatus == 'active') {
          updatedStatus = 'closed';
          docNeedsRepair = true;
        }

        if (docNeedsRepair) {
          batch.update(doc.reference, {
            'originalPrincipal': positiveOriginal,
            'pendingPrincipal': positivePending,
            'status': updatedStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          needsCommit = true;
        }

        if (updatedStatus == 'active' && positivePending > 0) {
          trueOutstandingLoans += positivePending;
        }
      }

      // 2. Inspect and repair loan_repayments in groups/{groupId}/loan_repayments
      final repaymentsSnapshot = await _firebaseService.loanRepayments(groupId).get();
      double trueTotalInterest = 0.0;

      for (final doc in repaymentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rawMonth = (data['month'] as num?)?.toInt() ?? 0;
        final rawYear = (data['year'] as num?)?.toInt() ?? 0;
        if (rawMonth == 9 && rawYear == 2026) {
          batch.delete(doc.reference);
          needsCommit = true;
          continue;
        }

        final rawPrincipal = (data['principalRepaid'] as num?)?.toDouble() ?? 0.0;
        final rawInterest = (data['interestAmount'] as num?)?.toDouble() ?? 0.0;
        final rawTotal = (data['totalPaid'] as num?)?.toDouble() ?? 0.0;

        bool repNeedsRepair = false;
        double posPrincipal = rawPrincipal;
        double posInterest = rawInterest;
        double posTotal = rawTotal;

        if (rawPrincipal < 0) {
          posPrincipal = -rawPrincipal;
          repNeedsRepair = true;
        }
        if (rawInterest < 0) {
          posInterest = -rawInterest;
          repNeedsRepair = true;
        }
        if (rawTotal < 0) {
          posTotal = -rawTotal;
          repNeedsRepair = true;
        }

        if (repNeedsRepair) {
          batch.update(doc.reference, {
            'principalRepaid': posPrincipal,
            'interestAmount': posInterest,
            'totalPaid': posTotal,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          needsCommit = true;
        }

        trueTotalInterest += posInterest;
      }

      // 3. Inspect contributions in groups/{groupId}/monthly_contributions
      final membersSnapshot = await _firebaseService.members(groupId).get();
      final membersMap = <String, Member>{};
      for (final doc in membersSnapshot.docs) {
        final m = Member.fromJson(doc.data() as Map<String, dynamic>);
        membersMap[m.id] = m;
      }

      final contribsSnapshot = await _firebaseService.monthlyContributionsByGroup(groupId).get();
      double trueTotalSavings = 0.0;

      for (final doc in contribsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final mId = data['memberId'] as String?;
        final member = mId != null ? membersMap[mId] : null;

        final rawMonth = (data['month'] as num?)?.toInt() ?? 0;
        final rawYear = (data['year'] as num?)?.toInt() ?? 0;

        final rawHafta = (data['regularHaftaAmount'] as num?)?.toDouble() ?? 0.0;
        final rawExpected = (data['expectedAmount'] as num?)?.toDouble() ?? 0.0;
        final rawPaid = (data['paidAmount'] as num?)?.toDouble() ?? (data['totalPaid'] as num?)?.toDouble() ?? 0.0;
        final rawInterest = (data['interestAmount'] as num?)?.toDouble() ?? 0.0;
        final rawPrincipal = (data['loanPrincipalPaid'] as num?)?.toDouble() ?? 0.0;
        final rawStatus = data['status'] as String? ?? 'pending';

        final memberDue = member?.monthlyContribution ?? 1000.0;
        final memberName = (member?.name ?? '').trim();
        final isAnkushGadekar = memberName.contains('अंकुश') && memberName.contains('गाडेकर');

        // Delete / revert any erroneous September 2026 test payment
        final isErroneousSeptember2026Payment = (rawMonth == 9 && rawYear == 2026) &&
            (rawPaid > 0 || rawStatus == 'paid' || rawStatus == 'partial' || rawInterest > 0 || rawPrincipal > 0 || data['paymentDate'] != null);

        // Delete / revert the 10 August 2026 ₹1,000 trial/test payment for Ankush Gadekar
        final isAnkushAug2026TrialPayment = isAnkushGadekar && (rawMonth == 8 && rawYear == 2026) &&
            (rawPaid > 0 || rawStatus == 'paid' || rawStatus == 'partial' || data['paymentDate'] != null);

        if (isErroneousSeptember2026Payment || isAnkushAug2026TrialPayment) {
          batch.update(doc.reference, {
            'regularHaftaAmount': memberDue,
            'expectedAmount': memberDue,
            'paidAmount': 0.0,
            'totalPaid': 0.0,
            'interestAmount': 0.0,
            'loanPrincipalPaid': 0.0,
            'status': 'pending',
            'paymentDate': null,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          needsCommit = true;
          continue;
        }

        final effectiveExpected = memberDue;
        final effectivePaid = rawPaid >= 0 ? rawPaid : 0.0;
        final validRegularPaid = effectivePaid > effectiveExpected ? effectiveExpected : effectivePaid;

        String effectiveStatus = rawStatus;
        if (validRegularPaid >= effectiveExpected && effectiveExpected > 0) {
          effectiveStatus = 'paid';
        } else if (validRegularPaid > 0) {
          effectiveStatus = 'partial';
        } else {
          effectiveStatus = 'pending';
        }

        bool docNeedsUpdate = false;
        if (rawHafta != memberDue ||
            rawExpected != effectiveExpected ||
            rawPaid != effectivePaid ||
            rawStatus != effectiveStatus ||
            data['regularHaftaAmount'] != memberDue) {
          docNeedsUpdate = true;
        }

        if (docNeedsUpdate) {
          batch.update(doc.reference, {
            'regularHaftaAmount': memberDue,
            'expectedAmount': effectiveExpected,
            'paidAmount': effectivePaid,
            'totalPaid': effectivePaid,
            'status': effectiveStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          needsCommit = true;
        }

        trueTotalSavings += (validRegularPaid > 0 ? validRegularPaid : 0.0);
      }

      // 3b. Inspect and purge any erroneous test/trial transaction records in activities
      final activitiesSnapshot = await _firebaseService.activities(groupId).get();
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dateStr = data['date'] as String?;
        final refId = data['referenceId'] as String? ?? '';
        final desc = data['description'] as String? ?? '';
        final mName = data['memberName'] as String? ?? '';
        final mId = data['memberId'] as String? ?? '';

        bool isSep2026Tx = false;
        if (dateStr != null) {
          try {
            final dt = DateTime.parse(dateStr);
            if (dt.year == 2026 && dt.month == 9) {
              isSep2026Tx = true;
            }
          } catch (_) {}
        }
        if (refId.contains('2026-09') ||
            refId.contains('2026_09') ||
            refId.contains('2026_9') ||
            refId.contains('9_2026') ||
            desc.contains('9/2026') ||
            desc.contains('09/2026') ||
            desc.contains('September 2026') ||
            desc.contains('सप्टेंबर 2026')) {
          isSep2026Tx = true;
        }

        bool isAnkushAug2026TrialTx = false;
        final isAnkush = (mName.contains('अंकुश') && mName.contains('गाडेकर')) ||
            (membersMap[mId]?.name.contains('अंकुश') == true && membersMap[mId]?.name.contains('गाडेकर') == true);
        if (isAnkush) {
          if (dateStr != null) {
            try {
              final dt = DateTime.parse(dateStr);
              if (dt.year == 2026 && dt.month == 8) {
                isAnkushAug2026TrialTx = true;
              }
            } catch (_) {}
          }
          if (refId.contains('2026-08') ||
              refId.contains('2026_08') ||
              refId.contains('2026_8') ||
              refId.contains('8_2026') ||
              desc.contains('8/2026') ||
              desc.contains('08/2026') ||
              desc.contains('August 2026') ||
              desc.contains('ऑगस्ट 2026')) {
            isAnkushAug2026TrialTx = true;
          }
        }

        if (isSep2026Tx || isAnkushAug2026TrialTx) {
          batch.delete(doc.reference);
          needsCommit = true;
        }
      }

      // 4. Inspect and repair the Group document totals
      final groupDoc = await _firebaseService.groups.doc(groupId).get();
      if (groupDoc.exists) {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        final storedName = groupData['name'] as String?;
        final storedOutstanding = (groupData['totalOutstandingLoans'] as num?)?.toDouble() ?? 0.0;
        final storedSavings = (groupData['totalSavings'] as num?)?.toDouble() ?? 0.0;
        final storedInterest = (groupData['totalInterestCollected'] as num?)?.toDouble() ?? 0.0;
        final storedFund = (groupData['totalFund'] as num?)?.toDouble() ?? 0.0;
        final storedTarget = (groupData['monthlyTarget'] as num?)?.toDouble() ?? 0.0;
        final perShare = (groupData['monthlyContributionAmount'] as num?)?.toDouble() ?? 1000.0;

        final activeMembersList = await getMembers(groupId, activeOnly: true);
        final calculatedTarget = CalculationUtils.calculateMonthlySavingsTarget(
          activeMembersList,
          perShareAmount: perShare,
        );

        final isLegacyName = storedName == null ||
            storedName.trim().isEmpty ||
            storedName == 'Shivshahi' ||
            storedName == 'Shivshahi Bachat Gat' ||
            storedName == 'shivshahi_group_001';
        final effectiveName = isLegacyName ? 'Chhatrapati Bachat Gat, Ghargaon Stand' : storedName;

        final effectiveSavings = trueTotalSavings;
        final effectiveInterest = trueTotalInterest;
        final effectiveOutstanding = trueOutstandingLoans >= 0 ? trueOutstandingLoans : 0.0;

        final calculatedAvailableFund = (effectiveSavings + effectiveInterest) - effectiveOutstanding;
        final effectiveFund = calculatedAvailableFund >= 0 ? calculatedAvailableFund : 0.0;

        final updates = <String, dynamic>{};
        if (isLegacyName) updates['name'] = effectiveName;
        if (storedOutstanding != effectiveOutstanding) updates['totalOutstandingLoans'] = effectiveOutstanding;
        if (storedSavings != effectiveSavings) updates['totalSavings'] = effectiveSavings;
        if (storedInterest != effectiveInterest) updates['totalInterestCollected'] = effectiveInterest;
        if (storedFund != effectiveFund) updates['totalFund'] = effectiveFund;
        if (storedTarget != calculatedTarget && calculatedTarget > 0) updates['monthlyTarget'] = calculatedTarget;

        if (updates.isNotEmpty) {
          updates['updatedAt'] = DateTime.now().toIso8601String();
          batch.update(groupDoc.reference, updates);
          needsCommit = true;
        }
      }

      if (needsCommit) {
        await batch.commit();
      }
    });
  }

  /// Resets all transactional, collection, loan, interest, and payment history to ZERO state.
  /// Strictly preserves all member master records (names, IDs, shares, join dates, etc.).
  Future<void> resetAllFinancialData(String groupId) async {
    return PerfLogger.traceAsync('resetAllFinancialData($groupId)', () async {
      // 1. Delete all monthly contributions
      final contribsSnapshot = await _firebaseService.monthlyContributionsByGroup(groupId).get();
      for (int i = 0; i < contribsSnapshot.docs.length; i += 450) {
        final batch = _firebaseService.firestore.batch();
        final chunk = contribsSnapshot.docs.skip(i).take(450);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 2. Delete all loans
      final loansSnapshot = await _firebaseService.loansByGroup(groupId).get();
      for (int i = 0; i < loansSnapshot.docs.length; i += 450) {
        final batch = _firebaseService.firestore.batch();
        final chunk = loansSnapshot.docs.skip(i).take(450);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 3. Delete all loan repayments
      final repaymentsSnapshot = await _firebaseService.loanRepayments(groupId).get();
      for (int i = 0; i < repaymentsSnapshot.docs.length; i += 450) {
        final batch = _firebaseService.firestore.batch();
        final chunk = repaymentsSnapshot.docs.skip(i).take(450);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 4. Delete all activities
      final activitiesSnapshot = await _firebaseService.activities(groupId).get();
      for (int i = 0; i < activitiesSnapshot.docs.length; i += 450) {
        final batch = _firebaseService.firestore.batch();
        final chunk = activitiesSnapshot.docs.skip(i).take(450);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 5. Reset group document counters to exactly 0.0
      final now = DateTime.now();
      await _firebaseService.groups.doc(groupId).set({
        'id': groupId,
        'name': 'Chhatrapati Bachat Gat, Ghargaon Stand',
        'managerId': 'manager_001',
        'monthlyTarget': 0.0,
        'monthlyContributionAmount': 1000.0,
        'monthlyHaftaDay': 10,
        'totalFund': 0.0,
        'totalSavings': 0.0,
        'totalOutstandingLoans': 0.0,
        'totalInterestCollected': 0.0,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      // 6. Ensure member master data is present (if empty, populate 363 members)
      final membersSnap = await _firebaseService.members(groupId).limit(1).get();
      if (membersSnap.docs.isEmpty) {
        await DataImportService.importExtractedMembers(this);
      }
    });
  }

  /// Generates and ensures independent monthly collection obligations for all active members
  /// up to the current active cycle (e.g. September 2026).
  /// Preserves all existing historical records (e.g. August 2026 PAID) and never overwrites them.
  Future<void> ensureMonthlyObligations(String groupId, {int? targetMonth, int? targetYear}) async {
    return PerfLogger.traceAsync('ensureMonthlyObligations($groupId)', () async {
      final now = DateTime.now();
      final month = targetMonth ?? now.month;
      final year = targetYear ?? now.year;

      final membersSnapshot = await _firebaseService.members(groupId).where('status', isEqualTo: MemberStatus.active.name).get();
      final loansSnapshot = await _firebaseService.loansByGroup(groupId).where('status', isEqualTo: LoanStatus.active.name).get();
      final existingContribsSnapshot = await _firebaseService.monthlyContributionsByGroup(groupId).where('month', isEqualTo: month).where('year', isEqualTo: year).get();

      final existingMemberIds = <String>{};
      for (final doc in existingContribsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final mId = data['memberId'] as String?;
        if (mId != null) existingMemberIds.add(mId);
      }

      final activeLoansByMember = <String, List<Loan>>{};
      for (final doc in loansSnapshot.docs) {
        final loan = Loan.fromJson(doc.data() as Map<String, dynamic>);
        if (loan.pendingPrincipal > 0) {
          activeLoansByMember.putIfAbsent(loan.memberId, () => []).add(loan);
        }
      }

      final batch = _firebaseService.firestore.batch();
      bool hasNew = false;

      for (final doc in membersSnapshot.docs) {
        final member = Member.fromJson(doc.data() as Map<String, dynamic>);
        if (existingMemberIds.contains(member.id)) continue;

        final docId = MonthlyContribution.generateId(
          memberId: member.id,
          month: month,
          year: year,
        );
        
        final memberLoans = activeLoansByMember[member.id] ?? const [];
        
        double monthlyInterest = 0.0;
        for (final loan in memberLoans) {
          monthlyInterest += CalculationUtils.calculateMonthlyInterest(
            outstandingPrincipal: loan.pendingPrincipal,
            annualRate: loan.interestRate,
          );
        }

        final regularHafta = member.monthlyContribution; // shares * monthlyContributionPerShare

        final contribution = {
          'id': docId,
          'memberId': member.id,
          'groupId': groupId,
          'month': month,
          'year': year,
          'regularHaftaAmount': regularHafta,
          'interestAmount': monthlyInterest,
          'loanPrincipalPaid': 0.0,
          'totalPaid': 0.0,
          'expectedAmount': regularHafta,
          'paidAmount': 0.0,
          'status': 'pending',
          'createdAt': DateTime(year, month, 1).toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        batch.set(_firebaseService.monthlyContributions.doc(docId), contribution);
        hasNew = true;
      }

      if (hasNew) {
        await batch.commit();
      }
    });
  }

  Future<BachatGatGroup?> getGroup(String groupId) async {
    return PerfLogger.traceAsync('getGroup($groupId)', () async {
      final doc = await _firebaseService.groups.doc(groupId).get();
      if (!doc.exists) return null;
      return BachatGatGroup.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  Stream<BachatGatGroup?> watchGroup(String groupId) {
    return _firebaseService.groups.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BachatGatGroup.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> createGroup(BachatGatGroup group) async {
    await _firebaseService.groups.doc(group.id).set(group.toJson(), SetOptions(merge: true));
  }

  Future<void> updateGroupSettings(String groupId, {
    String? name,
    double? monthlyTarget,
    double? monthlyContributionAmount,
    int? monthlyHaftaDay,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (monthlyTarget != null) updates['monthlyTarget'] = monthlyTarget;
    if (monthlyContributionAmount != null) updates['monthlyContributionAmount'] = monthlyContributionAmount;
    if (monthlyHaftaDay != null) updates['monthlyHaftaDay'] = monthlyHaftaDay;

    await _firebaseService.groups.doc(groupId).update(updates);
  }

  Stream<List<Member>> watchMembers(String groupId, {bool activeOnly = true}) {
    Query query = _firebaseService.members(groupId);
    if (activeOnly) {
      query = query.where('status', whereIn: ['ACTIVE', 'active', 'Active']);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();
      return CalculationUtils.sortMembersByBaseNameAndSequence(list);
    });
  }

  Future<List<Member>> getMembers(String groupId, {bool activeOnly = true}) async {
    return PerfLogger.traceAsync('getMembers($groupId, activeOnly=$activeOnly)', () async {
      Query query = _firebaseService.members(groupId);
      if (activeOnly) {
        query = query.where('status', whereIn: ['ACTIVE', 'active', 'Active']);
      }
      final snapshot = await query.get();
      final list = snapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();
      return CalculationUtils.sortMembersByBaseNameAndSequence(list);
    });
  }

  Future<Member?> getMember(String groupId, String memberId) async {
    return PerfLogger.traceAsync('getMember($groupId, $memberId)', () async {
      final doc = await _firebaseService.users.doc(memberId).get();
      if (!doc.exists) return null;
      return Member.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> addMember(Member member) async {
    if (member.shares < 1) {
      throw Exception('Shares must be at least 1.');
    }
    if (!member.monthlyContributionPerShare.isFinite || member.monthlyContributionPerShare < 0) {
      throw Exception('Contribution per share must be a valid non-negative amount.');
    }
    if (!member.monthlyContribution.isFinite || member.monthlyContribution < 0) {
      throw Exception('Total monthly contribution must be a valid non-negative amount.');
    }

    final batch = _firebaseService.firestore.batch();
    
    final memberRef = _firebaseService.users.doc(member.id);
    batch.set(memberRef, member.toJson());

    final now = DateTime.now();
    final activityRef = _firebaseService.transactions.doc('ACT_${now.millisecondsSinceEpoch}_add');
    final activity = AppTransaction(
      id: 'ACT_${now.millisecondsSinceEpoch}_add',
      groupId: member.groupId,
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.adjustment,
      amount: member.monthlyContribution,
      date: now,
      description: 'Member added: ${member.name} (Shares: ${member.shares}, Hafta: ₹${member.monthlyContribution.toStringAsFixed(0)})',
      referenceId: member.id,
    );
    batch.set(activityRef, activity.toJson());

    await batch.commit();
  }

  Future<void> updateMember(Member member) async {
    if (member.shares < 1) {
      throw Exception('Shares must be at least 1.');
    }
    if (!member.monthlyContributionPerShare.isFinite || member.monthlyContributionPerShare < 0) {
      throw Exception('Contribution per share must be a valid non-negative amount.');
    }
    if (!member.monthlyContribution.isFinite || member.monthlyContribution < 0) {
      throw Exception('Total monthly contribution must be a valid non-negative amount.');
    }

    final batch = _firebaseService.firestore.batch();

    final memberRef = _firebaseService.users.doc(member.id);
    batch.update(memberRef, member.toJson());

    final now = DateTime.now();
    final activityRef = _firebaseService.transactions.doc('ACT_${now.millisecondsSinceEpoch}_upd');
    final activity = AppTransaction(
      id: 'ACT_${now.millisecondsSinceEpoch}_upd',
      groupId: member.groupId,
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.adjustment,
      amount: member.monthlyContribution,
      date: now,
      description: 'Member updated: ${member.name} (Shares: ${member.shares}, Hafta: ₹${member.monthlyContribution.toStringAsFixed(0)})',
      referenceId: member.id,
    );
    batch.set(activityRef, activity.toJson());

    await batch.commit();
  }

  Future<void> deactivateMember(String groupId, String memberId) async {
    final doc = await _firebaseService.users.doc(memberId).get();
    final memberName = doc.exists ? (doc.data() as Map<String, dynamic>)['name'] ?? memberId : memberId;

    final batch = _firebaseService.firestore.batch();

    final memberRef = _firebaseService.users.doc(memberId);
    batch.update(memberRef, {
      'status': 'INACTIVE',
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final now = DateTime.now();
    final activityRef = _firebaseService.transactions.doc('ACT_${now.millisecondsSinceEpoch}_del');
    final activity = AppTransaction(
      id: 'ACT_${now.millisecondsSinceEpoch}_del',
      groupId: groupId,
      memberId: memberId,
      memberName: memberName,
      type: TransactionType.adjustment,
      amount: 0.0,
      date: now,
      description: 'Member deactivated: $memberName',
      referenceId: memberId,
    );
    batch.set(activityRef, activity.toJson());

    await batch.commit();
  }

  Future<void> deleteMember(String groupId, String memberId) async {
    await _firebaseService.users.doc(memberId).delete();
  }
}
