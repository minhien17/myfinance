import 'dart:async';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/pages/share/child_page/transation_group_page.dart';
import 'package:my_finance/pages/share/create_group_page.dart';
import 'package:my_finance/pages/share/join_group_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/res/app_styles.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/services/websocket_service.dart';
import 'package:my_finance/shared_preference.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  // Biến loading
  bool _isLoading = false;
  // Dữ liệu nhóm
  List<Group> _groups = [];
  // Danh sách lời mời đang chờ
  List<Map<String, dynamic>> _pendingInvitations = [];
  String username = "";
  String currentUserId = "";

  // 🔌 WebSocket service
  final WebSocketService _wsService = WebSocketService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _loadUsernameAndFetchGroups();
  }

  // 🔌 WebSocket: Setup và đăng ký listeners
  void _setupWebSocket() {
    print('🔌 SharePage: Setting up WebSocket...');
    print('🔌 SharePage: currentUserId = $currentUserId');

    _wsService.connect();

    // Join user room để nhận thông báo khi được thêm vào nhóm mới
    if (currentUserId.isNotEmpty) {
      print('🔌 SharePage: Joining user room for userId: $currentUserId');
      _wsService.joinUserRoom(currentUserId);
    } else {
      print('⚠️ SharePage: currentUserId is empty, cannot join user room!');
    }

    // Setup callbacks
    _setupWebSocketCallbacks();
  }

  @override
  void dispose() {
    _wsService.clearCallbacks();
    super.dispose();
  }

  // Fetch groups without showing loading indicator (for WebSocket updates)
  Future<void> _fetchGroupsSilent() async {
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupMy,
      onSuccess: (response) {
        if (!mounted) return;
        try {
          final List<dynamic> data = response.data;
          final List<Group> fetchedGroups = _parseGroups(data);

          // Only update if data changed
          if (_hasGroupsChanged(fetchedGroups)) {
            print('🔌 WebSocket: Groups updated');
            setState(() {
              _groups = fetchedGroups;
            });
          }
        } catch (e) {
          print("🔌 WebSocket fetch error: $e");
        }
      },
      onError: (error) {
        print("🔌 WebSocket fetch error: $error");
      },
    );
  }

  // Check if groups list has changed
  bool _hasGroupsChanged(List<Group> newGroups) {
    if (_groups.length != newGroups.length) return true;
    for (int i = 0; i < _groups.length; i++) {
      if (_groups[i].id != newGroups[i].id ||
          _groups[i].name != newGroups[i].name ||
          _groups[i].number != newGroups[i].number ||
          _groups[i].totalMembers != newGroups[i].totalMembers) {
        return true;
      }
    }
    return false;
  }

  // Parse groups from API response
  List<Group> _parseGroups(List<dynamic> data) {
    return data.map((item) {
      List<Member> groupMembers = [];
      String? currentMemberName;
      int joinedCount = 0;
      int totalCount = 0;

      if (item["members"] != null) {
        final List<dynamic> membersData = item["members"];
        totalCount = membersData.length;

        for (var m in membersData) {
          final member = Member.fromJson(
            m is Map ? Map<String, dynamic>.from(m) : {},
          );
          groupMembers.add(member);

          if (member.joined) {
            joinedCount++;
            if (member.userId != null && member.userId == currentUserId) {
              currentMemberName = member.name;
            }
          }
        }
      } else {
        joinedCount = item["joinedMemberCount"] ?? 0;
        totalCount = item["memberCount"] ?? 0;
      }

      return Group(
        id: (item["id"] ?? item["groupId"] ?? "").toString(),
        name: (item["name"] ?? "No Name").toString(),
        code: (item["code"] ?? "").toString(),
        number: joinedCount,
        totalMembers: totalCount,
        members: groupMembers,
        memberName: currentMemberName,
        ownerId: (item["ownerId"] ?? item["ownerUserId"] ?? item["createdByUserId"])?.toString(),
      );
    }).toList();
  }

  Future<void> _loadUsernameAndFetchGroups() async {
    username = await SharedPreferenceUtil.getUsername();
    currentUserId = await SharedPreferenceUtil.getUserId();
    _setupWebSocket(); // Setup WebSocket sau khi có userId
    await _fetchGroups();
    await _fetchPendingInvitations();
  }

  // Lấy danh sách lời mời đang chờ
  Future<void> _fetchPendingInvitations() async {
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupInvitationsMy,
      onSuccess: (response) {
        if (!mounted) return;
        try {
          final List<dynamic> data = response.data ?? [];
          setState(() {
            _pendingInvitations = data.map((item) => Map<String, dynamic>.from(item)).toList();
          });
          print('📨 Fetched ${_pendingInvitations.length} pending invitations');
          // Log cấu trúc dữ liệu để debug
          for (var inv in _pendingInvitations) {
            print('📨 Invitation data: $inv');
          }
        } catch (e) {
          print('Error parsing pending invitations: $e');
        }
      },
      onError: (error) {
        print('Error fetching pending invitations: $error');
      },
    );
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });

    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupMy,
      onSuccess: (response) {
        // response.data [ {id, name, ownerName, memberNames: []}, ... ]
        // Map sang Model Group
        // Model Group: id, name, number, members
        // API Return: _id (mongodb?), name, ownerName, memberNames

        try {
          final List<dynamic> data = response.data;
          print("🔍 SharePage - API /my returned ${data.length} groups");

          final List<Group> fetchedGroups = data.map((item) {
            print("🔍 SharePage - Processing group: ${item['name']}");
            print(
              "📋 SharePage - Group data has members? ${item['members'] != null}",
            );
            if (item["members"] != null) {
              print(
                "📋 SharePage - Members count in API response: ${(item['members'] as List).length}",
              );
            }

            // Xử lý members
            List<Member> groupMembers = [];
            String? currentMemberName;
            int joinedCount = 0;
            int totalCount = 0;

            if (item["members"] != null) {
              final List<dynamic> membersData = item["members"];
              totalCount = membersData.length;

              for (var m in membersData) {
                final member = Member.fromJson(
                  m is Map ? Map<String, dynamic>.from(m) : {},
                );
                groupMembers.add(member);

                if (member.joined) {
                  joinedCount++;
                  // Nhận diện mình dựa trên userId
                  if (member.userId != null && member.userId == currentUserId) {
                    currentMemberName = member.name;
                  }
                }
              }
            } else {
              // Fallback
              joinedCount = item["joinedMemberCount"] ?? 0;
              totalCount = item["memberCount"] ?? 0;
            }

            final group = Group(
              id: (item["id"] ?? item["groupId"] ?? "").toString(),
              name: (item["name"] ?? "No Name").toString(),
              code: (item["code"] ?? "").toString(),
              number: joinedCount,
              totalMembers: totalCount,
              members: groupMembers,
              memberName: currentMemberName,
              ownerId: (item["ownerId"] ?? item["ownerUserId"] ?? item["createdByUserId"])?.toString(),
            );

            print(
              "🔍 SharePage - Created group: ${group.name} with ${group.members.length} members, ownerId: ${group.ownerId}",
            );
            print("🔍 SharePage - Raw ownerId fields: ownerId=${item['ownerId']}, ownerUserId=${item['ownerUserId']}, createdByUserId=${item['createdByUserId']}");

            return group;
          }).toList();

          setState(() {
            _groups = fetchedGroups;
            _isLoading = false;
          });
        } catch (e) {
          print("Error parsing groups: $e");
          setState(() {
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        print("Error fetching groups: $error");
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  void _addGroup() async {
    print("Mở màn hình tạo nhóm mới...");
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateGroupPage()),
    );
    // Sau khi tạo xong và back về, reload lại list
    _fetchGroups();
  }

  // Hiển thị dialog lời mời vào nhóm
  void _showInvitationDialog(Map<String, dynamic> data) {
    final invitationId = data['invitationId']?.toString() ?? '';
    final groupName = data['groupName']?.toString() ?? 'Unknown';
    // Backend gửi field 'invitedByMemberName'
    final inviterName = data['invitedByMemberName']?.toString() ?? data['inviterName']?.toString() ?? 'Someone';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Lời mời tham gia nhóm'),
          content: Text('$inviterName đã mời bạn tham gia nhóm "$groupName"'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _rejectInvitation(invitationId, groupName: groupName);
              },
              child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _acceptInvitation(invitationId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
              ),
              child: const Text('Chấp nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Chấp nhận lời mời
  void _acceptInvitation(String invitationId) {
    if (invitationId.isEmpty) return;

    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.groupInvitationAccept(invitationId),
      body: {},
      onSuccess: (response) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận lời mời'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchGroups();
        _fetchPendingInvitations();
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  // Từ chối lời mời
  void _rejectInvitation(String invitationId, {String? groupName}) {
    if (invitationId.isEmpty) return;

    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.groupInvitationReject(invitationId),
      body: {},
      onSuccess: (response) {
        if (!mounted) return;
        _fetchPendingInvitations();
        _showRejectSuccessDialog(groupName);
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: ${error.toString()}')),
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

  // Dialog hiển thị khi từ chối lời mời thành công
  void _showRejectSuccessDialog(String? groupName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Tự động đóng dialog sau 2 giây
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.orange.shade600,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                // Tiêu đề
                const Text(
                  'Đã từ chối lời mời',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Nội dung
                Text(
                  groupName != null
                      ? 'Bạn đã từ chối tham gia nhóm "$groupName"'
                      : 'Lời mời đã được từ chối',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToGroupDetail(Group group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionGroupPage(group: group),
      ),
    );
    // Re-setup callbacks sau khi quay về từ page con
    _setupWebSocketCallbacks();
    // Luôn refresh data khi quay về (có thể có thay đổi member count)
    _fetchGroupsSilent();
    // Nếu result = true (rời nhóm), reload với loading indicator
    if (result == true) {
      _fetchGroups();
    }
  }

  // Setup lại callbacks (dùng khi quay về từ page con)
  void _setupWebSocketCallbacks() {
    // Khi user được thêm vào nhóm mới
    _wsService.onAddedToGroup = (data) {
      print('🔌 WS SharePage: ✅ Added to group event received! - $data');
      _fetchGroupsSilent();
    };

    // Khi có member mới tham gia nhóm
    _wsService.onMemberJoined = (data) {
      print('🔌 WS SharePage: Member joined - $data');
      _fetchGroupsSilent();
    };

    // Khi member rời nhóm
    _wsService.onMemberLeft = (data) {
      print('🔌 WS SharePage: Member left - $data');
      _fetchGroupsSilent();
    };

    // Khi member được thêm vào nhóm
    _wsService.onMemberAdded = (data) {
      print('🔌 WS SharePage: Member added - $data');
      _fetchGroupsSilent();
    };

    // Khi member bị xóa khỏi nhóm
    _wsService.onMemberRemoved = (data) {
      print('🔌 WS SharePage: Member removed - $data');
      _fetchGroupsSilent();
    };

    // Khi nhóm bị xóa
    _wsService.onGroupDeleted = (data) {
      print('🔌 WS SharePage: Group deleted - $data');
      _fetchGroupsSilent();
    };

    // Khi quyền sở hữu được chuyển
    _wsService.onOwnershipTransferred = (data) {
      print('🔌 WS SharePage: Ownership transferred - $data');
      _fetchGroupsSilent();
    };

    // ========== INVITATION EVENTS ==========

    // Khi nhận được lời mời vào nhóm
    _wsService.onGroupInvitation = (data) {
      print('🔌 WS SharePage: Group invitation received - $data');
      _fetchPendingInvitations();
      if (mounted) {
        _showInvitationDialog(data);
      }
    };

    // Khi lời mời bị hủy
    _wsService.onInvitationCancelled = (data) {
      print('🔌 WS SharePage: Invitation cancelled - $data');
      _fetchPendingInvitations();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lời mời vào nhóm "${data['groupName'] ?? 'Unknown'}" đã bị hủy'),
          backgroundColor: Colors.orange,
        ),
      );
    };

    // Khi lời mời được chấp nhận (cho owner)
    _wsService.onInvitationAccepted = (data) {
      print('🔌 WS SharePage: Invitation accepted - $data');
      _fetchGroupsSilent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['userName'] ?? 'User'} đã chấp nhận lời mời'),
          backgroundColor: Colors.green,
        ),
      );
    };

    // Khi lời mời bị từ chối (cho owner)
    _wsService.onInvitationRejected = (data) {
      print('🔌 WS SharePage: Invitation rejected - $data');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['userName'] ?? 'User'} đã từ chối lời mời'),
          backgroundColor: Colors.red,
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách nhóm'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JoinGroupScreen()),
                );
                _fetchGroups();
              },
              child: Text("Tham gia", style: AppStyles.linkText16_500),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGroups();
          await _fetchPendingInvitations();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Section lời mời đang chờ
                          if (_pendingInvitations.isNotEmpty) ...[
                            _buildPendingInvitationsSection(),
                            const SizedBox(height: 16),
                          ],
                          // Danh sách nhóm
                          if (_groups.isEmpty && _pendingInvitations.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.25),
                              child: Center(
                                child: Text(
                                  'Bạn chưa có nhóm nào.\nNhấn "Thêm nhóm" để tạo hoặc tham gia nhóm.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ..._groups.map((group) => _buildGroupItem(group)),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              _buildAddGroupButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CON ---

  // Section hiển thị lời mời đang chờ
  Widget _buildPendingInvitationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mail_outline, color: Colors.orange.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Lời mời đang chờ (${_pendingInvitations.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._pendingInvitations.map((invitation) => _buildInvitationItem(invitation)),
      ],
    );
  }

  // Item lời mời
  Widget _buildInvitationItem(Map<String, dynamic> invitation) {
    final invitationId = invitation['id']?.toString() ?? invitation['invitationId']?.toString() ?? '';
    final groupName = invitation['groupName']?.toString() ?? invitation['group']?['name']?.toString() ?? 'Unknown';
    // Backend gửi field 'invitedByMemberName'
    final inviterName = invitation['invitedByMemberName']?.toString()
        ?? invitation['inviterName']?.toString()
        ?? invitation['inviter']?['username']?.toString()
        ?? 'Someone';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.group_add, color: Colors.orange.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Được mời bởi $inviterName',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectInvitation(invitationId, groupName: groupName),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                  child: const Text('Từ chối'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptInvitation(invitationId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Chấp nhận'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupItem(Group group) {
    // Thiết kế tương đồng với các ô màu xám trong ảnh
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: InkWell(
        onTap: () => _navigateToGroupDetail(group),
        child: Container(
          height: 60,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: group.code));
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.white),
                              const SizedBox(width: 12),
                              Text('Đã sao chép mã: ${group.code}'),
                            ],
                          ),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      "Code: ${group.code}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(BootstrapIcons.people_fill),
              SizedBox(width: 10),
              Text(
                "${group.number}/${group.totalMembers}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupButton() {
    // Thiết kế nút tương đồng với các nút màu xanh lá cây khác (SIGN UP, SIGN IN)
    return ElevatedButton(
      onPressed: _addGroup,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Màu nền
        foregroundColor: AppColors.title, // Màu chữ/icon
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            // 🔹 Thêm viền ngoài
            color: Colors.black12, // Màu viền
            width: 1, // Độ dày
          ),
        ),
        elevation: 4, // Độ đổ bóng tương tự BoxShadow blurRadius: 4
        shadowColor: Colors.black12, // Màu bóng
      ),

      child: Text('Thêm nhóm', style: AppStyles.titleText16_500),
    );
  }
}
