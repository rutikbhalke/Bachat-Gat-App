enum InvestmentStatus { paid, partial, pending }

class MonthlyInvestment {
  final String id;
  final String memberId;
  final int month;
  final int year;
  final double expectedAmount;
  final double paidAmount;
  final DateTime? paymentDate;
  final InvestmentStatus status;
  final String? notes;

  MonthlyInvestment({
    required this.id,
    required this.memberId,
    required this.month,
    required this.year,
    required this.expectedAmount,
    required this.paidAmount,
    this.paymentDate,
    required this.status,
    this.notes,
  });

  double get pendingAmount => expectedAmount - paidAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'month': month,
        'year': year,
        'expectedAmount': expectedAmount,
        'paidAmount': paidAmount,
        'paymentDate': paymentDate?.toIso8601String(),
        'status': status.name,
        'notes': notes,
      };

  factory MonthlyInvestment.fromJson(Map<String, dynamic> json) => MonthlyInvestment(
        id: json['id'],
        memberId: json['memberId'],
        month: json['month'],
        year: json['year'],
        expectedAmount: (json['expectedAmount'] as num).toDouble(),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
        status: InvestmentStatus.values.byName(json['status']),
        notes: json['notes'],
      );
}
