import 'package:flutter/material.dart';
import 'package:my_finance/pages/signin/signin_page.dart';
import 'package:my_finance/pages/signin/signup_page.dart';

// --- MAIN SCREEN: MyFinanceOnboarding ---
class MyFinanceOnboarding extends StatefulWidget {
  @override
  _MyFinanceOnboardingState createState() => _MyFinanceOnboardingState();
}

class _MyFinanceOnboardingState extends State<MyFinanceOnboarding> {
  // Tổng số trang là 3
  final int _numPages = 3;
  // PageController để kiểm soát và theo dõi trang hiện tại
  final PageController _pageController = PageController(initialPage: 0);
  // Biến theo dõi trang hiện tại
  int _currentPage = 0;

  // --- DANH SÁCH ĐƯỜNG DẪN ĐẾN CÁC FILE ẢNH CỦA BẠN ---
  // Đảm bảo bạn đã thêm các ảnh này vào pubspec.yaml và thư mục assets/images/
  final List<String> _imagePaths = [
    'assets/images/image1.png', // Ảnh cho trang 1
    'assets/images/image2.png', // Ảnh cho trang 2
    'assets/images/image3.png', // Ảnh cho trang 3
  ];

  // Danh sách các Widget trang
  List<Widget> _buildPages() {
    return [
      // Trang 1: Sử dụng ảnh đầu tiên
      _buildImagePage(
        context,
        imagePath: _imagePaths[0],
        title: 'Kiểm soát tài chính toàn diện'
      ),
      // Trang 2: Sử dụng ảnh thứ hai
      _buildImagePage(
        context,
        imagePath: _imagePaths[1],
        title: 'Tối ưu chi tiêu và Tiết kiệm', // Tiêu đề từ ảnh thứ hai
      ),
      // Trang 3: Sử dụng ảnh thứ ba (hoặc ảnh bảo mật của bạn nếu bạn muốn dùng ảnh riêng cho nó)
      _buildImagePage(
        context,
        imagePath: _imagePaths[2],
        title: 'Bảo mật dữ liệu tuyệt đối', // Tiêu đề từ ảnh bảo mật
      ),
    ];
  }
  
  // Hàm tạo Widget cho Dots Indicator (Chỉ báo trang)
  Widget _buildPageIndicator() {
    // Dùng Row để hiển thị các chấm tròn
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_numPages, (index) => _indicator(index == _currentPage)),
    );
  }

  // Hàm tạo từng chấm tròn
  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0, // Chấm active dài hơn
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          // 1. App Header (MyFinance Logo/Title)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo và Tiêu đề
                Row(
                  children: [
                    SizedBox(width: 33, child: Image.asset('assets/icons/ic_launcher.png'),),
                    SizedBox(width: 8),
                    Text(
                      'MyFinance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                // Icon trạng thái (Wifi/Pin) - Tạm bỏ qua
                // Icon(Icons.signal_cellular_4_bar, color: Colors.black, size: 20),
              ],
            ),
          ),
          
          // 2. PageView (Nội dung chính trượt được)
          Expanded(
            child: PageView(
              // Physics: Luôn cho phép cuộn
              physics: ClampingScrollPhysics(), 
              controller: _pageController,
              onPageChanged: (int page) {
                // Cập nhật trạng thái chấm tròn khi trang thay đổi
                setState(() {
                  _currentPage = page;
                });
              },
              children: _buildPages(),
            ),
          ),
          
          // 3. Dots Indicator (Chấm chỉ báo)
          _buildPageIndicator(),
          
          // 4. Các nút bấm (Đặt ở dưới cùng)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
            child: Column(
              children: [
                // Nút "SIGN UP FOR FREE"
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),
              );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Bo tròn
                      ),
                      elevation: 0, // Bỏ bóng
                    ),
                    child: Text(
                      'ĐĂNG KÝ MIỄN PHÍ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 15),

                // Nút "SIGN IN"
                TextButton(
                  onPressed: () {
                    Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
                  },
                  child: Text(
                    'ĐĂNG NHẬP',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Version
                SizedBox(height: 10),
                Text(
                  'Version 1.0',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// --- WIDGET CHUYÊN DỤNG ĐỂ HIỂN THỊ TRANG VỚI ẢNH TỪ ASSETS ---
Widget _buildImagePage(BuildContext context, {required String imagePath, required String title}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Spacer(),
        
        // Hiển thị ảnh từ assets
        Image.asset(
          imagePath,
          height: 200, // Điều chỉnh chiều cao ảnh theo ý muốn
          // fit: BoxFit.contain, // Đảm bảo ảnh vừa vặn
        ),
        
        Spacer(),
        
        // Tiêu đề
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        SizedBox(height: 10),
        
      ],
    ),
  );
}