import 'dart:convert';

class BachatGroup {
  final String id;
  final String name;
  final DateTime formationDate;
  final double monthlyContribution; // Default ₹1000
  final double interestRateMonthly; // Default 2.0%
  final String notes;

  BachatGroup({
    required this.id,
    required this.name,
    required this.formationDate,
    this.monthlyContribution = 1000.0,
    this.interestRateMonthly = 2.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'formationDate': formationDate.toIso8601String(),
      'monthlyContribution': monthlyContribution,
      'interestRateMonthly': interestRateMonthly,
      'notes': notes,
    };
  }

  factory BachatGroup.fromMap(Map<String, dynamic> map) {
    return BachatGroup(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      formationDate: map['formationDate'] != null
          ? DateTime.parse(map['formationDate'])
          : DateTime.now(),
      monthlyContribution: (map['monthlyContribution'] ?? 1000.0).toDouble(),
      interestRateMonthly: (map['interestRateMonthly'] ?? 2.0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory BachatGroup.fromJson(String source) =>
      BachatGroup.fromMap(json.decode(source));
}

class BachatMember {
  final String id;
  final String groupId;
  final String name;
  final String phone;
  final String role; // President, Secretary, Treasurer, Member
  final DateTime joiningDate;

  BachatMember({
    required this.id,
    required this.groupId,
    required this.name,
    required this.phone,
    this.role = 'Member',
    required this.joiningDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'phone': phone,
      'role': role,
      'joiningDate': joiningDate.toIso8601String(),
    };
  }

  factory BachatMember.fromMap(Map<String, dynamic> map) {
    return BachatMember(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'Member',
      joiningDate: map['joiningDate'] != null
          ? DateTime.parse(map['joiningDate'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory BachatMember.fromJson(String source) =>
      BachatMember.fromMap(json.decode(source));
}

class BachatLoan {
  final String id;
  final String groupId;
  final String memberId;
  final String memberName;
  final double principalAmount;
  double remainingPrincipal;
  final double interestRateMonthly; // Default 2.0%
  final DateTime issueDate;
  String status; // ACTIVE, PAID_OFF
  final String purpose;

  BachatLoan({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.memberName,
    required this.principalAmount,
    required this.remainingPrincipal,
    this.interestRateMonthly = 2.0,
    required this.issueDate,
    this.status = 'ACTIVE',
    this.purpose = 'Personal / Emergency',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'memberId': memberId,
      'memberName': memberName,
      'principalAmount': principalAmount,
      'remainingPrincipal': remainingPrincipal,
      'interestRateMonthly': interestRateMonthly,
      'issueDate': issueDate.toIso8601String(),
      'status': status,
      'purpose': purpose,
    };
  }

  factory BachatLoan.fromMap(Map<String, dynamic> map) {
    return BachatLoan(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      principalAmount: (map['principalAmount'] ?? 0.0).toDouble(),
      remainingPrincipal: (map['remainingPrincipal'] ?? 0.0).toDouble(),
      interestRateMonthly: (map['interestRateMonthly'] ?? 2.0).toDouble(),
      issueDate: map['issueDate'] != null
          ? DateTime.parse(map['issueDate'])
          : DateTime.now(),
      status: map['status'] ?? 'ACTIVE',
      purpose: map['purpose'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory BachatLoan.fromJson(String source) =>
      BachatLoan.fromMap(json.decode(source));
}

class MonthlyPayment {
  final String id;
  final String groupId;
  final String memberId;
  final String memberName;
  final String monthYear; // e.g. "August 2026"
  final DateTime paymentDate;
  final double savingsAmount; // Default ₹1000
  final String? loanId;
  final double interestPaid; // 2% on previous balance
  final double principalPaid; // Amount reduced from loan
  final double totalPaid; // savingsAmount + interestPaid + principalPaid
  final double remainingLoanPrincipal; // Updated loan principal remaining after this payment
  final String notes;

  MonthlyPayment({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.memberName,
    required this.monthYear,
    required this.paymentDate,
    this.savingsAmount = 1000.0,
    this.loanId,
    this.interestPaid = 0.0,
    this.principalPaid = 0.0,
    required this.totalPaid,
    this.remainingLoanPrincipal = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'memberId': memberId,
      'memberName': memberName,
      'monthYear': monthYear,
      'paymentDate': paymentDate.toIso8601String(),
      'savingsAmount': savingsAmount,
      'loanId': loanId,
      'interestPaid': interestPaid,
      'principalPaid': principalPaid,
      'totalPaid': totalPaid,
      'remainingLoanPrincipal': remainingLoanPrincipal,
      'notes': notes,
    };
  }

  factory MonthlyPayment.fromMap(Map<String, dynamic> map) {
    return MonthlyPayment(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      monthYear: map['monthYear'] ?? '',
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : DateTime.now(),
      savingsAmount: (map['savingsAmount'] ?? 1000.0).toDouble(),
      loanId: map['loanId'],
      interestPaid: (map['interestPaid'] ?? 0.0).toDouble(),
      principalPaid: (map['principalPaid'] ?? 0.0).toDouble(),
      totalPaid: (map['totalPaid'] ?? 0.0).toDouble(),
      remainingLoanPrincipal: (map['remainingLoanPrincipal'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MonthlyPayment.fromJson(String source) =>
      MonthlyPayment.fromMap(json.decode(source));
}
