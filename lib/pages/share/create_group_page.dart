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
  final TextEditingController _groupNameController = TextEditingController();
  String ownerName = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final username = await SharedPreferenceUtil.getUsername();
    if (mounted) {
      setState(() {
        ownerName = username;
      });
    }
  }

  // Xử lý khi nhấn nút Create
  void _createGroup() {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      toastInfo(msg: "Vui lòng nhập tên nhóm");
      return;
    }

    // Gọi API
    _callApi(context, groupName);
  }

  void _callApi(BuildContext context, String groupName) {
    showLoading(context);

    final body = {
      "name": groupName,
      "ownerName": ownerName,
    };

    ApiUtil.getInstance()!.post(
      url: "http://localhost:3004/",
      body: body,
      onSuccess: (response) {
        print("✅ Create group success: ${response.data}");

        try {
          hideLoading();
        } catch (e) {
          print("Error hiding loading: $e");
        }

        if (mounted) {
          toastInfo(msg: "Tạo nhóm thành công!");
          Navigator.of(context).pop(); // Quay về SharePage
        }
      },
      onError: (error) {
        print("❌ Create group error: $error");

        try {
          hideLoading();
        } catch (e) {
          print("Error hiding loading: $e");
        }

        if (mounted) {
          toastInfo(msg: "Lỗi tạo nhóm: $error");
        }
      },
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
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
                  hintText: 'Nhập tên nhóm',
                  hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w300),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              )),
              const SizedBox(height: 15),

              // 2. Tên người tạo (chỉ hiển thị, không cho sửa)
              _buildInfoRow('Người tạo', Container(
                height: 43,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  ownerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )),

              const SizedBox(height: 40),

              // 3. Nút Create
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
              ? Container(
                  height: 43,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: inputWidget,
                )
              : inputWidget,
        ),
      ],
    );
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

