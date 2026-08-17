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

  // --- Reports & Statements ---
  Future<MemberMonthlyReport> getMemberReport(Member member, int month, int year) =>
      _reportService.getMemberMonthlyReport(groupId: groupId, member: member, month: month, year: year);

  Future<GroupMonthlyReport> getGroupReport(String groupName, int month, int year) =>
      _reportService.getGroupMonthlyReport(groupId: groupId, groupName: groupName, month: month, year: year);

  Future<List<PendingMemberReport>> getPendingReport({int? month, int? year, String? memberId}) =>
      _reportService.getPendingReport(groupId: groupId, month: month, year: year, memberId: memberId);

  Future<List<LoanReportItem>> getLoanReport({LoanStatus? statusFilter}) =>
      _reportService.getLoanReport(groupId: groupId, statusFilter: statusFilter);

  Future<List<MemberLedgerEntry>> getMemberLedger(String memberId) =>
      _reportService.getMemberLedger(groupId: groupId, memberId: memberId);

  // --- Group & Dashboard ---
  Stream<BachatGatGroup?> watchGroup() {
    _groupStream ??= _groupRepo.watchGroup(groupId).asBroadcastStream();
    return _groupStream!;
  }

  Future<void> updateGroupSettings({String? name, double? monthlyTarget, double? monthlyContributionAmount}) =>
      _groupRepo.updateGroupSettings(groupId, name: name, monthlyTarget: monthlyTarget, monthlyContributionAmount: monthlyContributionAmount);

  Stream<List<AppTransaction>> watchRecentActivities({int limit = 20}) {
    _recentActivitiesStream ??= _txRepo.watchRecentActivities(groupId, limit: limit).asBroadcastStream();
    return _recentActivitiesStream!;
  }

  // --- Members ---
  Stream<List<Member>> watchMembers({bool activeOnly = true}) {
    _membersStream ??= _groupRepo.watchMembers(groupId, activeOnly: activeOnly).asBroadcastStream();
    return _membersStream!;
  }

  Future<List<Member>> getMembers({bool activeOnly = true}) =>
      _groupRepo.getMembers(groupId, activeOnly: activeOnly);

  Future<Member?> getMember(String memberId) =>
      _groupRepo.getMember(groupId, memberId);
  
  Future<void> addMember(Member member) => _groupRepo.addMember(member);
  Future<void> updateMember(Member member) => _groupRepo.updateMember(member);
  Future<void> deactivateMember(String memberId) => _groupRepo.deactivateMember(groupId, memberId);

  // --- Transactions / Contributions ---
  Stream<List<MonthlyContribution>> watchContributions({String? memberId}) {
    return _txRepo.watchContributions(groupId, memberId: memberId);
  }

  Future<List<MonthlyContribution>> getContributions({String? memberId, int? month, int? year}) =>
      _txRepo.getContributions(groupId, memberId: memberId, month: month, year: year);

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

  Future<List<Loan>> getLoans({String? memberId, LoanStatus? status}) =>
      _txRepo.getLoans(groupId, memberId: memberId, status: status);

  Stream<List<LoanRepayment>> watchRepayments({String? loanId, String? memberId}) => 
      _txRepo.watchRepayments(groupId, loanId: loanId, memberId: memberId);

  Future<List<LoanRepayment>> getRepayments({String? loanId, String? memberId, int? month, int? year}) =>
      _txRepo.getRepayments(groupId, loanId: loanId, memberId: memberId, month: month, year: year);

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
