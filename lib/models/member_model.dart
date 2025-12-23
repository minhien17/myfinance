class Member {
  final String id;
  final String name;
  final String? userId;
  final bool joined;

  Member({
    required this.id,
    required this.name,
    this.userId,
    this.joined = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      userId: json['userId']?.toString(),
      joined: json['joined'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'joined': joined,
    };
  }
}
