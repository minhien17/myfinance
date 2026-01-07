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
// import 'package:my_finance/api/sse_service.dart';  // SSE disabled temporarily
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
  String username = "";
  String currentUserId = "";

  // 🔄 Polling timer for real-time updates
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 10);

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
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // 🔄 Polling: Start periodic refresh
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted) {
        print('🔄 Polling: Refreshing groups list...');
        _fetchGroupsSilent();
      }
    });
    print('🔄 Polling: Started with interval ${_pollingInterval.inSeconds}s');
  }

  // 🔄 Polling: Stop periodic refresh
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('🔄 Polling: Stopped');
  }

  // 🔄 Fetch groups without showing loading indicator (for polling)
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
            print('🔄 Polling: Groups updated');
            setState(() {
              _groups = fetchedGroups;
            });
          }
        } catch (e) {
          print("🔄 Polling error: $e");
        }
      },
      onError: (error) {
        print("🔄 Polling error: $error");
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
    await _fetchGroups();
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

  void _navigateToGroupDetail(Group group) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionGroupPage(group: group),
      ),
    );
    // Nếu result = true (rời nhóm), reload danh sách
    if (result == true) {
      _fetchGroups();
    }
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
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _groups.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
                            child: Text(
                              'Bạn chưa có nhóm nào.\nNhấn "Thêm nhóm" để tạo hoặc tham gia nhóm.',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          return _buildGroupItem(_groups[index]);
                        },
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
