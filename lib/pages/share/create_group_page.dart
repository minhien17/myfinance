import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
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

    // 💡 Logic gọi API để tạo GroupModel
    // Sau khi tạo thành công, thường sẽ Navigator.pop(context);
    // showLoading(context);
    _callApi(context);
    
  }

  Future<void> _callApi(BuildContext context) async {
    showLoading(context);

   // 3. Sử dụng Completer để đợi API hoàn thành
  final completer = Completer<void>();
  // Nếu gọi API
  ApiUtil.getInstance()!.post(
    url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/transaction",
    
    onSuccess: (response) {
      
      print("✅ Add expense success: ${response.data}");
      completer.complete(); 
      
    },
    onError: (error) {
      print("❌ Add expense error: $error");
      completer.completeError(error); 
      Navigator.pop(context); // quay lại màn hình trước
      
    },

  );

  try {
    // 5. ĐỢI API HOÀN THÀNH (Đây là bước QUAN TRỌNG NHẤT)
    await completer.future;

  } catch (e) {
    // Bắt lỗi nếu completer.completeError được gọi
    // Thêm logic thông báo lỗi ở đây (ví dụ: toastInfo)

  } finally {
    // 6. ẨN LOADING (Đảm bảo được gọi trong mọi trường hợp)
    if (context.mounted) {
      hideLoading();
    }
    
    // Tùy chọn: Đóng màn hình hiện tại sau khi hoàn thành
    // if (context.mounted) {
    //   Navigator.of(context).pop(); 
    // }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Create group',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tên nhóm
            _buildInfoRow('Name:', TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'Name of group',
                border: InputBorder.none,
              ),
              style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 16),
            )),
            const SizedBox(height: 15),

            // 2. Số lượng thành viên (Dùng Dropdown cho dễ chọn)
            _buildInfoRow('Num of member:', _buildMemberCountSelector()),
            const SizedBox(height: 25),

            // tên mình
                  Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  "You",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child:Container( // Bọc TextField trong Container màu xám
                        height: 43,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(username,
                        // In đậm chữ như trong ảnh
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center, // Canh giữa chữ trong ô xám
                        
                        ),
                      ), // Cho DropdownButton
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
      String label = 'Member ${index + 2}';
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
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Create',
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

