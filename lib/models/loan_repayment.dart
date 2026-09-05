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

  double get amount => totalPaid;
  double get interestPaid => interestAmount;
  DateTime get paidAt => paymentDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'repaymentId': id,
        'loanId': loanId,
        'groupId': groupId,
        'memberId': memberId,
        'month': month,
        'year': year,
        'amount': totalPaid,
        'openingPrincipal': openingPrincipal,
        'interestRate': interestRate,
        'interestAmount': interestAmount,
        'interestPaid': interestAmount,
        'regularContribution': regularContribution,
        'regularHafta': regularContribution,
        'principalRepaid': principalRepaid,
        'principalPaid': principalRepaid,
        'totalPaid': totalPaid,
        'totalPayment': totalPaid,
        'closingPrincipal': closingPrincipal,
        'pendingPrincipalAfterPayment': closingPrincipal,
        'paidAt': paymentDate.toIso8601String(),
        'paymentDate': paymentDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => toJson();

  factory LoanRepayment.fromJson(Map<String, dynamic> json) {
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

    final rawAmount = (json['amount'] ?? json['totalPayment'] ?? json['totalPaid'] ?? 0.0) as num;
    final principal = (json['principalPaid'] ?? json['principalRepaid'] ?? 0.0) as num;
    final interest = (json['interestPaid'] ?? json['interestAmount'] ?? 0.0) as num;
    final regular = (json['regularHafta'] ?? json['regularContribution'] ?? 0.0) as num;
    final opening = (json['openingPrincipal'] ?? 0.0) as num;
    final closing = (json['pendingPrincipalAfterPayment'] ?? json['closingPrincipal'] ?? 0.0) as num;

    final payDt = parseDate(json['paidAt'] ?? json['paymentDate']);

    return LoanRepayment(
      id: json['repaymentId']?.toString() ?? json['id']?.toString() ?? '',
      loanId: json['loanId']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      month: (json['month'] as num?)?.toInt() ?? payDt.month,
      year: (json['year'] as num?)?.toInt() ?? payDt.year,
      openingPrincipal: opening.toDouble(),
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 2.0,
      interestAmount: interest.toDouble(),
      regularContribution: regular.toDouble(),
      principalRepaid: principal.toDouble(),
      totalPaid: rawAmount.toDouble(),
      closingPrincipal: closing.toDouble(),
      paymentDate: payDt,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

