class LoanRepayment {
  final String id;
  final String loanId;
  final String memberId;
  final DateTime paymentDate;
  final double paymentAmount;
  final double interestAmount;
  final double principalAmount;
  final double remainingPrincipal;
  final String? notes;

  LoanRepayment({
    required this.id,
    required this.loanId,
    required this.memberId,
    required this.paymentDate,
    required this.paymentAmount,
    required this.interestAmount,
    required this.principalAmount,
    required this.remainingPrincipal,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'loanId': loanId,
        'memberId': memberId,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentAmount': paymentAmount,
        'interestAmount': interestAmount,
        'principalAmount': principalAmount,
        'remainingPrincipal': remainingPrincipal,
        'notes': notes,
      };

  factory LoanRepayment.fromJson(Map<String, dynamic> json) => LoanRepayment(
        id: json['id'],
        loanId: json['loanId'],
        memberId: json['memberId'],
        paymentDate: DateTime.parse(json['paymentDate']),
        paymentAmount: (json['paymentAmount'] as num).toDouble(),
        interestAmount: (json['interestAmount'] as num).toDouble(),
        principalAmount: (json['principalAmount'] as num).toDouble(),
        remainingPrincipal: (json['remainingPrincipal'] as num).toDouble(),
        notes: json['notes'],
      );
}
