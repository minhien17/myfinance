import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/pages/add/edit_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/utils.dart';

class TransactionPage extends StatefulWidget {
  final VoidCallback goHome;
  const TransactionPage({super.key, required this.goHome});
  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  

  List<TransactionModel> lists = [];

  List<String> months = [];
  double _totalExpense = 0; 
  double _totalIncome = 0;
  double _balance = 0;

  void reLoadPage(){
    getTotal();
    getListMonth();
    getListTransaction();
  }

  @override
  void initState() {
    super.initState();
    reLoadPage();  
  }

  void getTotal() {
    ApiUtil.getInstance()!.get(url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/home", onSuccess: (response){
      var data = response.data[0];
      
      _balance = data["balance"];
      _totalIncome = data['income'];
      _totalExpense = data['expense'];
      if (!mounted) return;
      setState(() {
        // cập nhật state
      });
    }, onError: (error){
      
    });
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
      (sum, e) => sum + (e.category == 'income' ? e.amount : -e.amount),
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
                      builder: (context) => EditExpensePage(
                        amount: expense.amount,
                        category: expense.category,
                        note: expense.note ?? "",
                        date: expense.dateTime,
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
                      Common.formatNumber(expense.amount.toString()),
                      style: expense.category != "income" ?
                      TextStyle(color: Colors.red, fontSize: 16) :   TextStyle(color: Colors.blue, fontSize: 16),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            toolbarHeight: 150,
            flexibleSpace: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 15, right: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: width / 3),
                      Container(
                        width: width / 3,
                        child: Column(
                          children: [
                            const Text("Balance",
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text(
                              "${Common.formatNumber(_balance.toString())} đ",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                                height: 30, child: Image.asset("assets/icons/wallet.png")
                                ),
                          ],
                        ),
                      ),
                      Container(
                        height: 80,
                        width: width / 3 - 10,
                        alignment: Alignment.topRight,
                        child: Row(
                          children: [
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.search),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: width / 3,
                        child: InkWell(
                          onTap: () {
                            print(months[index]);
                          },
                          child: Center(
                            child: Text(months[index],
                                style: const TextStyle(fontSize: 16)),
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
                      children: [
                        const Text("Inflow", style: TextStyle(
                                fontSize: 16)),
                        const Spacer(),
                        Text(Common.formatNumber(_totalIncome.toString()),
                            style: const TextStyle(color: Colors.blue, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text("Outflow",
                            style: TextStyle( fontSize: 16)),
                        const Spacer(),
                        Text(Common.formatNumber(_totalExpense.toString()),
                            style: const TextStyle(color: Colors.red, fontSize: 16)),
                      ],
                    ),
                    Divider(height: 16, thickness: 0.5, indent: width / 2),
                    Row(
                      children: [
                        const Spacer(),
                        Text(Common.formatNumber((_totalIncome - _totalExpense).toString()),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: widget.goHome,
                      child: const Text("View report for this period"),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                color: AppColors.background,
                child: 
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
    ApiUtil.getInstance()!.get(
    url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/transactions",
    onSuccess: (response) {
      // giả sử response.data là 1 mảng JSON
      List<dynamic> jsonList = response.data;
      if (!mounted) return;
      setState(() {
        months =
            jsonList.map((json) => TransactionModel.fromJson(json).id).toList();
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
  
  void getListTransaction() {
    ApiUtil.getInstance()!.get(
    url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/transactions",
    onSuccess: (response) {
      // giả sử response.data là 1 mảng JSON
      List<dynamic> jsonList = response.data;
      if (!mounted) return;
      setState(() {
        lists =
            jsonList.map((json) => TransactionModel.fromJson(json)).toList();
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