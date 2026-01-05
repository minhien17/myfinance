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
    // Convert id to string - API có thể trả về number hoặc string
    String memberId = '';
    if (json['id'] != null) {
      memberId = json['id'].toString();
    } else if (json['_id'] != null) {
      memberId = json['_id'].toString();
    }

    return Member(
      id: memberId,
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
