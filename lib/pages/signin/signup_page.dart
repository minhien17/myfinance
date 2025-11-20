import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/pages/signin/signin_page.dart';
import 'package:my_finance/shared_preference.dart';

// --- Widget chính của màn hình "Sign up" ---
class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Trạng thái để kiểm soát việc hiển thị mật khẩu
  bool _isPasswordVisible = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  Future<void> _signup(BuildContext context) async {
    // xử lý text trước
    final username = _usernameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  // Kiểm tra cơ bản
  if (username.isEmpty || email.isEmpty || password.isEmpty) {
    toastInfo(msg: "Please fill in all fields");
    return;
  }

   if (password.length < 6){
    toastInfo(msg: "Password must have at least 6 characters");
    return;
  }

  // Kiểm tra định dạng email
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!emailRegex.hasMatch(email)) {
    toastInfo(msg: "Invalid email format");
    
    return;
  }


    showLoading(context);
    ApiUtil.getInstance()!.post(
    body: {
      "username": username,
      "email":email,
      "password":password
    },
    url: "http://localhost:3003/auth/register", // fixx
    onSuccess: (response) {
      hideLoading();
      var res = response.data;

      setState(() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SignInScreen()),
        );
      });
      
    },
    onError: (error) {
      if (error is TimeoutException) {
            toastInfo(msg: "Time out");
          } else {
            toastInfo(msg: error.toString());
          }
          hideLoading();
    },
  );
    
    
  }

  // Hàm tạo nút đăng nhập/đăng ký bằng bên thứ ba
  Widget _buildSocialButton({
    required String text,
    required String imageAsset, // Sử dụng String để mô phỏng asset path
    required Color textColor,
    required Color borderColor,
    required Function() onPressed,
  }) {
    // Lưu ý: Đối với Google/Apple, bạn nên sử dụng các gói (packages) chính thức
    // Đây là cách mô phỏng giao diện
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Mô phỏng Icon/Logo bên trái
            // Trong thực tế, bạn sẽ dùng Image.asset(imageAsset)
            // Tạm dùng Text để mô phỏng vị trí logo
            Text(
              imageAsset, 
              style: TextStyle(
                fontSize: 20, 
                color: (text.contains('GOOGLE')) ? Colors.red : Colors.black,
              )
            ), 
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
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
        title: Text('Sign up'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      
      // 2. Body (Nội dung chính)
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 10),

            // Nút 1: Connect with Google
            _buildSocialButton(
              text: 'CONNECT WITH GOOGLE',
              imageAsset: 'G', // Mô phỏng logo Google
              textColor: Colors.red, // Chữ màu đỏ
              borderColor: Colors.red, // Viền màu đỏ
              onPressed: () {
                print('Đăng ký bằng Google...');
              },
            ),
            
            SizedBox(height: 10),

            // Nút 2: Sign in with Apple
            _buildSocialButton(
              text: 'SIGN IN WITH APPLE',
              imageAsset: '', // Mô phỏng logo Apple
              textColor: Colors.black, // Chữ màu đen
              borderColor: Colors.black, // Viền màu đen
              onPressed: () {
                print('Đăng ký bằng Apple...');
              },
            ),
            
            // Thông báo nhỏ dưới Apple button
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "We'll never post without your permission.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            SizedBox(height: 20),

            // Dòng chữ OR
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'OR',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            
            SizedBox(height: 10),

            // Trường Username
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                labelText: 'Username',
                border: UnderlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Trường Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: UnderlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Trường Password
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                border: UnderlineInputBorder(),
                // Biểu tượng mắt
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            
            SizedBox(height: 40),
            
            // Nút "SIGN UP" chính
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _signup(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'SIGN UP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 15),

            // Nút "Sign in" (chuyển sang trang đăng nhập)
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
                },
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.green, // Màu chữ xanh lá
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}