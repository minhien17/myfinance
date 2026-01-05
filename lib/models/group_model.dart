import 'package:my_finance/models/member_model.dart';

class Group {
  final String id;
  final String name;
  final int number; // số lượng thành viên đã tham gia (joinedMemberCount)
  final int totalMembers; // tổng số lượng thành viên (memberCount)
  final List<Member> members; // danh sách thành viên

  final String code; // Mã nhóm
  final String? memberName; // Tên của chính người dùng hiện tại trong nhóm này
  final String? ownerId; // userId của trưởng nhóm (người tạo nhóm)

  Group({
    required this.id,
    required this.name,
    this.code = "", // default
    required this.number,
    this.totalMembers = 0,
    required this.members,
    this.memberName,
    this.ownerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'members': members,
      'memberName': memberName,
      'ownerId': ownerId,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    List<Member> membersList = [];
    if (json['members'] != null && json['members'] is List) {
      membersList = (json['members'] as List)
          .map((m) => Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {}))
          .toList();
    }

    return Group(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      code: json['code']?.toString() ?? '',
      number: json['number'] ?? json['joinedMemberCount'] ?? 0,
      totalMembers: json['totalMembers'] ?? json['memberCount'] ?? membersList.length,
      members: membersList,
      memberName: json['memberName'],
      ownerId: json['ownerId']?.toString() ?? json['ownerUserId']?.toString() ?? json['createdByUserId']?.toString(),
    );
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, number: $number, members: $members}';
  }
}
