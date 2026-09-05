enum MemberStatus { active, inactive }

class Member {
  final String id;
  final String groupId;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String memberCode;
  final DateTime joinDate;

  /// Number of shares owned by the member.
  /// Minimum = 1.
  final int shares;

  /// Monthly contribution for ONE share.
  /// Default = ₹1000.
  final double monthlyContributionPerShare;

  /// Total monthly hafta.
  /// Always = shares × monthlyContributionPerShare.
  final double monthlyContribution;

  final MemberStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const double defaultMonthlyContributionPerShare = 1000.0;

  Member({
    required this.id,
    required this.groupId,
    required this.name,
    required this.phone,
    this.email = '',
    this.role = 'MEMBER',
    this.memberCode = '',
    required this.joinDate,
    int? shares,
    double? monthlyContributionPerShare,
    double? monthlyContribution,
    this.status = MemberStatus.active,
    required this.createdAt,
    required this.updatedAt,
  })  : shares = _normalizeShares(shares),
        monthlyContributionPerShare = _resolvePerShare(
          shares: _normalizeShares(shares),
          perShare: monthlyContributionPerShare,
          totalMonthly: monthlyContribution,
        ),
        monthlyContribution = _calculateTotal(
          shares: _normalizeShares(shares),
          perShare: _resolvePerShare(
            shares: _normalizeShares(shares),
            perShare: monthlyContributionPerShare,
            totalMonthly: monthlyContribution,
          ),
        );

  String get uid => id;
  String get fullName => name;
  double get monthlyShare => monthlyContribution;

  // ---------------------------------------------------------------------------
  // NORMALIZATION / CALCULATION
  // ---------------------------------------------------------------------------

  static int _normalizeShares(int? value) {
    if (value == null || value < 1) {
      return 1;
    }

    return value;
  }

  static double _resolvePerShare({
    required int shares,
    double? perShare,
    double? totalMonthly,
  }) {
    if (perShare != null && perShare.isFinite && perShare >= 0) {
      return perShare;
    }

    if (totalMonthly != null && totalMonthly.isFinite && totalMonthly >= 0) {
      return totalMonthly / shares;
    }

    return defaultMonthlyContributionPerShare;
  }

  static double _calculateTotal({
    required int shares,
    required double perShare,
  }) {
    final total = shares * perShare;
    if (!total.isFinite || total < 0) {
      return 0.0;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  int get shareCount => shares;
  double get monthlyHaftaAmount => monthlyContribution;
  double get totalMonthlyHafta => monthlyContribution;
  double get perShareHafta => monthlyContributionPerShare;

  // ---------------------------------------------------------------------------
  // JSON / FIRESTORE
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': id,
      'groupId': groupId,
      'name': name,
      'fullName': name,
      'phone': phone,
      'email': email,
      'role': role,
      'memberCode': memberCode.isNotEmpty ? memberCode : id,
      'joinDate': joinDate.toIso8601String(),
      'shares': shares,
      'shareCount': shares,
      'monthlyShare': monthlyContribution,
      'monthlyContributionPerShare': monthlyContributionPerShare,
      'monthlyContribution': monthlyContribution,
      'monthlyHaftaAmount': monthlyContribution,
      'status': status == MemberStatus.active ? 'ACTIVE' : 'INACTIVE',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  // ---------------------------------------------------------------------------
  // FROM JSON
  // ---------------------------------------------------------------------------

  factory Member.fromJson(Map<String, dynamic> json) {
    final dynamic rawShares = json['shares'] ?? json['shareCount'];
    int parsedShares = 1;
    if (rawShares is num) {
      parsedShares = rawShares.toInt();
    } else if (rawShares is String) {
      parsedShares = int.tryParse(rawShares) ?? 1;
    }
    if (parsedShares < 1) parsedShares = 1;

    final dynamic rawPerShare = json['monthlyContributionPerShare'];
    double? parsedPerShare;
    if (rawPerShare is num) {
      parsedPerShare = rawPerShare.toDouble();
    } else if (rawPerShare is String) {
      parsedPerShare = double.tryParse(rawPerShare);
    }

    final dynamic rawMonthly = json['monthlyShare'] ?? json['monthlyHaftaAmount'] ?? json['monthlyContribution'];
    double? parsedMonthly;
    if (rawMonthly is num) {
      parsedMonthly = rawMonthly.toDouble();
    } else if (rawMonthly is String) {
      parsedMonthly = double.tryParse(rawMonthly);
    }

    final double finalPerShare;
    if (parsedPerShare != null && parsedPerShare.isFinite && parsedPerShare >= 0) {
      finalPerShare = parsedPerShare;
    } else if (parsedMonthly != null && parsedMonthly.isFinite && parsedMonthly >= 0) {
      finalPerShare = parsedMonthly / parsedShares;
    } else {
      finalPerShare = defaultMonthlyContributionPerShare;
    }

    final double finalMonthly = _calculateTotal(
      shares: parsedShares,
      perShare: finalPerShare,
    );

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

    MemberStatus parseStatus(dynamic value) {
      if (value is String) {
        final lower = value.toLowerCase().trim();
        if (lower == 'inactive' || lower == 'in_active') {
          return MemberStatus.inactive;
        }
      }
      return MemberStatus.active;
    }

    final id = json['uid']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['fullName']?.toString() ?? json['name']?.toString() ?? '';
    final phone = json['phone']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    final role = json['role']?.toString() ?? 'MEMBER';
    final memberCode = json['memberCode']?.toString() ?? id;

    return Member(
      id: id,
      groupId: json['groupId']?.toString() ?? '',
      name: name,
      phone: phone,
      email: email,
      role: role,
      memberCode: memberCode,

      joinDate: parseDate(json['joinDate']),

      shares: parsedShares,

      monthlyContributionPerShare:
      finalPerShare,

      monthlyContribution:
      finalMonthly,

      status: parseStatus(json['status']),

      createdAt:
      parseDate(json['createdAt']),

      updatedAt:
      parseDate(json['updatedAt']),
    );
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------

  Member copyWith({
    String? name,
    String? phone,
    int? shares,
    double? monthlyContributionPerShare,
    double? monthlyContribution,
    MemberStatus? status,
    DateTime? updatedAt,
  }) {
    final int newShares =
    _normalizeShares(shares ?? this.shares);

    // Priority:
    //
    // 1. Explicit per-share amount
    // 2. Explicit total monthly amount -> derive per-share
    // 3. Existing per-share amount
    //
    // This ensures:
    //
    // shares = 4
    // per share = ₹1000
    // total = ₹4000
    //
    // If shares change from 4 -> 5:
    // total automatically becomes ₹5000.
    final double newPerShare;

    if (monthlyContributionPerShare != null) {
      if (!monthlyContributionPerShare.isFinite ||
          monthlyContributionPerShare < 0) {
        throw ArgumentError(
          'Monthly contribution per share must be a valid non-negative amount.',
        );
      }

      newPerShare =
          monthlyContributionPerShare;
    } else if (monthlyContribution != null) {
      if (!monthlyContribution.isFinite ||
          monthlyContribution < 0) {
        throw ArgumentError(
          'Monthly contribution must be a valid non-negative amount.',
        );
      }

      newPerShare =
          monthlyContribution / newShares;
    } else {
      newPerShare =
          this.monthlyContributionPerShare;
    }

    final double newTotal =
    _calculateTotal(
      shares: newShares,
      perShare: newPerShare,
    );

    return Member(
      id: id,
      groupId: groupId,

      name: name ?? this.name,
      phone: phone ?? this.phone,

      joinDate: joinDate,

      shares: newShares,

      monthlyContributionPerShare:
      newPerShare,

      monthlyContribution:
      newTotal,

      status: status ?? this.status,

      createdAt: createdAt,

      updatedAt:
      updatedAt ?? DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------------------------

  void validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError(
        'Member ID cannot be empty.',
      );
    }

    if (groupId.trim().isEmpty) {
      throw ArgumentError(
        'Group ID cannot be empty.',
      );
    }

    if (name.trim().isEmpty) {
      throw ArgumentError(
        'Member name cannot be empty.',
      );
    }

    if (shares < 1) {
      throw ArgumentError(
        'Shares must be at least 1.',
      );
    }

    if (!monthlyContributionPerShare.isFinite ||
        monthlyContributionPerShare < 0) {
      throw ArgumentError(
        'Monthly contribution per share must be a valid non-negative amount.',
      );
    }

    final expectedTotal =
        shares * monthlyContributionPerShare;

    if (!monthlyContribution.isFinite ||
        monthlyContribution < 0) {
      throw ArgumentError(
        'Monthly contribution must be a valid non-negative amount.',
      );
    }

    if ((monthlyContribution - expectedTotal).abs() >
        0.01) {
      throw ArgumentError(
        'Monthly contribution must equal '
            'shares × monthly contribution per share.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DEBUG / DISPLAY
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'Member('
        'name: $name, '
        'shares: $shares, '
        'perShare: ₹${monthlyContributionPerShare.toStringAsFixed(2)}, '
        'monthlyHafta: ₹${monthlyContribution.toStringAsFixed(2)}'
        ')';
  }
}