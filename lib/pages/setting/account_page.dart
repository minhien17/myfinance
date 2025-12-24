import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/pages/setting/child_page/about_page.dart';
import 'package:my_finance/pages/setting/child_page/my_account_page.dart';
import 'package:my_finance/pages/setting/child_page/setting_page.dart';
import 'package:my_finance/pages/setting/child_page/support_page.dart';
import 'package:my_finance/shared_preference.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();


}
// nhanh moi

class _AccountPageState extends State<AccountPage> {
  String username = "Hiển Linh";
  String email = "hienlinh2624@gmail.com";

  Future<void> getUserInfor () async {
    // username = await SharedPreferenceUtil.getUsername();
    // email = await SharedPreferenceUtil.getEmail();
    setState(() {
      
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserInfor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tài khoản"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
        ListView(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
        children: <Widget>[
          ListTile(
            leading: SizedBox(width: 5,), // Biểu tượng dấu hỏi (?)
            title: Column(children: [
              SizedBox(
                height: 80,
                child: Image.asset("assets/images/account.png")),
                SizedBox(height: 10,),
              Text(username),
              Text(email),
              SizedBox(
                height: 30,
                child: Image.asset("assets/images/google.png")),
            ],),
            trailing: Icon(Icons.chevron_right), // Biểu tượng mũi tên >
            onTap: () {
              // Chuyển sang SupportPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyAccountPage()),
              );
            },
          ),

           InkWell(
            onTap: () {
              // Chuyển sang SupportPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportPage()),
              );
            },
             child: Container(
              width: double.infinity,
              child: Image.asset("assets/images/update_image.png")),
           ),
           ListTile(
            leading: Icon(BootstrapIcons.table), // Biểu tượng dấu hỏi (?)
            title: Text('Xuất Google Sheet'),
            trailing: Icon(Icons.chevron_right), // Biểu tượng mũi tên >
            onTap: () {
              // Chuyển sang SupportPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportPage()),
              );
            },
          ),
          // 1. Container cho Support
          ListTile(
            leading: Icon(Icons.help_outline), // Biểu tượng dấu hỏi (?)
            title: Text('Hỗ trợ'),
            trailing: Icon(Icons.chevron_right), // Biểu tượng mũi tên >
            onTap: () {
              // Chuyển sang SupportPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportPage()),
              );
            },
          ),
         

          // 2. Container cho Settings
          ListTile(
            leading: Icon(BootstrapIcons.gear), // Biểu tượng bánh răng
            title: Text('Cài đặt'),
            trailing: Icon(Icons.chevron_right), // Biểu tượng mũi tên >
            onTap: () {
              // Chuyển sang SettingsPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),

          // 3. Container cho About
          ListTile(
            leading: Icon(Icons.info_outline), // Biểu tượng chữ i (info)
            title: Text('Về chúng tôi'),
            trailing: Icon(Icons.chevron_right), // Biểu tượng mũi tên >
            onTap: () {
              // Chuyển sang AboutPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            },
          ),
        ],
      ),
    
          ],
        ),
      )
      
    );
  }
}