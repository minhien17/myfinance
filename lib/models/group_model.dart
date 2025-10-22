class Group {
  final String id;
  final String name;
  final int number; // số lượng thành viên
  final List<String> members; // danh sách tên thành viên

  Group({
    required this.id,
    required this.name,
    required this.number,
    required this.members,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'members': members,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      members: List<String>.from(json['members']),
    );
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, number: $number, members: $members}';
  }
}
