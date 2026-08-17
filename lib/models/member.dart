enum MemberStatus { active, inactive }

class Member {
  final String id;
  final String groupId;
  final String name;
  final String phone;
  final DateTime joinDate;
  final double monthlyContribution; // Current Hafta
  final MemberStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    required this.id,
    required this.groupId,
    required this.name,
    required this.phone,
    required this.joinDate,
    required this.monthlyContribution,
    this.status = MemberStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  double get monthlyHaftaAmount => monthlyContribution;

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'name': name,
        'phone': phone,
        'joinDate': joinDate.toIso8601String(),
        'monthlyContribution': monthlyContribution,
        'monthlyHaftaAmount': monthlyContribution,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'],
        groupId: json['groupId'] ?? '',
        name: json['name'],
        phone: json['phone'],
        joinDate: DateTime.parse(json['joinDate']),
        monthlyContribution: (json['monthlyHaftaAmount'] ?? json['monthlyContribution'] as num).toDouble(),
        status: MemberStatus.values.byName(json['status'] ?? 'active'),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );

  Member copyWith({
    String? name,
    String? phone,
    double? monthlyContribution,
    MemberStatus? status,
    DateTime? updatedAt,
  }) =>
      Member(
        id: id,
        groupId: groupId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        joinDate: joinDate,
        monthlyContribution: monthlyContribution ?? this.monthlyContribution,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
