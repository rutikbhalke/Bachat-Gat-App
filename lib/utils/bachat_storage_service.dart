import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/bachat_models.dart';

class BachatStorageService extends ChangeNotifier {
  static final BachatStorageService _instance =
      BachatStorageService._internal();
  factory BachatStorageService() => _instance;
  BachatStorageService._internal();

  List<BachatGroup> _groups = [];
  List<BachatMember> _members = [];
  List<BachatLoan> _loans = [];
  List<MonthlyPayment> _payments = [];

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<BachatGroup> get groups => List.unmodifiable(_groups);
  List<BachatMember> get members => List.unmodifiable(_members);
  List<BachatLoan> get loans => List.unmodifiable(_loans);
  List<MonthlyPayment> get payments => List.unmodifiable(_payments);

  static const String _keyGroups = 'bachat_groups_v1';
  static const String _keyMembers = 'bachat_members_v1';
  static const String _keyLoans = 'bachat_loans_v1';
  static const String _keyPayments = 'bachat_payments_v1';

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    final groupsJson = prefs.getString(_keyGroups);
    final membersJson = prefs.getString(_keyMembers);
    final loansJson = prefs.getString(_keyLoans);
    final paymentsJson = prefs.getString(_keyPayments);

    if (groupsJson != null && groupsJson.isNotEmpty) {
      final List decoded = json.decode(groupsJson);
      _groups = decoded.map((e) => BachatGroup.fromMap(e)).toList();
    }

    if (membersJson != null && membersJson.isNotEmpty) {
      final List decoded = json.decode(membersJson);
      _members = decoded.map((e) => BachatMember.fromMap(e)).toList();
    }

    if (loansJson != null && loansJson.isNotEmpty) {
      final List decoded = json.decode(loansJson);
      _loans = decoded.map((e) => BachatLoan.fromMap(e)).toList();
    }

    if (paymentsJson != null && paymentsJson.isNotEmpty) {
      final List decoded = json.decode(paymentsJson);
      _payments = decoded.map((e) => MonthlyPayment.fromMap(e)).toList();
    }

    // If empty, seed initial sample Bachat Gat data for instant user demonstration
    if (_groups.isEmpty) {
      await _seedInitialData();
    } else if (_enforceSingleGroup()) {
      await _saveAll();
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyGroups, json.encode(_groups.map((e) => e.toMap()).toList()));
    await prefs.setString(
        _keyMembers, json.encode(_members.map((e) => e.toMap()).toList()));
    await prefs.setString(
        _keyLoans, json.encode(_loans.map((e) => e.toMap()).toList()));
    await prefs.setString(
        _keyPayments, json.encode(_payments.map((e) => e.toMap()).toList()));
    notifyListeners();
  }

  Future<void> _seedInitialData() async {
    final defaultGroup = BachatGroup(
      id: 'group_1',
      name: 'Jai Hanuman Bachat Gat',
      formationDate: DateTime(2026, 1, 1),
      monthlyContribution: 1000.0,
      interestRateMonthly: 2.0,
      notes: 'Monthly fixed contribution with 2% loan interest',
    );

    _groups = [defaultGroup];

    final m1 = BachatMember(
      id: 'mem_1',
      groupId: 'group_1',
      name: 'Sunita Rajesh Patil',
      phone: '919876543210',
      role: 'President',
      joiningDate: DateTime(2026, 1, 1),
    );
    final m2 = BachatMember(
      id: 'mem_2',
      groupId: 'group_1',
      name: 'Anjali Ramesh Deshmukh',
      phone: '919812345678',
      role: 'Secretary',
      joiningDate: DateTime(2026, 1, 1),
    );
    final m3 = BachatMember(
      id: 'mem_3',
      groupId: 'group_1',
      name: 'Pooja Vikas Kulkarni',
      phone: '919765432109',
      role: 'Treasurer',
      joiningDate: DateTime(2026, 1, 1),
    );
    final m4 = BachatMember(
      id: 'mem_4',
      groupId: 'group_1',
      name: 'Rekha Suresh Pawar',
      phone: '919890123456',
      role: 'Member',
      joiningDate: DateTime(2026, 1, 15),
    );
    final m5 = BachatMember(
      id: 'mem_5',
      groupId: 'group_1',
      name: 'Meena Laxman Shinde',
      phone: '919922334455',
      role: 'Member',
      joiningDate: DateTime(2026, 2, 1),
    );

    _members = [m1, m2, m3, m4, m5];

    // Historical payments for Jan, Feb, Mar, Apr, May, Jun, Jul 2026
    final months = [
      'January 2026',
      'February 2026',
      'March 2026',
      'April 2026',
      'May 2026',
      'June 2026',
      'July 2026'
    ];

    for (int i = 0; i < months.length; i++) {
      final monthStr = months[i];
      final date = DateTime(2026, i + 1, 10);
      for (var mem in _members) {
        _payments.add(MonthlyPayment(
          id: 'pay_${mem.id}_$i',
          groupId: 'group_1',
          memberId: mem.id,
          memberName: mem.name,
          monthYear: monthStr,
          paymentDate: date,
          savingsAmount: 1000.0,
          totalPaid: 1000.0,
          notes: 'Regular monthly contribution',
        ));
      }
    }

    // Disburse a Loan to Rekha Suresh Pawar (₹10,000) taken in June 2026
    final loan1 = BachatLoan(
      id: 'loan_1',
      groupId: 'group_1',
      memberId: m4.id,
      memberName: m4.name,
      principalAmount: 10000.0,
      remainingPrincipal: 8000.0, // After ₹2,000 principal repayment
      interestRateMonthly: 2.0,
      issueDate: DateTime(2026, 6, 1),
      status: 'ACTIVE',
      purpose: 'Small Business Expansion',
    );

    _loans = [loan1];

    // July payment for Rekha Pawar (m4): ₹1,000 savings + ₹200 interest (2% of 10,000) + ₹2,000 principal repayment = ₹3,200 total paid
    _payments.add(MonthlyPayment(
      id: 'pay_m4_july_loan',
      groupId: 'group_1',
      memberId: m4.id,
      memberName: m4.name,
      monthYear: 'July 2026 (Loan Repayment)',
      paymentDate: DateTime(2026, 7, 10),
      savingsAmount: 1000.0,
      loanId: loan1.id,
      interestPaid: 200.0,
      principalPaid: 2000.0,
      totalPaid: 3200.0,
      remainingLoanPrincipal: 8000.0,
      notes: '₹1,000 Savings + ₹200 Interest (2%) + ₹2,000 Loan Principal Paid',
    ));

    await _saveAll();
  }

  bool _enforceSingleGroup() {
    if (_groups.isEmpty) return false;

    var changed = false;
    final primary = _groups.first;
    final cleanedName = primary.name.replaceAll('Mahila ', '').trim();
    final singleGroup = BachatGroup(
      id: primary.id,
      name: cleanedName.isEmpty ? 'Jai Hanuman Bachat Gat' : cleanedName,
      formationDate: primary.formationDate,
      monthlyContribution: primary.monthlyContribution,
      interestRateMonthly: primary.interestRateMonthly,
      notes: primary.notes,
    );

    if (_groups.length != 1 || singleGroup.name != primary.name) {
      _groups = [singleGroup];
      changed = true;
    }

    final groupId = singleGroup.id;
    _members = _members.map((m) {
      if (m.groupId == groupId) return m;
      changed = true;
      return BachatMember(
        id: m.id,
        groupId: groupId,
        name: m.name,
        phone: m.phone,
        role: m.role,
        joiningDate: m.joiningDate,
      );
    }).toList();

    _loans = _loans.map((l) {
      if (l.groupId == groupId) return l;
      changed = true;
      return BachatLoan(
        id: l.id,
        groupId: groupId,
        memberId: l.memberId,
        memberName: l.memberName,
        principalAmount: l.principalAmount,
        remainingPrincipal: l.remainingPrincipal,
        interestRateMonthly: l.interestRateMonthly,
        issueDate: l.issueDate,
        status: l.status,
        purpose: l.purpose,
      );
    }).toList();

    _payments = _payments.map((p) {
      if (p.groupId == groupId) return p;
      changed = true;
      return MonthlyPayment(
        id: p.id,
        groupId: groupId,
        memberId: p.memberId,
        memberName: p.memberName,
        monthYear: p.monthYear,
        paymentDate: p.paymentDate,
        savingsAmount: p.savingsAmount,
        loanId: p.loanId,
        interestPaid: p.interestPaid,
        principalPaid: p.principalPaid,
        totalPaid: p.totalPaid,
        remainingLoanPrincipal: p.remainingLoanPrincipal,
        notes: p.notes,
      );
    }).toList();

    return changed;
  }

  // Group Operations
  Future<BachatGroup> updateSingleGroup({
    required String name,
    required double monthlyContribution,
    required double interestRateMonthly,
    String notes = '',
  }) async {
    final existing = _groups.isNotEmpty
        ? _groups.first
        : BachatGroup(
            id: 'group_1',
            name: 'Jai Hanuman Bachat Gat',
            formationDate: DateTime.now(),
          );

    final group = BachatGroup(
      id: existing.id,
      name: name,
      formationDate: existing.formationDate,
      monthlyContribution: monthlyContribution,
      interestRateMonthly: interestRateMonthly,
      notes: notes,
    );

    _groups = [group];
    await _saveAll();
    return group;
  }

  Future<BachatGroup> addGroup({
    required String name,
    double monthlyContribution = 1000.0,
    double interestRateMonthly = 2.0,
    String notes = '',
  }) async {
    final groupId = _groups.isNotEmpty ? _groups.first.id : 'group_1';
    final group = BachatGroup(
      id: groupId,
      name: name,
      formationDate:
          _groups.isNotEmpty ? _groups.first.formationDate : DateTime.now(),
      monthlyContribution: monthlyContribution,
      interestRateMonthly: interestRateMonthly,
      notes: notes,
    );
    _groups = [group];
    await _saveAll();
    return group;
  }

  // Member Operations
  Future<BachatMember> addMember({
    required String groupId,
    required String name,
    required String phone,
    String role = 'Member',
  }) async {
    final member = BachatMember(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      name: name,
      phone: phone,
      role: role,
      joiningDate: DateTime.now(),
    );
    _members.add(member);
    await _saveAll();
    return member;
  }

  List<BachatMember> getMembersForGroup(String groupId) {
    return _members.where((m) => m.groupId == groupId).toList();
  }

  // Loan Operations
  Future<BachatLoan> disburseLoan({
    required String groupId,
    required String memberId,
    required double principalAmount,
    double interestRateMonthly = 2.0,
    String purpose = '',
  }) async {
    final member = _members.firstWhere((m) => m.id == memberId);
    final loan = BachatLoan(
      id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      memberId: memberId,
      memberName: member.name,
      principalAmount: principalAmount,
      remainingPrincipal: principalAmount,
      interestRateMonthly: interestRateMonthly,
      issueDate: DateTime.now(),
      status: 'ACTIVE',
      purpose: purpose,
    );
    _loans.add(loan);
    await _saveAll();
    return loan;
  }

  List<BachatLoan> getLoansForGroup(String groupId) {
    return _loans.where((l) => l.groupId == groupId).toList();
  }

  BachatLoan? getActiveLoanForMember(String memberId) {
    try {
      return _loans.firstWhere(
        (l) => l.memberId == memberId && l.status == 'ACTIVE',
      );
    } catch (_) {
      return null;
    }
  }

  // Payment Recording Logic
  Future<MonthlyPayment> recordPayment({
    required String groupId,
    required String memberId,
    required String monthYear,
    required double savingsAmount, // Default ₹1000
    double principalPaid = 0.0,
    double interestPaid = 0.0,
    String notes = '',
  }) async {
    final member = _members.firstWhere((m) => m.id == memberId);
    final activeLoan = getActiveLoanForMember(memberId);

    double remainingLoanBal = 0.0;
    String? loanIdUsed;

    if (activeLoan != null) {
      loanIdUsed = activeLoan.id;
      // Deduct principal paid from remaining principal
      activeLoan.remainingPrincipal =
          (activeLoan.remainingPrincipal - principalPaid)
              .clamp(0.0, double.infinity);
      remainingLoanBal = activeLoan.remainingPrincipal;
      if (activeLoan.remainingPrincipal <= 0) {
        activeLoan.status = 'PAID_OFF';
      }
    }

    final totalPaid = savingsAmount + interestPaid + principalPaid;

    final payment = MonthlyPayment(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      memberId: memberId,
      memberName: member.name,
      monthYear: monthYear,
      paymentDate: DateTime.now(),
      savingsAmount: savingsAmount,
      loanId: loanIdUsed,
      interestPaid: interestPaid,
      principalPaid: principalPaid,
      totalPaid: totalPaid,
      remainingLoanPrincipal: remainingLoanBal,
      notes: notes,
    );

    _payments.add(payment);
    await _saveAll();
    return payment;
  }

  List<MonthlyPayment> getPaymentsForMember(String memberId) {
    final list = _payments.where((p) => p.memberId == memberId).toList();
    list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return list;
  }

  List<MonthlyPayment> getPaymentsForGroup(String groupId) {
    final list = _payments.where((p) => p.groupId == groupId).toList();
    list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return list;
  }

  // Financial Summary Aggregates
  double getTotalSavingsForGroup(String groupId) {
    return _payments
        .where((p) => p.groupId == groupId)
        .fold(0.0, (sum, item) => sum + item.savingsAmount);
  }

  double getTotalInterestEarnedForGroup(String groupId) {
    return _payments
        .where((p) => p.groupId == groupId)
        .fold(0.0, (sum, item) => sum + item.interestPaid);
  }

  double getTotalLoansDisbursedForGroup(String groupId) {
    return _loans
        .where((l) => l.groupId == groupId)
        .fold(0.0, (sum, item) => sum + item.principalAmount);
  }

  double getTotalActiveLoanPrincipalForGroup(String groupId) {
    return _loans
        .where((l) => l.groupId == groupId && l.status == 'ACTIVE')
        .fold(0.0, (sum, item) => sum + item.remainingPrincipal);
  }

  double getNetAvailableGroupFunds(String groupId) {
    final savings = getTotalSavingsForGroup(groupId);
    final interest = getTotalInterestEarnedForGroup(groupId);
    final activeLoans = getTotalActiveLoanPrincipalForGroup(groupId);
    return (savings + interest - activeLoans);
  }

  double getTotalSavingsForMember(String memberId) {
    return _payments
        .where((p) => p.memberId == memberId)
        .fold(0.0, (sum, item) => sum + item.savingsAmount);
  }

  double getTotalInterestPaidByMember(String memberId) {
    return _payments
        .where((p) => p.memberId == memberId)
        .fold(0.0, (sum, item) => sum + item.interestPaid);
  }

  double getTotalPrincipalPaidByMember(String memberId) {
    return _payments
        .where((p) => p.memberId == memberId)
        .fold(0.0, (sum, item) => sum + item.principalPaid);
  }
}
