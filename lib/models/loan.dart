enum LoanStatus { active, closed, cancelled }

class Loan {
  final String id;
  final String groupId;
  final String memberId;
  final double originalPrincipal;
  final double pendingPrincipal;
  final double interestRate; // Monthly rate %
  final DateTime loanDate;
  final String? purpose;
  final LoanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.groupId,
    required this.memberId,
    required double originalPrincipal,
    required double pendingPrincipal,
    required this.interestRate,
    required this.loanDate,
    this.purpose,
    this.status = LoanStatus.active,
    required this.createdAt,
    required this.updatedAt,
  })  : originalPrincipal = originalPrincipal >= 0 ? originalPrincipal : -originalPrincipal,
        pendingPrincipal = pendingPrincipal >= 0 ? pendingPrincipal : 0.0;

  String get loanId => id;
  DateTime get issueDate => loanDate;
  DateTime get issuedAt => loanDate;
  double get principalAmount => originalPrincipal;
  double get remainingAmount => pendingPrincipal;
  double get totalPaid => (originalPrincipal - pendingPrincipal).clamp(0.0, double.infinity);
  double get totalPayable => originalPrincipal;
  bool get isFullyRepaid => pendingPrincipal <= 0 || status == LoanStatus.closed;

  Map<String, dynamic> toJson() {
    final statusStr = status == LoanStatus.active
        ? 'ACTIVE'
        : (status == LoanStatus.closed ? 'CLOSED' : 'CANCELLED');

    return {
      'id': id,
      'loanId': id,
      'groupId': groupId,
      'memberId': memberId,
      'principalAmount': originalPrincipal,
      'originalPrincipal': originalPrincipal,
      'remainingAmount': pendingPrincipal,
      'pendingPrincipal': pendingPrincipal,
      'totalPaid': totalPaid,
      'totalPayable': totalPayable,
      'interestRate': interestRate,
      'interestAmount': (originalPrincipal * (interestRate / 100)),
      'issuedAt': loanDate.toIso8601String(),
      'loanDate': loanDate.toIso8601String(),
      'issueDate': loanDate.toIso8601String(),
      'purpose': purpose,
      'status': statusStr,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory Loan.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    DateTime parseDate(dynamic value) {
      if (value == null) return now;
      if (value is DateTime) return value;
      if (value.runtimeType.toString().contains('Timestamp')) {
        try {
          return (value as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? now;
      }
      return now;
    }

    final rawOriginal = (json['principalAmount'] ?? json['originalPrincipal'] ?? 0.0) as num;
    final rawPending = (json['remainingAmount'] ?? json['pendingPrincipal'] ?? rawOriginal) as num;

    final positiveOriginal = rawOriginal.toDouble() >= 0 ? rawOriginal.toDouble() : -rawOriginal.toDouble();
    final positivePending = rawPending.toDouble() >= 0 ? rawPending.toDouble() : 0.0;

    LoanStatus parseStatus(dynamic value) {
      if (value == null) return LoanStatus.active;
      final str = value.toString().toUpperCase().trim();
      if (str == 'CLOSED' || str == 'PAID' || str == 'REPAID') return LoanStatus.closed;
      if (str == 'CANCELLED' || str == 'REJECTED') return LoanStatus.cancelled;
      if (str == 'ACTIVE' || str == 'OPEN' || str == 'APPROVED') return LoanStatus.active;
      for (final s in LoanStatus.values) {
        if (s.name.toUpperCase() == str) return s;
      }
      return LoanStatus.active;
    }

    final loanDt = parseDate(json['issuedAt'] ?? json['issueDate'] ?? json['loanDate']);

    return Loan(
      id: json['loanId']?.toString() ?? json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      originalPrincipal: positiveOriginal,
      pendingPrincipal: positivePending,
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 2.0,
      loanDate: loanDt,
      purpose: json['purpose']?.toString(),
      status: parseStatus(json['status']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Loan copyWith({
    double? pendingPrincipal,
    LoanStatus? status,
    DateTime? updatedAt,
  }) =>
      Loan(
        id: id,
        groupId: groupId,
        memberId: memberId,
        originalPrincipal: originalPrincipal,
        pendingPrincipal: pendingPrincipal ?? this.pendingPrincipal,
        interestRate: interestRate,
        loanDate: loanDate,
        purpose: purpose,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

