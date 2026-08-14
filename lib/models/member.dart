enum MemberStatus { active, inactive }

class Member {
  final String id;
  final String name;
  final String phone;
  final DateTime joinDate;
  final double monthlyInvestment;
  final MemberStatus status;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.joinDate,
    required this.monthlyInvestment,
    this.status = MemberStatus.active,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'joinDate': joinDate.toIso8601String(),
        'monthlyInvestment': monthlyInvestment,
        'status': status.name,
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        joinDate: DateTime.parse(json['joinDate']),
        monthlyInvestment: (json['monthlyInvestment'] as num).toDouble(),
        status: MemberStatus.values.byName(json['status'] ?? 'active'),
      );

  Member copyWith({
    String? name,
    String? phone,
    double? monthlyInvestment,
    MemberStatus? status,
  }) =>
      Member(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        joinDate: joinDate,
        monthlyInvestment: monthlyInvestment ?? this.monthlyInvestment,
        status: status ?? this.status,
      );
}
