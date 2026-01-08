import 'package:flutter/material.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/services/websocket_service.dart';

class ViewMembersPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<Member> members;
  final String currentUserId;
  final String? ownerId;

  const ViewMembersPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.currentUserId,
    this.ownerId,
  });

  @override
  State<ViewMembersPage> createState() => _ViewMembersPageState();
}

class _ViewMembersPageState extends State<ViewMembersPage> {
  late List<Member> _members;
  late String? _ownerId;

  // 🔌 WebSocket service
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.members);
    _ownerId = widget.ownerId;
    print("🔍 ViewMembersPage - initState with ${_members.length} members, ownerId: ${widget.ownerId}");
    _setupWebSocket();
  }

  // 🔌 WebSocket: Setup listeners
  void _setupWebSocket() {
    _wsService.connect();
    _wsService.joinGroupRoom(widget.groupId, userId: widget.currentUserId);

    // Khi có member mới tham gia
    _wsService.onMemberJoined = (data) {
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.groupId) return;

      print('🔌 WS ViewMembers: Member joined');
      _fetchMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên mới'} đã tham gia', Colors.green);
    };

    // Khi member rời nhóm
    _wsService.onMemberLeft = (data) {
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.groupId) return;

      print('🔌 WS ViewMembers: Member left');
      _fetchMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên'} đã rời nhóm', Colors.orange);
    };

    // Khi member được thêm vào
    _wsService.onMemberAdded = (data) {
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.groupId) return;

      print('🔌 WS ViewMembers: Member added');
      _fetchMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên mới'} được thêm vào nhóm', Colors.green);
    };

    // Khi member bị xóa
    _wsService.onMemberRemoved = (data) {
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.groupId) return;

      print('🔌 WS ViewMembers: Member removed');
      _fetchMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên'} đã bị xóa', Colors.orange);
    };

    // Khi quyền sở hữu được chuyển
    _wsService.onOwnershipTransferred = (data) {
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.groupId) return;

      print('🔌 WS ViewMembers: Ownership transferred');
      setState(() {
        _ownerId = data['newOwnerUserId']?.toString();
      });
      _fetchMembers();
      _showSnackBar('Quyền trưởng nhóm đã chuyển cho ${data['newOwnerName'] ?? 'thành viên khác'}', Colors.amber);
    };

    // Khi nhóm bị xóa
    _wsService.onGroupDeleted = (data) {
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.groupId) return;

      print('🔌 WS ViewMembers: Group deleted');
      _showSnackBar('Nhóm đã bị xóa', Colors.red);
      Navigator.pop(context, true);
      Navigator.pop(context, true);
    };
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Fetch members từ API
  void _fetchMembers() {
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupMy,
      onSuccess: (response) {
        if (!mounted) return;

        final List<dynamic> groups = response.data ?? [];
        final currentGroup = groups.firstWhere(
          (g) => (g['id'] ?? g['groupId'])?.toString() == widget.groupId,
          orElse: () => null,
        );

        if (currentGroup != null && currentGroup['members'] != null) {
          final List<dynamic> membersData = currentGroup['members'];
          setState(() {
            _members = membersData.map((m) {
              return Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {});
            }).toList();
            // Cập nhật ownerId nếu có
            final newOwnerId = (currentGroup['ownerId'] ?? currentGroup['ownerUserId'])?.toString();
            if (newOwnerId != null) {
              _ownerId = newOwnerId;
            }
          });
        }
      },
      onError: (error) {
        print('❌ Error fetching members: $error');
      },
    );
  }

  @override
  void dispose() {
    _wsService.leaveGroupRoom(widget.groupId);
    _wsService.clearGroupCallbacks(); // Không xóa onAddedToGroup
    super.dispose();
  }

  void _showLeaveGroupDialog() {
    final isOwner = widget.currentUserId == _ownerId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Rời nhóm'),
          ],
        ),
        content: Text(
          isOwner
              ? 'Bạn là trưởng nhóm. Nếu rời nhóm, nhóm sẽ bị xóa hoặc cần chuyển quyền cho người khác. Bạn có chắc chắn muốn rời nhóm?'
              : 'Bạn có chắc chắn muốn rời khỏi nhóm "${widget.groupName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Rời nhóm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    showLoading(context);

    ApiUtil.getInstance()!.delete(
      url: ApiEndpoint.groupLeave(widget.groupId),
      onSuccess: (response) {
        hideLoading();

        final data = response.data;
        final bool deleted = data['deleted'] == true;
        final bool transferred = data['transferred'] == true;
        final String? newOwnerName = data['newOwnerName'];

        String message;
        if (deleted) {
          message = 'Nhóm đã bị xoá (không còn thành viên)';
        } else if (transferred) {
          message = 'Đã rời nhóm. Quyền trưởng nhóm chuyển cho $newOwnerName';
        } else {
          message = 'Đã rời khỏi nhóm "${widget.groupName}"';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Pop 2 lần: ViewMembersPage -> TransactionGroupPage -> SharePage
        Navigator.of(context).pop(true); // Pop ViewMembersPage
        Navigator.of(context).pop(true); // Pop TransactionGroupPage
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $error')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  // 🗑️ Xóa thành viên (chỉ trưởng nhóm)
  void _showRemoveMemberDialog(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_remove, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Xóa thành viên'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${member.name}" khỏi nhóm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removeMember(Member member) {
    showLoading(context);

    // Dùng DELETE method để xóa thành viên
    ApiUtil.getInstance()!.delete(
      url: ApiEndpoint.groupRemoveMember(widget.groupId, member.id),
      onSuccess: (response) {
        hideLoading();

        // Cập nhật danh sách local
        setState(() {
          _members.removeWhere((m) => m.id == member.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Đã xóa "${member.name}" khỏi nhóm')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $error')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final joinedCount = _members.where((m) => m.joined).length;
    final isCurrentUserOwner = widget.currentUserId == _ownerId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Thành viên - ${widget.groupName}'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Nút rời nhóm
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red.shade600),
            tooltip: 'Rời nhóm',
            onPressed: _showLeaveGroupDialog,
          ),
        ],
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
                  '$joinedCount/${_members.length}',
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
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final isCurrentUser = member.userId == widget.currentUserId;
                final isOwner = member.userId != null && member.userId == _ownerId;
                final displayName = isCurrentUser
                    ? '${member.name} (bạn)'
                    : member.name;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isOwner ? Border.all(color: Colors.amber.shade400, width: 2) : null,
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
                    leading: Stack(
                      children: [
                        CircleAvatar(
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
                        if (isOwner)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: isOwner
                        ? Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium, size: 12, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Trưởng nhóm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
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
                        // Nút xóa thành viên (chỉ hiện cho trưởng nhóm, không xóa chính mình và trưởng nhóm)
                        if (isCurrentUserOwner && !isCurrentUser && !isOwner)
                          IconButton(
                            icon: Icon(Icons.person_remove, color: Colors.red.shade400, size: 20),
                            tooltip: 'Xóa thành viên',
                            onPressed: () => _showRemoveMemberDialog(member),
                          ),
                      ],
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
