// --- Widget chính của màn hình "Delete account" ---
import 'package:flutter/material.dart';

class DeleteAccountPage extends StatelessWidget {
  
  // Hàm tạo Widget con cho mỗi mục cảnh báo (Icon X đỏ + Text)
  Widget _buildWarningItem(BuildContext context, {required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Icon X màu đỏ
        Icon(
          Icons.close, // Biểu tượng dấu X
          color: Colors.red,
          size: 24,
        ),
        SizedBox(width: 8),
        // Text của điều khoản
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar (Cần đảm bảo theme MaterialApp có cài đặt màu trắng/đen cho AppBar)
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Xử lý khi nhấn nút quay lại
            Navigator.pop(context); 
          },
        ),
        title: Text('Delete account'),
        centerTitle: true,
      ),
      
      // 2. Body (Nội dung chính)
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Tiêu đề/Thông báo chính
            Text(
              'Deleting your account will do the following:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 20),
            
            // Danh sách các điều khoản
            _buildWarningItem(
              context,
              text: 'Won\'t be able to retrieve data',
            ),
            SizedBox(height: 10),
            _buildWarningItem(
              context,
              text: 'Log out on all device',
            ),
            SizedBox(height: 10),
            _buildWarningItem(
              context,
              text: 'Delete all your account information',
            ),
            
            // Dùng Spacer để đẩy nút 'Continue' xuống dưới cùng
            Spacer(),
            
            // 3. Nút 'Continue' lớn ở dưới cùng
            Container(
              width: double.infinity, // Mở rộng hết chiều ngang
              height: 50, // Chiều cao cố định
              child: ElevatedButton(
                onPressed: () {
                  // Xử lý logic xóa tài khoản
                },
                style: ElevatedButton.styleFrom(
                  // primary: Colors.green, // Màu nền xanh lá
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Bo góc nhẹ
                  ),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Khoảng trống dưới cùng
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}