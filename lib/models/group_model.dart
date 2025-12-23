import 'package:my_finance/models/member_model.dart';

class Group {
  final String id;
  final String name;
  final int number; // số lượng thành viên đã tham gia (joinedMemberCount)
  final int totalMembers; // tổng số lượng thành viên (memberCount)
  final List<Member> members; // danh sách thành viên

  final String code; // Mã nhóm
  final String? memberName; // Tên của chính người dùng hiện tại trong nhóm này

  Group({
    required this.id,
    required this.name,
    this.code = "", // default
    required this.number,
    this.totalMembers = 0, 
    required this.members,
    this.memberName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'members': members,
      'memberName': memberName,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      members: (json['members'] as List).map((m) => Member.fromJson(m)).toList(),
      memberName: json['memberName'],
    );
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, number: $number, members: $members}';
  }
}
