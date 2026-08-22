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

  /// Returns only the regular savings/hafta portion actually paid for this monthly obligation.
  double get actualRegularPaid {
    // If interest or principal are explicitly tracked as non-zero on this record,
    // we must ensure they are not part of the 'paidAmount' if 'paidAmount' was
    // recorded as the total payment (legacy behavior).
    if (interestAmount > 0 || loanPrincipalPaid > 0) {
      // If paidAmount matches totalPaid, it likely includes interest/principal
      if ((paidAmount - totalPaid).abs() < 0.01) {
        final regular = totalPaid - interestAmount - loanPrincipalPaid;
        return regular > 0 ? (regular > expectedAmount ? expectedAmount : regular) : 0.0;
      }
    }
    // Otherwise trust paidAmount but clamp to expected
    return paidAmount > expectedAmount ? expectedAmount : paidAmount;
  }

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

  static String generateId({
    required String memberId,
    required int month,
    required int year,
  }) {
    final monthStr = month.toString().padLeft(2, '0');
    return 'C_${memberId}_${year}_$monthStr';
  }
}
