import 'package:flutter/material.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/res/app_colors.dart';

class ViewMembersPage extends StatelessWidget {
  final String groupName;
  final List<Member> members;
  final String currentUserId;

  const ViewMembersPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Đếm số thành viên đã tham gia
    final joinedCount = members.where((m) => m.joined).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thành viên - $groupName'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header thống kê
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Tổng số thành viên',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$joinedCount/${members.length}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$joinedCount người đã tham gia',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Danh sách thành viên
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isCurrentUser = member.userId == currentUserId;
                final displayName = isCurrentUser
                    ? '${member.name} (bạn)'
                    : member.name;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: member.joined
                          ? AppColors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: member.joined ? AppColors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: (member.userId?.isNotEmpty ?? false)
                        ? Text(
                            'ID: ${member.userId!.substring(0, member.userId!.length > 8 ? 8 : member.userId!.length)}...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: member.joined
                            ? AppColors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member.joined ? 'Đã tham gia' : 'Chờ tham gia',
                        style: TextStyle(
                          color: member.joined ? AppColors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
