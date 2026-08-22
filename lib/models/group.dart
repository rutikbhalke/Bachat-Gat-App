class BachatGatGroup {
  final String id;
  final String name;
  final String managerId;
  final double monthlyTarget;
  final double monthlyContributionAmount;
  final int monthlyHaftaDay; // Configured monthly hafta due date (e.g. 10th of month, default: 10)
  
  // Denormalized totals for dashboard
  final double totalFund; // Current available cash balance in group
  final double totalSavings; // Total accumulated regular member savings
  final double totalOutstandingLoans; // Current active loan principal outstanding
  final double totalInterestCollected; // Total accumulated loan interest collected

  final DateTime createdAt;
  final DateTime updatedAt;

  BachatGatGroup({
    required this.id,
    required this.name,
    required this.managerId,
    required this.monthlyTarget,
    required this.monthlyContributionAmount,
    this.monthlyHaftaDay = 10,
    double totalFund = 0.0,
    double totalSavings = 0.0,
    double totalOutstandingLoans = 0.0,
    double totalInterestCollected = 0.0,
    required this.createdAt,
    required this.updatedAt,
  })  : totalFund = totalFund >= 0 ? totalFund : 0.0,
        totalSavings = totalSavings >= 0 ? totalSavings : 0.0,
        totalOutstandingLoans = totalOutstandingLoans >= 0 ? totalOutstandingLoans : 0.0,
        totalInterestCollected = totalInterestCollected >= 0 ? totalInterestCollected : 0.0;

  /// Actual available lending fund for the group (liquid cash available, never negative).
  /// Formula: Available Group Balance = Total Savings + Actual Interest Received - Outstanding Loan Principal
  double get availableFund {
    final computed = (totalSavings + totalInterestCollected) - totalOutstandingLoans;
    return computed > 0 ? computed : 0.0;
  }

  /// Actual available cash balance for disbursement/expenses (never negative).
  double get availableCash => availableFund;

  /// Total group worth / assets = Total Savings + Total Interest Collected (or Available Cash + Active Outstanding Loans).
  double get totalGroupAssets => (totalSavings + totalInterestCollected) > 0 ? (totalSavings + totalInterestCollected) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'managerId': managerId,
        'monthlyTarget': monthlyTarget,
        'monthlyContributionAmount': monthlyContributionAmount,
        'monthlyHaftaDay': monthlyHaftaDay,
        'totalFund': totalFund >= 0 ? totalFund : 0.0,
        'totalSavings': totalSavings >= 0 ? totalSavings : 0.0,
        'totalOutstandingLoans': totalOutstandingLoans >= 0 ? totalOutstandingLoans : 0.0,
        'totalInterestCollected': totalInterestCollected >= 0 ? totalInterestCollected : 0.0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BachatGatGroup.fromJson(Map<String, dynamic> json) {
    final rawFund = (json['totalFund'] as num?)?.toDouble() ?? 0.0;
    final rawSavings = (json['totalSavings'] as num?)?.toDouble() ?? 0.0;
    final rawOutstanding = (json['totalOutstandingLoans'] as num?)?.toDouble() ?? 0.0;
    final rawInterest = (json['totalInterestCollected'] as num?)?.toDouble() ?? 0.0;

    return BachatGatGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Chhatrapati Bachat Gat, Ghargaon Stand',
      managerId: json['managerId'] ?? 'manager_001',
      monthlyTarget: (json['monthlyTarget'] as num?)?.toDouble() ?? 0.0,
      monthlyContributionAmount: (json['monthlyContributionAmount'] as num?)?.toDouble() ?? 1000.0,
      monthlyHaftaDay: (json['monthlyHaftaDay'] as num?)?.toInt() ?? 10,
      totalFund: rawFund >= 0 ? rawFund : 0.0,
      totalSavings: rawSavings >= 0 ? rawSavings : 0.0,
      totalOutstandingLoans: rawOutstanding >= 0 ? rawOutstanding : 0.0,
      totalInterestCollected: rawInterest >= 0 ? rawInterest : 0.0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
