import 'package:flutter/material.dart';
import 'package:my_finance/pages/home/home.dart';
import 'package:my_finance/pages/signin/onboard_page.dart';
import 'package:my_finance/shared_preference.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi hàm kiểm tra token ngay khi Widget được tạo
    _checkAuthStatus();
  }

  // HÀM QUAN TRỌNG: Kiểm tra Token trong SharedPreferences
  void _checkAuthStatus() async {
    
    // 2. Lấy token (nếu không có thì trả về "")
    final token = await SharedPreferenceUtil.getToken();

    // Dùng Future.delayed để có một khoảng thời gian chờ (giúp giao diện mượt hơn)
    await Future.delayed(Duration(seconds: 1)); 

    // 3. Kiểm tra điều kiện và điều hướng
    Widget nextScreen;
    if (!token.isNotEmpty) { // fixx tạm
      // Token KHÔNG phải là "" (tức là đã đăng nhập)
      nextScreen = MainPage();
    } else {
      // Token là "" (chưa đăng nhập hoặc token đã bị xóa)
      nextScreen = MyFinanceOnboarding();
    }

    // 4. Điều hướng
    // Dùng pushReplacement để thay thế màn hình Loading, ngăn người dùng quay lại
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị màn hình Loading trong khi kiểm tra token
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), // Vòng xoay chờ
            SizedBox(height: 20),
            Text('Syncing data ...'),
          ],
        ),
      ),
    );
  }
}
