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
      debugPrint('[REPORT ERROR] Error ensuring group exists: $e');
    });
  }

  /// Manually clears cached reports (e.g. after refresh button click or event)
  void invalidateReports() {
    _reportService.invalidateCache();
    notifyListeners();
  }

  /// Resets all payment, loan, repayment, and activity history to 0 state, preserving 363 members.
  Future<void> resetFinancialData() async {
    await _groupRepo.resetAllFinancialData(groupId);
    _reportService.invalidateCache();
    notifyListeners();
  }

  // --- Reports & Statements ---
  Future<MemberMonthlyReport> getMemberReport(Member member, int month, int year) =>
      _reportService.getMemberMonthlyReport(groupId: groupId, member: member, month: month, year: year);

  Future<GroupMonthlyReport> getGroupReport(String groupName, int month, int year, {bool forceRefresh = false}) =>
      _reportService.getGroupMonthlyReport(groupId: groupId, groupName: groupName, month: month, year: year, forceRefresh: forceRefresh);

  Future<List<PendingMemberReport>> getPendingReport({int? month, int? year, String? memberId, bool forceRefresh = false}) =>
      _reportService.getPendingReport(groupId: groupId, month: month, year: year, memberId: memberId, forceRefresh: forceRefresh);

  Future<List<LoanReportItem>> getLoanReport({LoanStatus? statusFilter, bool forceRefresh = false}) =>
      _reportService.getLoanReport(groupId: groupId, statusFilter: statusFilter, forceRefresh: forceRefresh);

  Future<List<MemberLedgerEntry>> getMemberLedger(String memberId, {bool forceRefresh = false}) =>
      _reportService.getMemberLedger(groupId: groupId, memberId: memberId, forceRefresh: forceRefresh);

  // --- Group & Dashboard ---
  Stream<BachatGatGroup?> watchGroup() {
    return _groupRepo.watchGroup(groupId);
  }

  Future<void> updateGroupSettings({
    String? name,
    double? monthlyTarget,
    double? monthlyContributionAmount,
    int? monthlyHaftaDay,
  }) async {
    await _groupRepo.updateGroupSettings(
      groupId,
      name: name,
      monthlyTarget: monthlyTarget,
      monthlyContributionAmount: monthlyContributionAmount,
      monthlyHaftaDay: monthlyHaftaDay,
    );
    _reportService.invalidateCache();
  }

  Stream<List<AppTransaction>> watchRecentActivities({int limit = 20}) {
    return _txRepo.watchRecentActivities(groupId, limit: limit);
  }

  // --- Members ---
  Stream<List<Member>> watchMembers({bool activeOnly = true}) {
    return _groupRepo.watchMembers(groupId, activeOnly: activeOnly);
  }

  Future<List<Member>> getMembers({bool activeOnly = true}) =>
      _groupRepo.getMembers(groupId, activeOnly: activeOnly);

  Future<Member?> getMember(String memberId) =>
      _groupRepo.getMember(groupId, memberId);
  
  Future<void> addMember(Member member) async {
    await _groupRepo.addMember(member);
    _reportService.invalidateCache();
  }

  Future<void> updateMember(Member member) async {
    await _groupRepo.updateMember(member);
    _reportService.invalidateCache();
  }

  Future<void> deactivateMember(String memberId) async {
    await _groupRepo.deactivateMember(groupId, memberId);
    _reportService.invalidateCache();
  }

  // --- Transactions / Contributions ---
  Future<void> ensureMonthlyObligations({int? targetMonth, int? targetYear}) async {
    await _groupRepo.ensureMonthlyObligations(groupId, targetMonth: targetMonth, targetYear: targetYear);
  }

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
  }) async {
    await _txRepo.recordContribution(
      groupId,
      contribution,
      tx,
      loan: loan,
      repayment: repayment,
    );
    _reportService.invalidateCache();
  }

  // --- Loans ---
  Stream<List<Loan>> watchLoans({String? memberId}) {
    return _txRepo.watchLoans(groupId, memberId: memberId);
  }

  Future<List<Loan>> getLoans({String? memberId, LoanStatus? status}) =>
      _txRepo.getLoans(groupId, memberId: memberId, status: status);

  Stream<List<LoanRepayment>> watchRepayments({String? loanId, String? memberId}) => 
      _txRepo.watchRepayments(groupId, loanId: loanId, memberId: memberId);

  Future<List<LoanRepayment>> getRepayments({String? loanId, String? memberId, int? month, int? year}) =>
      _txRepo.getRepayments(groupId, loanId: loanId, memberId: memberId, month: month, year: year);

  Future<void> issueLoan(Loan loan, AppTransaction tx) async {
    await _txRepo.issueLoan(groupId, loan, tx);
    _reportService.invalidateCache();
  }

  Future<void> recordLoanRepayment({
    required Loan loan,
    required LoanRepayment repayment,
    required AppTransaction tx,
    MonthlyContribution? contribution,
  }) async {
    await _txRepo.recordLoanRepayment(
      groupId: groupId,
      loan: loan,
      repayment: repayment,
      tx: tx,
      contribution: contribution,
    );
    _reportService.invalidateCache();
  }
}
