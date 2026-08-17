class BachatGatManager {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String groupId;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;

  BachatGatManager({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.groupId,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'email': email,
        'groupId': groupId,
        'photoUrl': photoUrl,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BachatGatManager.fromJson(Map<String, dynamic> json) => BachatGatManager(
        uid: json['uid'],
        name: json['name'],
        phone: json['phone'],
        email: json['email'],
        groupId: json['groupId'],
        photoUrl: json['photoUrl'],
        isActive: json['isActive'] ?? true,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
