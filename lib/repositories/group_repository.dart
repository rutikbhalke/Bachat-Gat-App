import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/transaction.dart';

class GroupRepository {
  final FirebaseService _firebaseService;

  GroupRepository(this._firebaseService);

  Future<void> ensureGroupExists(String groupId, {String name = 'Shivshahi Bachat Gat'}) async {
    final groupRef = _firebaseService.groups.doc(groupId);
    final doc = await groupRef.get();
    if (!doc.exists) {
      final now = DateTime.now();
      await groupRef.set({
        'id': groupId,
        'name': name,
        'managerId': 'manager_001',
        'monthlyTarget': 6000.0,
        'monthlyContributionAmount': 1000.0,
        'totalFund': 0.0,
        'totalSavings': 0.0,
        'totalOutstandingLoans': 0.0,
        'totalInterestCollected': 0.0,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Future<BachatGatGroup?> getGroup(String groupId) async {
    final doc = await _firebaseService.groups.doc(groupId).get();
    if (!doc.exists) return null;
    return BachatGatGroup.fromJson(doc.data() as Map<String, dynamic>);
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

  Stream<List<Member>> watchMembers(String groupId) {
    return _firebaseService.members(groupId)
        .where('status', isEqualTo: 'active')
        .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> addMember(Member member) async {
    final batch = _firebaseService.firestore.batch();
    
    final memberRef = _firebaseService.members(member.groupId).doc(member.id);
    batch.set(memberRef, member.toJson());

    final now = DateTime.now();
    final activityRef = _firebaseService.activities(member.groupId).doc('ACT_${now.millisecondsSinceEpoch}_add');
    final activity = AppTransaction(
      id: 'ACT_${now.millisecondsSinceEpoch}_add',
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.adjustment,
      amount: member.monthlyContribution,
      date: now,
      description: 'Member added: ${member.name}',
      referenceId: member.id,
    );
    batch.set(activityRef, activity.toJson());

    await batch.commit();
  }

  Future<void> updateMember(Member member) async {
    final batch = _firebaseService.firestore.batch();

    final memberRef = _firebaseService.members(member.groupId).doc(member.id);
    batch.update(memberRef, member.toJson());

    final now = DateTime.now();
    final activityRef = _firebaseService.activities(member.groupId).doc('ACT_${now.millisecondsSinceEpoch}_upd');
    final activity = AppTransaction(
      id: 'ACT_${now.millisecondsSinceEpoch}_upd',
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.adjustment,
      amount: member.monthlyContribution,
      date: now,
      description: 'Member updated: ${member.name} (Hafta: ₹${member.monthlyContribution})',
      referenceId: member.id,
    );
    batch.set(activityRef, activity.toJson());

    await batch.commit();
  }

  Future<void> deactivateMember(String groupId, String memberId) async {
    final doc = await _firebaseService.members(groupId).doc(memberId).get();
    final memberName = doc.exists ? (doc.data() as Map<String, dynamic>)['name'] ?? memberId : memberId;

    final batch = _firebaseService.firestore.batch();

    final memberRef = _firebaseService.members(groupId).doc(memberId);
    batch.update(memberRef, {
      'status': MemberStatus.inactive.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final now = DateTime.now();
    final activityRef = _firebaseService.activities(groupId).doc('ACT_${now.millisecondsSinceEpoch}_del');
    final activity = AppTransaction(
      id: 'ACT_${now.millisecondsSinceEpoch}_del',
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
}
