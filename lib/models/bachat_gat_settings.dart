class BachatGatSettings {
  final String groupName;
  final String managerName;
  final double defaultMonthlyInvestment;
  final double defaultInterestRate;
  final String currency;

  BachatGatSettings({
    required this.groupName,
    required this.managerName,
    required this.defaultMonthlyInvestment,
    required this.defaultInterestRate,
    this.currency = '₹',
  });

  Map<String, dynamic> toJson() => {
        'groupName': groupName,
        'managerName': managerName,
        'defaultMonthlyInvestment': defaultMonthlyInvestment,
        'defaultInterestRate': defaultInterestRate,
        'currency': currency,
      };

  factory BachatGatSettings.fromJson(Map<String, dynamic> json) => BachatGatSettings(
        groupName: json['groupName'] ?? 'My Bachat Gat',
        managerName: json['managerName'] ?? 'Manager',
        defaultMonthlyInvestment: (json['defaultMonthlyInvestment'] as num?)?.toDouble() ?? 1000.0,
        defaultInterestRate: (json['defaultInterestRate'] as num?)?.toDouble() ?? 2.0,
        currency: json['currency'] ?? '₹',
      );
}
