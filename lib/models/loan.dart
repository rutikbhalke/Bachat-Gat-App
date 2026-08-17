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
    required this.originalPrincipal,
    required this.pendingPrincipal,
    required this.interestRate,
    required this.loanDate,
    this.purpose,
    this.status = LoanStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  String get loanId => id;
  DateTime get issueDate => loanDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'loanId': id,
        'groupId': groupId,
        'memberId': memberId,
        'originalPrincipal': originalPrincipal,
        'pendingPrincipal': pendingPrincipal,
        'interestRate': interestRate,
        'loanDate': loanDate.toIso8601String(),
        'issueDate': loanDate.toIso8601String(),
        'purpose': purpose,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['loanId'] ?? json['id'],
        groupId: json['groupId'] ?? '',
        memberId: json['memberId'],
        originalPrincipal: (json['originalPrincipal'] as num).toDouble(),
        pendingPrincipal: (json['pendingPrincipal'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        loanDate: DateTime.parse(json['issueDate'] ?? json['loanDate']),
        purpose: json['purpose'],
        status: LoanStatus.values.byName(json['status'] ?? 'active'),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );

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
