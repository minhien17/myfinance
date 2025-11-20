import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/pages/share/child_page/transation_group_page.dart';
import 'package:my_finance/pages/share/create_group_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/res/app_styles.dart';


class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {

  @override
void initState() {
  super.initState();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // làm trong suốt
      statusBarIconBrightness: Brightness.light, // icon trắng
      statusBarBrightness: Brightness.dark, // iOS
    ),
  );
}

  // Dữ liệu mô phỏng từ API/Database
  // Khởi tạo với một vài nhóm để hiển thị
  List<Group> _groups = [
    Group(id: "", name: "Trọ", number: 3, members: ["Hiển", "Đạt", "Trọng"]),
  ];
  
  // Bạn có thể thêm biến _isLoading = false; nếu muốn quản lý trạng thái API
  // Future<void> _fetchGroups() async { ... }

  void _addGroup() {
    
    print("Mở màn hình tạo nhóm mới...");
    Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupPage()),
              );
  }

  void _navigateToGroupDetail(Group group) {
    // Logic khi nhấn vào một nhóm
    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionGroupPage(name: group.name,),
                    ),
                  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Nền trắng tương đồng
      appBar: AppBar(
        title: const Text(
          'Share money',
          // style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.background,
        elevation: 0, // Không có bóng dưới AppBar
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroupPage()),
              );
            },
              child: Text("Join group", 
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
            // 1. Danh sách các nhóm (hoặc Placeholder nếu rỗng)
            Expanded(
              child: _groups.isEmpty
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

            // 2. Nút "Add group"
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
              Text(
                group.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Spacer(),
              Icon(BootstrapIcons.people_fill),
              SizedBox(width: 10,),
              Text(
                "${group.number}",
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
        'Add group',
        style: AppStyles.titleText16_500
      ),
    );
  }
}