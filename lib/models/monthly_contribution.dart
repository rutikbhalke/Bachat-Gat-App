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
        totalPaid = totalPaid ?? paidAmount ?? ((regularHaftaAmount ?? 0.0) + (interestAmount) + (loanPrincipalPaid)),
        paidAmount = paidAmount ?? totalPaid ?? ((regularHaftaAmount ?? 0.0) + (interestAmount) + (loanPrincipalPaid));

  double get pendingAmount => expectedAmount - (paidAmount - interestAmount - loanPrincipalPaid > 0 ? paidAmount - interestAmount - loanPrincipalPaid : (paidAmount > expectedAmount ? expectedAmount : paidAmount));

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'groupId': groupId,
        'month': month,
        'year': year,
        'regularHaftaAmount': regularHaftaAmount,
        'interestAmount': interestAmount,
        'loanPrincipalPaid': loanPrincipalPaid,
        'totalPaid': totalPaid,
        'expectedAmount': expectedAmount,
        'paidAmount': paidAmount,
        'paymentDate': paymentDate?.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MonthlyContribution.fromJson(Map<String, dynamic> json) {
    final regular = (json['regularHaftaAmount'] ?? json['expectedAmount'] ?? 0.0) as num;
    final interest = (json['interestAmount'] ?? 0.0) as num;
    final principal = (json['loanPrincipalPaid'] ?? 0.0) as num;
    final total = (json['totalPaid'] ?? json['paidAmount'] ?? (regular + interest + principal)) as num;
    final expected = (json['expectedAmount'] ?? regular) as num;
    final paid = (json['paidAmount'] ?? total) as num;

    return MonthlyContribution(
      id: json['id'],
      memberId: json['memberId'],
      groupId: json['groupId'] ?? '',
      month: json['month'],
      year: json['year'],
      regularHaftaAmount: regular.toDouble(),
      interestAmount: interest.toDouble(),
      loanPrincipalPaid: principal.toDouble(),
      totalPaid: total.toDouble(),
      expectedAmount: expected.toDouble(),
      paidAmount: paid.toDouble(),
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      status: ContributionStatus.values.byName(json['status']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
