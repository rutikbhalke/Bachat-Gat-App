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
  final String groupId;
  final String memberId;
  final String memberName;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? description;
  final String? referenceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppTransaction({
    required this.id,
    this.groupId = '',
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.referenceId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'memberId': memberId,
        'memberName': memberName,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'description': description,
        'referenceId': referenceId,
        'createdAt': (createdAt ?? date).toIso8601String(),
        'updatedAt': (updatedAt ?? date).toIso8601String(),
      };

  Map<String, dynamic> toFirestore() => toJson();

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
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

    TransactionType parseType(dynamic value) {
      if (value == null) return TransactionType.adjustment;
      final str = value.toString().trim();
      for (final t in TransactionType.values) {
        if (t.name == str || t.name.toLowerCase() == str.toLowerCase()) return t;
      }
      if (str.toLowerCase().contains('contribution') || str.toLowerCase().contains('saving') || str.toLowerCase().contains('hafta')) {
        return TransactionType.monthlyInvestment;
      }
      if (str.toLowerCase().contains('repay')) return TransactionType.loanRepayment;
      if (str.toLowerCase().contains('loan')) return TransactionType.loanIssue;
      return TransactionType.adjustment;
    }

    final txDate = parseDate(json['date'] ?? json['createdAt']);

    return AppTransaction(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      memberName: json['memberName']?.toString() ?? '',
      type: parseType(json['type']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: txDate,
      description: json['description']?.toString(),
      referenceId: json['referenceId']?.toString(),
      createdAt: parseDate(json['createdAt'] ?? txDate),
      updatedAt: parseDate(json['updatedAt'] ?? txDate),
    );
  }
}

