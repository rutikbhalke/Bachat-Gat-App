enum ContributionStatus { paid, partial, pending, waived }

class MonthlyContribution {
  final String id;
  final String memberId;
  final String groupId;
  final int month;
  final int year;
  final double regularHaftaAmount;
  final double interestAmount;
  final double loanPrincipalPaid;
  final double totalPaid;
  final double expectedAmount;
  final double paidAmount;
  final DateTime? paymentDate;
  final ContributionStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyContribution({
    required this.id,
    required this.memberId,
    required this.groupId,
    required this.month,
    required this.year,
    double? regularHaftaAmount,
    this.interestAmount = 0.0,
    this.loanPrincipalPaid = 0.0,
    double? totalPaid,
    double? expectedAmount,
    double? paidAmount,
    this.paymentDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  })  : regularHaftaAmount = regularHaftaAmount ?? expectedAmount ?? 0.0,
        expectedAmount = expectedAmount ?? regularHaftaAmount ?? 0.0,
        paidAmount = paidAmount ?? 0.0,
        totalPaid = totalPaid ?? (paidAmount ?? 0.0) + interestAmount + loanPrincipalPaid;

  double get remainingAmount {
    return (expectedAmount - paidAmount).clamp(0.0, double.infinity);
  }
  double get pendingAmount => remainingAmount;

  /// Returns the regular savings/hafta portion actually paid for this monthly contribution obligation.
  /// Strictly represents the member's savings deposit (e.g. ₹1,000).
  /// Loan principal repayments and interest belong to the loan/repayment module and are never deducted from savings.
  double get actualRegularPaid {
    if (paidAmount > 0) {
      if ((interestAmount > 0 || loanPrincipalPaid > 0) && regularHaftaAmount > 0 && paidAmount > regularHaftaAmount) {
        final regular = paidAmount - interestAmount - loanPrincipalPaid;
        return regular > 0 ? (regular > regularHaftaAmount ? regularHaftaAmount : regular) : 0.0;
      }
      return (regularHaftaAmount > 0 && paidAmount > regularHaftaAmount) ? regularHaftaAmount : paidAmount;
    }
    if (status == ContributionStatus.paid) {
      return regularHaftaAmount > 0 ? regularHaftaAmount : (expectedAmount > 0 ? expectedAmount : 1000.0);
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    final statusStr = status == ContributionStatus.paid
        ? 'PAID'
        : (status == ContributionStatus.partial ? 'PARTIAL' : (status == ContributionStatus.waived ? 'WAIVED' : 'PENDING'));

    return {
      'id': id,
      'memberId': memberId,
      'groupId': groupId,
      'month': month,
      'year': year,
      'amount': paidAmount > 0 ? paidAmount : (expectedAmount > 0 ? expectedAmount : regularHaftaAmount),
      'regularHaftaAmount': regularHaftaAmount,
      'interestAmount': interestAmount,
      'loanPrincipalPaid': loanPrincipalPaid,
      'totalPaid': totalPaid,
      'expectedAmount': expectedAmount,
      'paidAmount': paidAmount,
      'paidAt': paymentDate?.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'status': statusStr,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  MonthlyContribution copyWith({
    String? id,
    String? memberId,
    String? groupId,
    int? month,
    int? year,
    double? regularHaftaAmount,
    double? interestAmount,
    double? loanPrincipalPaid,
    double? totalPaid,
    double? expectedAmount,
    double? paidAmount,
    DateTime? paymentDate,
    ContributionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyContribution(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      groupId: groupId ?? this.groupId,
      month: month ?? this.month,
      year: year ?? this.year,
      regularHaftaAmount: regularHaftaAmount ?? this.regularHaftaAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      loanPrincipalPaid: loanPrincipalPaid ?? this.loanPrincipalPaid,
      totalPaid: totalPaid ?? this.totalPaid,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MonthlyContribution.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value.runtimeType.toString().contains('Timestamp')) {
        try {
          return (value as dynamic).toDate() as DateTime;
        } catch (_) {}
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final rawAmount = (json['amount'] ?? json['paidAmount'] ?? json['expectedAmount'] ?? json['regularHaftaAmount'] ?? 0.0) as num;
    final regular = (json['regularHaftaAmount'] ?? json['expectedAmount'] ?? rawAmount) as num;
    final interest = (json['interestAmount'] ?? 0.0) as num;
    final principal = (json['loanPrincipalPaid'] ?? 0.0) as num;
    final total = (json['totalPaid'] ?? json['paidAmount'] ?? (regular + interest + principal)) as num;
    final expected = (json['expectedAmount'] ?? regular) as num;
    final paid = (json['paidAmount'] ?? (json['status']?.toString().toUpperCase() == 'PAID' ? rawAmount : 0.0)) as num;

    ContributionStatus parseStatus(dynamic value) {
      if (value == null) return ContributionStatus.pending;
      final str = value.toString().toUpperCase().trim();
      if (str == 'PAID') return ContributionStatus.paid;
      if (str == 'PARTIAL') return ContributionStatus.partial;
      if (str == 'WAIVED') return ContributionStatus.waived;
      if (str == 'PENDING' || str == 'DUE' || str == 'UNPAID') return ContributionStatus.pending;
      for (final s in ContributionStatus.values) {
        if (s.name.toUpperCase() == str) return s;
      }
      return ContributionStatus.pending;
    }

    final paymentDt = parseDate(json['paidAt']) ?? parseDate(json['paymentDate']);

    return MonthlyContribution(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      month: (json['month'] as num?)?.toInt() ?? now.month,
      year: (json['year'] as num?)?.toInt() ?? now.year,
      regularHaftaAmount: regular.toDouble(),
      interestAmount: interest.toDouble(),
      loanPrincipalPaid: principal.toDouble(),
      totalPaid: total.toDouble(),
      expectedAmount: expected.toDouble(),
      paidAmount: paid.toDouble(),
      paymentDate: paymentDt,
      status: parseStatus(json['status']),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt']) ?? now,
      updatedAt: parseDate(json['updatedAt']) ?? now,
    );
  }

  static String generateId({
    required String memberId,
    required int month,
    required int year,
  }) {
    final monthStr = month.toString().padLeft(2, '0');
    return 'C_${memberId}_${year}_$monthStr';
  }
}
