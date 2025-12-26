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
import 'package:my_finance/api/api_util.dart';
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
      url: "http://localhost:3004/my", 
      onSuccess: (response) {
        // response.data [ {id, name, ownerName, memberNames: []}, ... ]
        // Map sang Model Group
        // Model Group: id, name, number, members
        // API Return: _id (mongodb?), name, ownerName, memberNames
        
        try {
          final List<dynamic> data = response.data;
          final List<Group> fetchedGroups = data.map((item) {
            
            // Xử lý members
            List<Member> groupMembers = [];
            String? currentMemberName;
            int joinedCount = 0;
            int totalCount = 0;

            if (item["members"] != null) {
              final List<dynamic> membersData = item["members"];
              totalCount = membersData.length;
              
              for (var m in membersData) {
                final member = Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {});
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

            return Group(
              id: (item["id"] ?? item["groupId"] ?? "").toString(), 
              name: (item["name"] ?? "No Name").toString(), 
              code: (item["code"] ?? "").toString(),
              number: joinedCount, 
              totalMembers: totalCount,
              members: groupMembers,
              memberName: currentMemberName,
            );
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

  void _navigateToGroupDetail(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionGroupPage(group: group),
      ),
    );
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
              child: Text(
                "Tham gia nhóm", 
                style: AppStyles.linkText16_500,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _groups.isEmpty
                      ? Center(
                          child: Text(
                            'Create your group now',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
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
                  Text(
                    "Code: ${group.code}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(BootstrapIcons.people_fill),
              SizedBox(width: 10,),
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
            side: const BorderSide( // 🔹 Thêm viền ngoài
          color: Colors.black12, // Màu viền
          width: 1,              // Độ dày
        ),
          ),
          elevation: 4, // Độ đổ bóng tương tự BoxShadow blurRadius: 4
          shadowColor: Colors.black12, // Màu bóng
          
        ),

      child: Text(
        'Thêm nhóm',
        style: AppStyles.titleText16_500
      ),
    );
  }
}