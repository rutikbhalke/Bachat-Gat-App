class LoanRepayment {
  final String id;
  final String loanId;
  final String groupId;
  final String memberId;
  final int month;
  final int year;
  final double openingPrincipal;
  final double interestRate;
  final double interestAmount;
  final double regularContribution;
  final double principalRepaid;
  final double totalPaid;
  final double closingPrincipal;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanRepayment({
    required this.id,
    required this.loanId,
    required this.groupId,
    required this.memberId,
    required this.month,
    required this.year,
    required this.openingPrincipal,
    required this.interestRate,
    required this.interestAmount,
    required this.regularContribution,
    required this.principalRepaid,
    required this.totalPaid,
    required this.closingPrincipal,
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  String get repaymentId => id;
  double get regularHafta => regularContribution;
  double get principalPaid => principalRepaid;
  double get totalPayment => totalPaid;
  double get pendingPrincipalAfterPayment => closingPrincipal;

  LoanRepayment copyWith({
    String? id,
    String? loanId,
    String? groupId,
    String? memberId,
    int? month,
    int? year,
    double? openingPrincipal,
    double? interestRate,
    double? interestAmount,
    double? regularContribution,
    double? principalRepaid,
    double? totalPaid,
    double? closingPrincipal,
    DateTime? paymentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanRepayment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      month: month ?? this.month,
      year: year ?? this.year,
      openingPrincipal: openingPrincipal ?? this.openingPrincipal,
      interestRate: interestRate ?? this.interestRate,
      interestAmount: interestAmount ?? this.interestAmount,
      regularContribution: regularContribution ?? this.regularContribution,
      principalRepaid: principalRepaid ?? this.principalRepaid,
      totalPaid: totalPaid ?? this.totalPaid,
      closingPrincipal: closingPrincipal ?? this.closingPrincipal,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'repaymentId': id,
        'loanId': loanId,
        'groupId': groupId,
        'memberId': memberId,
        'month': month,
        'year': year,
        'openingPrincipal': openingPrincipal,
        'interestRate': interestRate,
        'interestAmount': interestAmount,
        'regularContribution': regularContribution,
        'regularHafta': regularContribution,
        'principalRepaid': principalRepaid,
        'principalPaid': principalRepaid,
        'totalPaid': totalPaid,
        'totalPayment': totalPaid,
        'closingPrincipal': closingPrincipal,
        'pendingPrincipalAfterPayment': closingPrincipal,
        'paymentDate': paymentDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LoanRepayment.fromJson(Map<String, dynamic> json) => LoanRepayment(
        id: json['repaymentId'] ?? json['id'],
        loanId: json['loanId'],
        groupId: json['groupId'] ?? '',
        memberId: json['memberId'],
        month: json['month'],
        year: json['year'],
        openingPrincipal: (json['openingPrincipal'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        interestAmount: (json['interestAmount'] as num).toDouble(),
        regularContribution: (json['regularHafta'] ?? json['regularContribution'] ?? 0.0 as num).toDouble(),
        principalRepaid: (json['principalPaid'] ?? json['principalRepaid'] as num).toDouble(),
        totalPaid: (json['totalPayment'] ?? json['totalPaid'] as num).toDouble(),
        closingPrincipal: (json['pendingPrincipalAfterPayment'] ?? json['closingPrincipal'] as num).toDouble(),
        paymentDate: DateTime.parse(json['paymentDate']),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
}
