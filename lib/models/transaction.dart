enum TransactionType {
  monthlyInvestment,
  loanIssue,
  loanRepayment,
  interestPayment,
  adjustment,
  otherIncome,
  otherExpense
}

class AppTransaction {
  final String id;
  final String memberId;
  final String memberName;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? description;
  final String? referenceId;

  AppTransaction({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.referenceId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'memberName': memberName,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'referenceId': referenceId,
      };

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'],
        memberId: json['memberId'],
        memberName: json['memberName'],
        type: TransactionType.values.byName(json['type']),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        description: json['description'],
        referenceId: json['referenceId'],
      );
}
