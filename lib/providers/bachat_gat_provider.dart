import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/monthly_contribution.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/transaction.dart';
import '../repositories/group_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/report_service.dart';
import '../models/report_models.dart';

class BachatGatProvider extends ChangeNotifier {
  final GroupRepository _groupRepo;
  final TransactionRepository _txRepo;
  final ReportService _reportService;
  
  final String groupId = 'shivshahi_group_001'; // Default group ID

  BachatGatProvider(this._groupRepo, this._txRepo, this._reportService) {
    _initGroup();
  }

  void _initGroup() {
    _groupRepo.ensureGroupExists(groupId).catchError((e) {
      debugPrint('Error ensuring group exists: $e');
    });
  }

  // --- Cached Streams ---
  Stream<BachatGatGroup?>? _groupStream;
  Stream<List<AppTransaction>>? _recentActivitiesStream;
  Stream<List<Member>>? _membersStream;
  Stream<List<Loan>>? _loansStream;

  // --- Reports ---
  Future<MemberMonthlyReport> getMemberReport(Member member, int month, int year) =>
      _reportService.getMemberMonthlyReport(groupId: groupId, member: member, month: month, year: year);

  Future<GroupMonthlyReport> getGroupReport(String groupName, int month, int year) =>
      _reportService.getGroupMonthlyReport(groupId: groupId, groupName: groupName, month: month, year: year);

  // --- Group & Dashboard ---
  Stream<BachatGatGroup?> watchGroup() {
    _groupStream ??= _groupRepo.watchGroup(groupId).asBroadcastStream();
    return _groupStream!;
  }

  Stream<List<AppTransaction>> watchRecentActivities() {
    _recentActivitiesStream ??= _txRepo.watchRecentActivities(groupId).asBroadcastStream();
    return _recentActivitiesStream!;
  }

  // --- Members ---
  Stream<List<Member>> watchMembers() {
    _membersStream ??= _groupRepo.watchMembers(groupId).asBroadcastStream();
    return _membersStream!;
  }
  
  Future<void> addMember(Member member) => _groupRepo.addMember(member);
  Future<void> updateMember(Member member) => _groupRepo.updateMember(member);
  Future<void> deactivateMember(String memberId) => _groupRepo.deactivateMember(groupId, memberId);

  // --- Transactions / Contributions ---
  Stream<List<MonthlyContribution>> watchContributions({String? memberId}) {
    return _txRepo.watchContributions(groupId, memberId: memberId);
  }

  Future<void> recordContribution(
    MonthlyContribution contribution,
    AppTransaction tx, {
    Loan? loan,
    LoanRepayment? repayment,
  }) => _txRepo.recordContribution(
    groupId,
    contribution,
    tx,
    loan: loan,
    repayment: repayment,
  );

  // --- Loans ---
  Stream<List<Loan>> watchLoans({String? memberId}) {
    if (memberId == null) {
      _loansStream ??= _txRepo.watchLoans(groupId).asBroadcastStream();
      return _loansStream!;
    }
    return _txRepo.watchLoans(groupId, memberId: memberId);
  }

  Stream<List<LoanRepayment>> watchRepayments({String? loanId, String? memberId}) => 
      _txRepo.watchRepayments(groupId, loanId: loanId, memberId: memberId);

  Future<void> issueLoan(Loan loan, AppTransaction tx) => 
      _txRepo.issueLoan(groupId, loan, tx);

  Future<void> recordLoanRepayment({
    required Loan loan,
    required LoanRepayment repayment,
    required AppTransaction tx,
    MonthlyContribution? contribution,
  }) => _txRepo.recordLoanRepayment(
    groupId: groupId,
    loan: loan,
    repayment: repayment,
    tx: tx,
    contribution: contribution,
  );
}
