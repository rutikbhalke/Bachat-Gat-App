import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member.dart';
import '../models/monthly_investment.dart';
import '../models/loan.dart';
import '../models/loan_repayment.dart';
import '../models/transaction.dart';
import '../models/bachat_gat_settings.dart';
import '../core/utils/calculation_utils.dart';

class DataService {
  final SharedPreferences _prefs;

  DataService(this._prefs);

  // Keys
  static const String _membersKey = 'members_v2';
  static const String _investmentsKey = 'investments_v2';
  static const String _loansKey = 'loans_v2';
  static const String _repaymentsKey = 'repayments_v2';
  static const String _transactionsKey = 'transactions_v2';
  static const String _settingsKey = 'settings_v2';

  // --- Settings ---
  BachatGatSettings getSettings() {
    final String? data = _prefs.getString(_settingsKey);
    if (data == null) {
      return BachatGatSettings(
        groupName: 'Jai Hanuman Bachat Gat',
        managerName: 'Admin',
        defaultMonthlyInvestment: 1000,
        defaultInterestRate: 2.0,
      );
    }
    return BachatGatSettings.fromJson(jsonDecode(data));
  }

  Future<void> saveSettings(BachatGatSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  // --- Members ---
  List<Member> getMembers() {
    final String? data = _prefs.getString(_membersKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Member.fromJson(e)).toList();
  }

  Future<void> saveMembers(List<Member> members) async {
    await _prefs.setString(_membersKey, jsonEncode(members.map((e) => e.toJson()).toList()));
  }

  Future<void> addMember(Member member) async {
    final members = getMembers();
    members.add(member);
    await saveMembers(members);
  }

  // --- Monthly Investments ---
  List<MonthlyInvestment> getInvestments() {
    final String? data = _prefs.getString(_investmentsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => MonthlyInvestment.fromJson(e)).toList();
  }

  Future<void> saveInvestments(List<MonthlyInvestment> list) async {
    await _prefs.setString(_investmentsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> recordInvestment({
    required Member member,
    required int month,
    required int year,
    required double amount,
    String? notes,
  }) async {
    final investments = getInvestments();
    
    // Check if already exists for this member/month/year
    final existingIndex = investments.indexWhere((i) => 
      i.memberId == member.id && i.month == month && i.year == year);

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    
    double paidSoFar = amount;
    if (existingIndex != -1) {
      paidSoFar += investments[existingIndex].paidAmount;
    }

    final status = paidSoFar >= member.monthlyInvestment 
      ? InvestmentStatus.paid 
      : (paidSoFar > 0 ? InvestmentStatus.partial : InvestmentStatus.pending);

    final record = MonthlyInvestment(
      id: existingIndex != -1 ? investments[existingIndex].id : id,
      memberId: member.id,
      month: month,
      year: year,
      expectedAmount: member.monthlyInvestment, // Preserves history
      paidAmount: paidSoFar,
      paymentDate: DateTime.now(),
      status: status,
      notes: notes,
    );

    if (existingIndex != -1) {
      investments[existingIndex] = record;
    } else {
      investments.add(record);
    }

    await saveInvestments(investments);

    // Record Transaction
    await addTransaction(AppTransaction(
      id: 'T_$id',
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.monthlyInvestment,
      amount: amount,
      date: DateTime.now(),
      description: 'Monthly Investment - ${CalculationUtils.getMonthName(month)} $year',
      referenceId: record.id,
    ));
  }

  // --- Loans ---
  List<Loan> getLoans() {
    final String? data = _prefs.getString(_loansKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => Loan.fromJson(e)).toList();
  }

  Future<void> saveLoans(List<Loan> list) async {
    await _prefs.setString(_loansKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> issueLoan({
    required Member member,
    required double amount,
    required double rate,
    String? purpose,
    String? notes,
  }) async {
    final loans = getLoans();
    final String id = 'L_${DateTime.now().millisecondsSinceEpoch}';
    
    final loan = Loan(
      id: id,
      memberId: member.id,
      loanAmount: amount,
      loanDate: DateTime.now(),
      interestRate: rate,
      outstandingPrincipal: amount,
      purpose: purpose,
      notes: notes,
    );

    loans.add(loan);
    await saveLoans(loans);

    // Record Transaction
    await addTransaction(AppTransaction(
      id: 'T_$id',
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.loanIssue,
      amount: amount,
      date: DateTime.now(),
      description: 'Loan Issued: ${purpose ?? "General"}',
      referenceId: id,
    ));
  }

  // --- Repayments ---
  List<LoanRepayment> getRepayments() {
    final String? data = _prefs.getString(_repaymentsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => LoanRepayment.fromJson(e)).toList();
  }

  Future<void> saveRepayments(List<LoanRepayment> list) async {
    await _prefs.setString(_repaymentsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> recordRepayment({
    required Loan loan,
    required double paymentAmount,
    String? notes,
  }) async {
    final repayments = getRepayments();
    final loans = getLoans();
    
    final currentPrincipal = loan.outstandingPrincipal;
    final interestAmount = CalculationUtils.calculateMonthlyInterest(
      outstandingPrincipal: currentPrincipal,
      annualRate: loan.interestRate,
    );

    double principalPaid = paymentAmount - interestAmount;
    if (principalPaid < 0) principalPaid = 0; // Payment didn't even cover interest
    
    if (principalPaid > currentPrincipal) {
      principalPaid = currentPrincipal; // Overpayment
    }

    final remainingPrincipal = currentPrincipal - principalPaid;
    final String id = 'R_${DateTime.now().millisecondsSinceEpoch}';

    final repayment = LoanRepayment(
      id: id,
      loanId: loan.id,
      memberId: loan.memberId,
      paymentDate: DateTime.now(),
      paymentAmount: paymentAmount,
      interestAmount: interestAmount,
      principalAmount: principalPaid,
      remainingPrincipal: remainingPrincipal,
      notes: notes,
    );

    repayments.add(repayment);
    await saveRepayments(repayments);

    // Update Loan Status
    final loanIndex = loans.indexWhere((l) => l.id == loan.id);
    if (loanIndex != -1) {
      loans[loanIndex] = loans[loanIndex].copyWith(
        outstandingPrincipal: remainingPrincipal,
        status: remainingPrincipal <= 0 ? LoanStatus.closed : LoanStatus.active,
      );
      await saveLoans(loans);
    }

    // Record Transactions (Separate Principal and Interest)
    final member = getMembers().firstWhere((m) => m.id == loan.memberId);
    
    await addTransaction(AppTransaction(
      id: 'T_P_$id',
      memberId: member.id,
      memberName: member.name,
      type: TransactionType.loanRepayment,
      amount: principalPaid,
      date: DateTime.now(),
      description: 'Loan Principal Repayment',
      referenceId: id,
    ));

    if (interestAmount > 0) {
      await addTransaction(AppTransaction(
        id: 'T_I_$id',
        memberId: member.id,
        memberName: member.name,
        type: TransactionType.interestPayment,
        amount: interestAmount,
        date: DateTime.now(),
        description: 'Loan Interest Payment',
        referenceId: id,
      ));
    }
  }

  // --- Transactions ---
  List<AppTransaction> getTransactions() {
    final String? data = _prefs.getString(_transactionsKey);
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data);
    return list.map((e) => AppTransaction.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<AppTransaction> list) async {
    await _prefs.setString(_transactionsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> addTransaction(AppTransaction tx) async {
    final list = getTransactions();
    list.add(tx);
    await saveTransactions(list);
  }

  // --- Financial Aggregates ---
  double getTotalSavings() {
    return getInvestments().fold(0.0, (sum, i) => sum + i.paidAmount);
  }

  double getTotalOutstandingLoans() {
    return getLoans().where((l) => l.status == LoanStatus.active)
        .fold(0.0, (sum, l) => sum + l.outstandingPrincipal);
  }

  double getTotalInterestEarned() {
    return getRepayments().fold(0.0, (sum, r) => sum + r.interestAmount);
  }

  double getMonthlyCollection(int month, int year) {
    return getInvestments()
        .where((i) => i.month == month && i.year == year)
        .fold(0.0, (sum, i) => sum + i.paidAmount);
  }

  double getExpectedMonthlyCollection(int month, int year) {
    // For simplicity, sum of current monthlyInvestment of all active members
    return getMembers().where((m) => m.status == MemberStatus.active)
        .fold(0.0, (sum, m) => sum + m.monthlyInvestment);
  }
}
