import 'dart:async';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/pages/share/child_page/add_transation_group_page.dart';
import 'package:my_finance/pages/share/child_page/edit_transation_group_page.dart';
import 'package:my_finance/pages/share/child_page/view_report_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';
import 'package:my_finance/utils.dart';

class TransactionGroupPage extends StatefulWidget {
  final String name;
  const TransactionGroupPage({super.key, required this.name});
  @override
  _TransactionGroupPageState createState() => _TransactionGroupPageState();
}

class _TransactionGroupPageState extends State<TransactionGroupPage> with SingleTickerProviderStateMixin  {
  final now = DateTime.now();
  late ScrollController _scrollController;

  String selectedMonth = '';
  
  List<String> months = ["8/2025", "9/2025", "10/2025", "11/2025"]; // danh sách tháng lấy từ API
  List<TransactionModel> lists = [];
  bool _loading = true;

  double _totalExpense = 3000000; 
  double _youPay = 100000; 
  String owner = '';

  void reLoadPage(){
    getListMonth();
    getListTransaction(selectedMonth);
  }

  Future<void> getOwner() async {
    owner = await SharedPreferenceUtil.getUsername();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); 
    

    selectedMonth = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    setState(() {
      // Cuộn ListView đến cuối
      _scrollToEnd();
    });
    reLoadPage(); 
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else {
      // Nếu controller chưa có client (list chưa render) thì đợi 1 chút
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

    void _scrollToSelected() {
      if (!_scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
        return;
      }

      final selectedIndex = months.indexOf(selectedMonth);
      const itemWidth = 100.0; // 👉 CHỈNH THEO ITEM CỦA BẠN
      final offset = selectedIndex * itemWidth;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }


  List<Widget> buildExpenseList(List<TransactionModel> lists, BuildContext context) {
  // 1️⃣ Gom nhóm theo ngày (YYYY-MM-DD)
  Map<String, List<TransactionModel>> grouped = {};
  for (var expense in lists) {
    String dateKey = expense.dateTime.toIso8601String().split('T')[0];
    grouped.putIfAbsent(dateKey, () => []);
    grouped[dateKey]!.add(expense);
  }

  // 2️⃣ Tạo danh sách Widget cho từng nhóm
  List<Widget> containers = grouped.entries.map((entry) {
    String dateKey = entry.key;
    List<TransactionModel> dailyExpenses = entry.value;

    // Chuyển dateKey -> DateTime để hiển thị
    DateTime date = DateTime.parse(dateKey);

    // ✅ Tính tổng tiền trong ngày
    double totalAmount = dailyExpenses.fold(
      0,
      (sum, e) => sum + e.amount,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧾 Header ngày + tổng tiền
          Row(
            children: [
              Text(
                "${date.day}/${date.month}/${date.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                Common.formatNumber(totalAmount.toString()),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 5,)
            ],
          ),

          const SizedBox(height: 10),

          // 3️⃣ Danh sách expense trong ngày đó
          ...dailyExpenses.map((expense) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTransactionGroupPage(
                        amount: expense.amount,
                        category: expense.category,
                        note: expense.note ?? "",
                        date: expense.dateTime,
                        owner: expense.owner,
                      ),
                    ),
                  );
                  // Gọi reloadPage() nếu cần
                },
                child: Row(
                  children: [
                    itemLeading(expense.category),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleOf(expense.category) ??"",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expense.note ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      expense.owner,
                      style: 
                      TextStyle(color: AppColors.blackIcon, fontSize: 16)
                    ),
                    SizedBox(width: 50,),
                    Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: Text(
                        Common.formatNumber(expense.amount.toString()),
                        style:
                        TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }).toList();

    return containers;
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),
        title: Text(
          widget.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
  PopupMenuButton<String>(
    // 1. Giữ nguyên icon cũ của bạn
    icon: const Icon(Icons.more_vert), 
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: AppColors.background,
    ),
    // 2. Xử lý logic khi người dùng chọn 1 trong 2 mục
    onSelected: (String value) {
      if (value == 'edit_name') {
        // Code mở popup/màn hình chỉnh sửa tên ở đây
        print("Đã chọn Chỉnh sửa tên");
      } else if (value == 'add_member') {
        // Code mở màn hình thêm người ở đây
        print("Đã chọn Thêm người");
      }
    },
    
    // 3. Định nghĩa danh sách các lựa chọn trong menu
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      // Lựa chọn 1: Chỉnh sửa tên
      const PopupMenuItem<String>(
        value: 'edit_name',
        child: Row(
          children: [
            Icon(Icons.edit, color: AppColors.blackIcon), // Icon minh họa
            SizedBox(width: 12),
            Text('Đổi tên nhóm'),
          ],
        ),
      ),
      // Lựa chọn 2: Thêm người
      const PopupMenuItem<String>(
        value: 'add_member',
        child: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.blackIcon), // Icon minh họa
            SizedBox(width: 12),
            Text('Thêm thành viên'),
          ],
        ),
      ),
      // Lựa chọn 3: Rời nhóm
      const PopupMenuItem<String>(
        value: 'out_group',
        child: Row(
          children: [
            Icon(Icons.remove, color: AppColors.blackIcon), // Icon minh họa
            SizedBox(width: 12),
            Text('Rời nhóm'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'delete_group',
        child: Row(
          children: [
            Icon(Icons.delete, color: AppColors.blackIcon), // Icon minh họa
            SizedBox(width: 12),
            Text('Xóa nhóm'),
          ],
        ),
      ),
    ],
  ),
],
        centerTitle: true, // 👈 căn giữa cho title
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 🔹 Thanh chọn tháng
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          backgroundColor: Colors.white,
          flexibleSpace: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                height: 36,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController, // 👈 Gán controller
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final monthValue = months[index];
                    final isSelected = monthValue == selectedMonth;
                    return GestureDetector(
                      onTap: () async {
                        if (isSelected) return;
                        setState(() => selectedMonth = monthValue);
                        _scrollToSelected();

                        // 🔸 Gọi API khi đổi tháng
                        getListTransaction(selectedMonth);
                      },
                      child: Container(
                        width: width / 3,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            months[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isSelected ? FontWeight.w500 : FontWeight.normal,
                              color: isSelected ? Colors.green : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text("Bạn", style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title)),
                        
                        Text("Nhóm", style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,)),
                        
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(Common.formatNumber(_youPay.toString()),
                            style: const TextStyle(color: AppColors.blackIcon, fontSize: 18)),
                        Text(Common.formatNumber(_totalExpense.toString()),
                            style: const TextStyle(color: AppColors.blackIcon, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 15),
                   Row(
                    
                    children: [
                      // 🔹 Nút Add Transaction
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddTransactionGroupPage()),
                            );
                          },
                          child: const Text(
                            "Thêm khoản",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 20,),

                      // 🔹 Nút View Detail
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ViewReportPage()),
                            );
                          },
                          child: const Text(
                            "Xem chi tiết",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                color: AppColors.background,
                child: 
                _loading ? 
                Center(child: CircularProgressIndicator(),) :
                Column(children: [...buildExpenseList(lists, context)]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
  
  void getSum() {}
  
  void getListMonth() {
    _loading = false;
    ApiUtil.getInstance()!.get(
    url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/transactions",
    onSuccess: (response) {
      // giả sử response.data là 1 mảng JSON
      List<dynamic> jsonList = response.data;
      if (!mounted) return;
      setState(() {
        // months =
        //     jsonList.map((json) => TransactionModel.fromJson(json).).toList();
        _loading = false;
      });
    },
    onError: (error) {
      if (error is TimeoutException) {
            toastInfo(msg: "Time out");
          } else {
            toastInfo(msg: error.toString());
          }
    },
  );
  }
  
  void getListTransaction(String nameOfMonth) {
    setState(() {
      _loading = true;
    });
    ApiUtil.getInstance()!.get(
    url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/transactions",
    onSuccess: (response) {
      // giả sử response.data là 1 mảng JSON
      List<dynamic> jsonList = response.data;
      if (!mounted) return;
      setState(() {
        lists =
            jsonList.map((json) => TransactionModel.fromJson(json)).toList();
        _loading = false;
      });
    },
    onError: (error) {
      print("Lỗi khi gọi API: $error");
    },
  );
  }
}

Image itemLeading(String type) {
  for (int i = 0; i < ListIcon.length; i++) {
    if (ListIcon[i].title == type) {
      return ListIcon[i].img;
    }
  }
  // Nếu không tìm thấy thì trả về icon mặc định
  return Image.asset(
    'assets/icons/other.png',
    height: 30,
    width: 30,
  );
}