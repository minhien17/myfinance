import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/pages/loading_page.dart';
import 'package:my_finance/pages/setting/child_page/change_password_page.dart';
import 'package:my_finance/pages/setting/child_page/change_username_page.dart';
import 'package:my_finance/pages/setting/child_page/delete_account_page.dart';
import 'package:my_finance/shared_preference.dart';

class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await SharedPreferenceUtil.saveToken("");
    // Chuyển về trang LoadingScreen để kiểm tra lại (hoặc trực tiếp về LoginScreen)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoadingScreen()),
    );
  }

  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text('My Account'),
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
                Text("Hiển Linh"),
                Text("hienlinh2624@gmail.com"),
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
            title: Text('Change username'),
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
            title: Text('Change password'),
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
            title: Text('Delete account'),
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
      }, child: Text("Sign out"))
          ],
        ),
      ),
    );
  }
}