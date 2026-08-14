enum LoanStatus { active, closed }

class Loan {
  final String id;
  final String memberId;
  final double loanAmount;
  final DateTime loanDate;
  final double interestRate; // Monthly rate
  final double outstandingPrincipal;
  final LoanStatus status;
  final String? purpose;
  final String? notes;

  Loan({
    required this.id,
    required this.memberId,
    required this.loanAmount,
    required this.loanDate,
    required this.interestRate,
    required this.outstandingPrincipal,
    this.status = LoanStatus.active,
    this.purpose,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'loanAmount': loanAmount,
        'loanDate': loanDate.toIso8601String(),
        'interestRate': interestRate,
        'outstandingPrincipal': outstandingPrincipal,
        'status': status.name,
        'purpose': purpose,
        'notes': notes,
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'],
        memberId: json['memberId'],
        loanAmount: (json['loanAmount'] as num).toDouble(),
        loanDate: DateTime.parse(json['loanDate']),
        interestRate: (json['interestRate'] as num).toDouble(),
        outstandingPrincipal: (json['outstandingPrincipal'] as num).toDouble(),
        status: LoanStatus.values.byName(json['status'] ?? 'active'),
        purpose: json['purpose'],
        notes: json['notes'],
      );

  Loan copyWith({
    double? outstandingPrincipal,
    LoanStatus? status,
  }) =>
      Loan(
        id: id,
        memberId: memberId,
        loanAmount: loanAmount,
        loanDate: loanDate,
        interestRate: interestRate,
        outstandingPrincipal: outstandingPrincipal ?? this.outstandingPrincipal,
        status: status ?? this.status,
        purpose: purpose,
        notes: notes,
      );
}
