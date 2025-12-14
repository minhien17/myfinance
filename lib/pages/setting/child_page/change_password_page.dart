import 'package:flutter/material.dart';

// --- Widget chính của màn hình "Change password" ---
class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Trạng thái để kiểm soát việc hiển thị mật khẩu
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  // Hàm tạo TextFormField tùy chỉnh cho mật khẩu
  Widget _buildPasswordField({
    required String labelText,
    required bool isVisible,
    required Function(bool) toggleVisibility,
  }) {
    return TextFormField(
      obscureText: !isVisible, // Ẩn văn bản nếu isVisible là false
      decoration: InputDecoration(
        labelText: labelText,
        // Loại bỏ đường gạch chân mặc định (tùy chọn)
        border: UnderlineInputBorder(), 
        // Biểu tượng mắt để bật/tắt hiển thị mật khẩu
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
            size: 20, // Kích thước icon nhỏ hơn một chút
          ),
          onPressed: () {
            // Cập nhật trạng thái hiển thị mật khẩu
            toggleVisibility(!isVisible);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Đổi mật khẩu'),
        centerTitle: true,
        elevation: 0, // Bỏ bóng dưới AppBar
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      
      // 2. Body (Nội dung chính)
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Email người dùng
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
              child: Text(
                'hienlinh2624@gmail.com',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400, // Hơi đậm hơn một chút
                ),
              ),
            ),
            
            // Trường "Old password"
            _buildPasswordField(
              labelText: 'Mật khẩu cũ',
              isVisible: _isOldPasswordVisible,
              toggleVisibility: (bool value) {
                setState(() {
                  _isOldPasswordVisible = value;
                });
              },
            ),
            
            SizedBox(height: 20),
            
            // Trường "New password"
            _buildPasswordField(
              labelText: 'Mật khẩu mới',
              isVisible: _isNewPasswordVisible,
              toggleVisibility: (bool value) {
                setState(() {
                  _isNewPasswordVisible = value;
                });
              },
            ),
            
            SizedBox(height: 40),
            
            // Nút "CHANGE PASSWORD"
            Container(
              width: double.infinity, // Mở rộng hết chiều ngang
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Xử lý logic đổi mật khẩu
                  print('Đổi mật khẩu...');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // Bo góc nhẹ
                  ),
                ),
                child: Text(
                  'ĐỔI MẬT KHẨU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 15),

            // Nút "FORGOT PASSWORD?"
            Center(
              child: TextButton(
                onPressed: () {
                  // Xử lý chuyển đến trang quên mật khẩu
                  print('Quên mật khẩu...');
                },
                child: Text(
                  'QUÊN MẬT KHẨU?',
                  style: TextStyle(
                    color: Colors.green, // Màu chữ xanh lá
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}