import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/pages/home/home.dart';
import 'package:my_finance/pages/signin/signup_page.dart';
import 'package:my_finance/shared_preference.dart';

// --- Widget chính của màn hình "Sign in" ---
class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Trạng thái để kiểm soát việc hiển thị mật khẩu
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {

  final email = _emailController.text.trim();
  final password = _passwordController.text;

  // Kiểm tra cơ bản
  if ( email.isEmpty || password.isEmpty) {
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
      "email":email,
      "password":password
    },
    url: "http://localhost:3003/auth/login",// fixx
    onSuccess: (response) {
      hideLoading();
      // lấy token và user name
      var res = response.data;
      String token = res["access_token"];
      String username = res["user"]["username"];
      String email = res["user"]["email"];
      
      print(res);
      print(username);
      SharedPreferenceUtil.saveToken(token);
      SharedPreferenceUtil.saveUsername(username);
      SharedPreferenceUtil.saveEmail(email);
      setState(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainPage()),(Route<dynamic> route) => false,
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

  // Hàm tạo nút đăng nhập bằng bên thứ ba
  Widget _buildSocialButton({
    required String text,
    required String imageAsset, // Mô phỏng asset path hoặc ký tự logo
    required Color textColor,
    required Color borderColor,
    required Function() onPressed,
  }) {
    // Đây là cách mô phỏng giao diện nút có viền và icon
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
            // Tạm dùng Text để mô phỏng vị trí logo (G hoặc )
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
        title: Text('Sign in'), // Thay đổi tiêu đề
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
              imageAsset: 'G', 
              textColor: Colors.red, 
              borderColor: Colors.red, 
              onPressed: () {
                print('Đăng nhập bằng Google...');
              },
            ),
            
            SizedBox(height: 10),

            // Nút 2: Sign in with Apple
            _buildSocialButton(
              text: 'SIGN IN WITH APPLE',
              imageAsset: '', 
              textColor: Colors.black, 
              borderColor: Colors.black, 
              onPressed: () {
                print('Đăng nhập bằng Apple...');
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
            
            // Nút "SIGN IN" chính
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _login(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'SIGN IN', // Thay đổi chữ thành SIGN IN
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 15),

            // Hàng chứa hai nút liên kết dưới cùng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút "Sign up"
                TextButton(
                  onPressed: () {
                    setState(() {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => SignUpScreen()),
                      );
                    });
                  },
                  child: Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.green, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Nút "Forgot password?"
                TextButton(
                  onPressed: () {
                    print('Chuyển sang Quên mật khẩu...');
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Colors.green, 
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}