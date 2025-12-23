import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/pages/loading_page.dart';
import 'package:my_finance/pages/setting/child_page/change_password_page.dart';
import 'package:my_finance/pages/setting/child_page/change_username_page.dart';
import 'package:my_finance/pages/setting/child_page/delete_account_page.dart';
import 'package:my_finance/shared_preference.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  String username = "";
  String email = "";

  Future<void> getUserInfor () async {
    username = await SharedPreferenceUtil.getUsername();
    email = await SharedPreferenceUtil.getEmail();
    setState(() {
      
    });
  }
  @override
  void initState() {
    super.initState();
    getUserInfor();
  }
  
  Future<void> _logout(BuildContext context) async {
    // Clear toàn bộ thông tin session
    await SharedPreferenceUtil.saveToken("");
    await SharedPreferenceUtil.saveUsername("");
    await SharedPreferenceUtil.saveEmail("");
    
    // Chuyển về trang LoadingScreen để kiểm tra lại
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoadingScreen()),
        (route) => false, // Xóa hết stack cũ
      );
    }
  }

  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text('Tài khoản của tôi'),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 80, child: Image.asset("assets/images/account.png")),
                SizedBox(height: 10),
                Text(username),
                Text(email),
                SizedBox(height: 30, child: Image.asset("assets/images/google.png")),
              ],
            ),
            
            ListView(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
        children: <Widget>[

           // 1. Change name
          ListTile(
            leading: Icon(BootstrapIcons.type), // Biểu tượng bánh răng
            title: Text('Đổi tên người dùng'),
            onTap: () {
              // Chuyển sang SettingsPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeUsernamePage(currentUsername: "Hiển Linh")),
              );
            },
          ),


          // 2. Container cho Settings
          ListTile(
            leading: Icon(BootstrapIcons.key), // Biểu tượng bánh răng
            title: Text('Đổi mật khẩu'),
            onTap: () {
              // Chuyển sang SettingsPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            },
          ),

          // 3. Container cho About
          ListTile(
            leading: Icon(BootstrapIcons.trash), // Biểu tượng chữ i (info)
            title: Text('Xóa tài khoản'),
            onTap: () {
              // Chuyển sang AboutPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeleteAccountPage()),
              );
            },
          ),
        ],
      ),
      ElevatedButton(onPressed: (){
         _logout(context);
      }, child: Text("Đăng xuất"))
          ],
        ),
      ),
    );
  }
}