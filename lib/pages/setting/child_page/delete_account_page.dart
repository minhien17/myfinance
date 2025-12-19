import 'package:flutter/material.dart';

class DeleteAccountPage extends StatelessWidget {
  
  // Hàm tạo Widget con cho mỗi mục cảnh báo
  Widget _buildWarningItem(BuildContext context, {required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Icon X màu đỏ
        const Icon(
          Icons.close, // Biểu tượng dấu X
          color: Colors.red,
          size: 24,
        ),
        const SizedBox(width: 8),
        // Text của điều khoản
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
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
      // 1. AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
        title: const Text('Xóa tài khoản'), // Đã dịch
        centerTitle: true,
      ),
      
      // 2. Body
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Tiêu đề/Thông báo chính
            const Text(
              'Việc xóa tài khoản sẽ thực hiện các hành động sau:', // Đã dịch
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Danh sách các điều khoản
            _buildWarningItem(
              context,
              text: 'Không thể khôi phục dữ liệu', // Đã dịch
            ),
            const SizedBox(height: 10),
            _buildWarningItem(
              context,
              text: 'Đăng xuất khỏi tất cả các thiết bị', // Đã dịch
            ),
            const SizedBox(height: 10),
            _buildWarningItem(
              context,
              text: 'Xóa toàn bộ thông tin tài khoản của bạn', // Đã dịch
            ),
            
            // Spacer để đẩy nút xuống dưới cùng
            const Spacer(),
            
            // 3. Nút 'Tiếp tục'
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Xử lý logic xóa tài khoản
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tiếp tục', // Đã dịch
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}