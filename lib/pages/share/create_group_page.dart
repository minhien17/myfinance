import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  // Trạng thái
  final TextEditingController _groupNameController = TextEditingController();
  // Khởi tạo số lượng thành viên (ví dụ: mặc định là 3 như trong ảnh)
  int _memberCount = 3; 

  String username = '';
  
  // List chứa Controllers cho Tên thành viên
  final List<TextEditingController> _memberControllers = [];

  @override
  void initState() {
    super.initState();
    // Khởi tạo controllers cho số lượng mặc định
    _initializeMemberControllers(_memberCount); 
    _loadUsername();
  }

    Future<void> _loadUsername() async {
    final usernametam = await SharedPreferenceUtil.getUsername();
    if (mounted) {
      setState(() {
        username = usernametam;
      });
    }
  }


  // Hàm khởi tạo/cập nhật danh sách TextEditingController
  void _initializeMemberControllers(int count) {
    // Đảm bảo list controllers có đúng số lượng cần thiết
    while (_memberControllers.length < count) {
      // Thêm controller mới nếu thiếu
      _memberControllers.add(TextEditingController());
    }
    while (_memberControllers.length > count) {
      // Xóa và dispose controller thừa
      _memberControllers.removeLast().dispose();
    }
  }
  
  // Xử lý khi số lượng thành viên thay đổi
  void _onMemberCountChanged(int? newCount) {
    if (newCount != null && newCount >= 2 && newCount <= 8) { // Giới hạn từ 2 đến 10
      setState(() {
        _memberCount = newCount;
        _initializeMemberControllers(newCount);
      });
    }
  }

  // Xử lý khi nhấn nút Create
  void _createGroup() {
    final groupName = _groupNameController.text;
    // final members = _memberControllers.map((c) => c.text).toList();
    
    // 💡 Lấy thông tin thành viên (Giả sử Hiển (you) là thành viên đầu tiên)
    List<String> memberNames = [username];
    for(int i = 0; i < _memberControllers.length; i++) {
      if (_memberControllers[i].text.isNotEmpty) {
        memberNames.add(_memberControllers[i].text);
      }
    }

    print(memberNames);

    if(groupName.isEmpty){
      toastInfo(msg: "Fill in the name of group");
      return;
    }

    if(memberNames.length != _memberCount){
      toastInfo(msg: "Fill in the name of members");
      return;
    }
    
    print('Tên nhóm: $groupName');
    print('Số lượng: $_memberCount');
    print('Thành viên: $memberNames');

    // Gọi API
    _callApi(context, groupName, memberNames);
    
  }

  Future<void> _callApi(BuildContext context, String groupName, List<String> memberNames) async {
    showLoading(context);

    // Chuẩn bị body theo DTO
    // dto.name, dto.ownerName, dto.memberNames
    // Giả sử ownerName là username hiện tại (đã có trong biến username hoặc memberNames[0])
    
    // memberNames bao gồm cả owner, nhưng DTO có vẻ tách ownerName và memberNames?
    // Dựa vào code NestJS: createGroup(userId, dto.name, dto.ownerName, dto.memberNames)
    // Thì memberNames trong DTO là danh sách các thành viên KHÁC owner? Hay tất cả?
    // Thường thì backend sẽ handle việc add owner vào group. 
    // Tuy nhiên theo prompt "dto.memberNames.map((x) => x.trim())", user truyền lên list tên.
    
    // Ở UI _createGroup logic: memberNames include cả username.
    // Hãy gửi tách biệt để an toàn hoặc gửi tất cả tùy logic backend.
    // Với "dto.ownerName", ta gửi username.
    // Với "dto.memberNames", ta gửi danh sách thành viên (có thể bao gồm hoặc không bao gồm owner, 
    // nhưng để chắc chắn ta gửi list các tên thành viên khác).
    
    // Tuy nhiên, logic UI hiện tại gộp chung. 
    // Hãy giả định memberNames gửi lên là danh sách tên các thành viên (không bao gồm owner nếu backend đã có ownerName).
    
    List<String> membersOnly = List.from(memberNames);
    if (membersOnly.contains(username)) {
      membersOnly.remove(username);
    }

    final body = {
      "name": groupName,
      "ownerName": username,
      "memberNames": membersOnly 
    };

    final completer = Completer<void>();
    
    ApiUtil.getInstance()!.post(
      url: "http://localhost:3004/", 
      body: body,
      onSuccess: (response) {
        print("✅ Create group success: ${response.data}");
        completer.complete();
        toastInfo(msg: "Tạo nhóm thành công!");
      },
      onError: (error) {
        print("❌ Create group error: $error");
        completer.completeError(error);
        toastInfo(msg: "Lỗi tạo nhóm: $error");
      },
    );

    try {
      await completer.future;
      if (context.mounted) {
        Navigator.pop(context); // Đóng màn hình tạo nhóm
      }
    } catch (e) {
      // Error handled in onError via toast
    } finally {
      if (context.mounted) {
        hideLoading();
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (var controller in _memberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tạo nhóm mới',
          // style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        
        child: Container(
          padding: const EdgeInsets.only(left:10, right: 10, top: 20, bottom: 20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tên nhóm
              _buildInfoRow('Tên nhóm', TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Điền tên',
                  hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300), // Màu mờ cho chữ "Điền tên"
                  border: InputBorder.none,
                ),
                style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 16),
              )),
              const SizedBox(height: 15),
          
              // 2. Số lượng thành viên (Dùng Dropdown cho dễ chọn)
              _buildInfoRow('Số lượng', _buildMemberCountSelector()),
              const SizedBox(height: 25),
          
              // tên mình
                    Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    "Tên của bạn",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 43,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextField(
                      controller: TextEditingController(text: username),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12, // 🔹 Điều chỉnh khoảng cách dọc để canh giữa
                          horizontal: 10,
                        ),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        setState(() {
                          username = value;
                        });
                      },
                    ),
                  ),
                ),
                
              ],
            ), 
            const SizedBox(height: 15),
          
              // 3. Danh sách TextField để điền tên thành viên
              ..._buildMemberInputFields(),
          
              const SizedBox(height: 40),
          
              // 4. Nút Create
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  // --- WIDGET CON ---

  // Xây dựng hàng thông tin (Label: Input)
  Widget _buildInfoRow(String label, Widget inputWidget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: inputWidget is TextField 
              ? Container( // Bọc TextField trong Container màu xám
                  height: 43,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: inputWidget,
                )
              : inputWidget, // Cho DropdownButton
        ),
      ],
    );
  }

  // Dropdown chọn số lượng thành viên
  Widget _buildMemberCountSelector() {
    return DropdownButton<int>(
      value: _memberCount,
      icon: const SizedBox(), // Ẩn icon mặc định
      elevation: 0,
      underline: const SizedBox(), // Ẩn gạch chân
      items: List.generate(8, (index) => index + 1) // Tạo list [2, 3, ..., 10]
          .map((int count) {
        return DropdownMenuItem<int>(
          value: count,
          child: Text(
            count.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
      onChanged: _onMemberCountChanged,
    );
  }

  // Xây dựng danh sách TextField cho thành viên
  List<Widget> _buildMemberInputFields() {
    return List.generate(_memberCount - 1, (index) {
      String label = 'Thành viên ${index + 2}';
      String initialName = ''; // Tên mặc định

      // Đặt tên mặc định cho controller
      if (_memberControllers[index].text.isEmpty) {
        _memberControllers[index].text = initialName;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: _buildInfoRow(
          label,
          TextField(
            controller: _memberControllers[index],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 12, // 🔹 Điều chỉnh khoảng cách dọc để canh giữa
                horizontal: 10,
              ),
            ),
            // In đậm chữ như trong ảnh
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center, // Canh giữa chữ trong ô xám
          ),
        ),
      );
    });
  }

  // Nút Create (Màu xanh lá)
  Widget _buildCreateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _createGroup,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300], // Màu xám nhạt tương đồng với ảnh
          minimumSize: const Size(200, 45), // Kích thước cố định (tương tự ảnh)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Tạo mới',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

}

