import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/pages/add/edit_page.dart';
import 'package:my_finance/res/app_colors.dart';
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

  double _totalExpense = 0; 

  void reLoadPage(){
    getListMonth();
    getListTransaction(selectedMonth);
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
      appBar: AppBar(
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back)),
        title: Text(
          widget.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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

                        // 🔸 Gọi API khi đổi tháng
                        getListTransaction(selectedMonth);
                      },
                      child: Container(
                        width: width / 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
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
                                  isSelected ? FontWeight.bold : FontWeight.normal,
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
                        Text("You", style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title)),
                        
                        Text("Group", style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,)),
                        
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(Common.formatNumber(_totalExpense.toString()),
                            style: const TextStyle(color: AppColors.blackIcon, fontSize: 18)),
                        Text(Common.formatNumber(_totalExpense.toString()),
                            style: const TextStyle(color: AppColors.blackIcon, fontSize: 18)),
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
        months =
            jsonList.map((json) => TransactionModel.fromJson(json).type).toList();
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