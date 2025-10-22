import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/pages/add/add_page.dart';
import 'package:my_finance/pages/home/home_page.dart';
import 'package:my_finance/pages/setting/account_page.dart';
import 'package:my_finance/pages/share/share_page.dart';
import 'package:my_finance/pages/transaction/transaction_page.dart';

import 'package:my_finance/res/app_colors.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Khởi tạo _widgetOptions lần đầu
    _initializeWidgetOptions();
  }

  void _initializeWidgetOptions() {
    _widgetOptions = <Widget>[
      HomePage(),
      // Gán UniqueKey() ban đầu
      TransactionPage(key: UniqueKey(), goHome: _goHome), 
      Placeholder(), // AddExpense dùng Navigator.push
      SharePage(),
      AccountPage(),
    ];
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      // mở trang AddExpense và chờ đóng
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddExpensePage()),
      );
      // Khi quay lại từ AddExpensePage:
      setState(() {
        // 1. BUỘC TẢI LẠI: Tạo một UniqueKey() mới cho TransactionPage (index 1)
        _widgetOptions[1] = TransactionPage(key: UniqueKey(), goHome: _goHome);
        
        // 2. Chuyển sang tab Transaction (index 1)
        _selectedIndex = 1;
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _goHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final List<Widget> _widgetOptions = <Widget>[
    //   HomePage(),
    //   TransactionPage(goHome: _goHome),
    //   Placeholder(), // AddExpense dùng Navigator.push nên giữ Placeholder
    //   SharePage(),
    //   AccountPage()
    // ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _widgetOptions[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.house_door),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.wallet2),
            label: "Transaction",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              BootstrapIcons.plus_circle_fill,
              color: Colors.green,
              size: 30,
            ),
            label: "Add",
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.people),
            label: "Share",
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.person),
            label: "Account",
          ),
        ],
        selectedItemColor: AppColors.title,
        unselectedItemColor: AppColors.grayText,
        selectedLabelStyle: const TextStyle(color: AppColors.title),
        unselectedLabelStyle: const TextStyle(
          color: AppColors.grayText,
        ),
        showUnselectedLabels: true,
      ),
    );
  }
}
