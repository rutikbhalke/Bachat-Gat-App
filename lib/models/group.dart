class BachatGatGroup {
  final String id;
  final String name;
  final String managerId;
  final double monthlyTarget;
  final double monthlyContributionAmount;
  
  // Denormalized totals for dashboard
  final double totalFund; 
  final double totalSavings;
  final double totalOutstandingLoans;
  final double totalInterestCollected;

  final DateTime createdAt;
  final DateTime updatedAt;

  BachatGatGroup({
    required this.id,
    required this.name,
    required this.managerId,
    required this.monthlyTarget,
    required this.monthlyContributionAmount,
    this.totalFund = 0.0,
    this.totalSavings = 0.0,
    this.totalOutstandingLoans = 0.0,
    this.totalInterestCollected = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'managerId': managerId,
        'monthlyTarget': monthlyTarget,
        'monthlyContributionAmount': monthlyContributionAmount,
        'totalFund': totalFund,
        'totalSavings': totalSavings,
        'totalOutstandingLoans': totalOutstandingLoans,
        'totalInterestCollected': totalInterestCollected,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BachatGatGroup.fromJson(Map<String, dynamic> json) => BachatGatGroup(
        id: json['id'],
        name: json['name'],
        managerId: json['managerId'],
        monthlyTarget: (json['monthlyTarget'] as num).toDouble(),
        monthlyContributionAmount: (json['monthlyContributionAmount'] as num).toDouble(),
        totalFund: (json['totalFund'] as num).toDouble(),
        totalSavings: (json['totalSavings'] as num).toDouble(),
        totalOutstandingLoans: (json['totalOutstandingLoans'] as num).toDouble(),
        totalInterestCollected: (json['totalInterestCollected'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
}
