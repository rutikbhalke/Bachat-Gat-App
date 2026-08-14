class SavingsRecord {
  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final int month;
  final int year;

  SavingsRecord({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'amount': amount,
        'date': date.toIso8601String(),
        'month': month,
        'year': year,
      };

  factory SavingsRecord.fromJson(Map<String, dynamic> json) => SavingsRecord(
        id: json['id'],
        memberId: json['memberId'],
        amount: json['amount'].toDouble(),
        date: DateTime.parse(json['date']),
        month: json['month'],
        year: json['year'],
      );
}

class SavingsConfig {
  final double monthlyContribution;
  final DateTime effectiveFrom;

  SavingsConfig({
    required this.monthlyContribution,
    required this.effectiveFrom,
  });

  Map<String, dynamic> toJson() => {
        'monthlyContribution': monthlyContribution,
        'effectiveFrom': effectiveFrom.toIso8601String(),
      };

  factory SavingsConfig.fromJson(Map<String, dynamic> json) => SavingsConfig(
        monthlyContribution: json['monthlyContribution'].toDouble(),
        effectiveFrom: DateTime.parse(json['effectiveFrom']),
      );
}
