import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/utils.dart';

class ReportPage extends StatefulWidget {
  final String month; // ví dụ: "11/2025"
  final Map<String, dynamic> transactionsMap; // nhận nguyên Map

  const ReportPage({super.key, required this.month, required this.transactionsMap,});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {

  List<TransactionModel> listTransaction = [];

  Map<String, dynamic> transactionData = {};

  // Thực hiện thao tác tổng hợp và sắp xếp
  List<TopExpenseModel> topExpenses = [];
  double _totalExpense = 0; 
  double _totalIncome = 0;

  @override
  void initState() {
    super.initState();

    transactionData = widget.transactionsMap;
    
    // 1️⃣ Hứng tổng income và expense từ fakeTransactions['totals']
    _totalIncome = Common.parseDouble(transactionData['totals']['income']);
    _totalExpense = Common.parseDouble(transactionData['totals']['expense']);
    
    // 1️⃣ Tạo list tạm thời kiểu MapEntry<String, double>
    var entries = <MapEntry<String, double>>[];

    (transactionData['data'] as Map<String, dynamic>).forEach((key, value) {
      if (key.toLowerCase() != 'income'){
      entries.add(MapEntry(key, Common.parseDouble(value)));}
    });

    // 2️⃣ Sắp xếp giảm dần
    entries.sort((a, b) => b.value.compareTo(a.value));

    // 3️⃣ Tạo listTransaction
    listTransaction = entries.map((e) => TransactionModel.full(
      category: e.key,
      amount: e.value,
    )).toList();


        topExpenses = aggregateAndGetTop5Expenses(transactionData);

  }

  List<Widget> buildExpenseList(List<TransactionModel> lists, BuildContext context) {
  
  // 1️⃣ Map qua danh sách và tạo Widget
  List<Widget> containers = lists.asMap().entries.map((entry) {
    final index = entry.key;
    final expense = entry.value;
    
    final Color amountColor = expense.category == "income" ? Colors.blue : Colors.red;
    return Column(
      mainAxisSize: MainAxisSize.min, // Đảm bảo Column không chiếm hết chiều cao
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.all(10),
          
          child: Row(
            children: [
              // 💡 SỬ DỤNG HÀM CỦA BẠN: Biểu tượng
              itemLeading(expense.category), 
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 💡 SỬ DỤNG HÀM CỦA BẠN: Tiêu đề
                    Text(
                      titleOf(expense.category) ?? expense.category, // Fallback là category
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                  ],
                ),
              ),
              
              // Số tiền
              Text(
                Common.formatNumber(expense.amount.toString()),
                // 💡 SỬ DỤNG amountColor ĐÃ TÍNH
                style: TextStyle(color: amountColor, fontSize: 16),
              ),
            ],
          ),
        ),
        // 💡 ĐƯỜNG KẺ DƯỚI (Divider)
        // Điều chỉnh màu sắc và độ dày cho tinh tế hơn
        if (index != lists.length - 1) Divider(
          height: 0, // Đặt height = 0 để kiểm soát khoảng cách bằng padding
          thickness: 0.8, // Độ dày mỏng
          color: Colors.black12, // Màu xám nhạt
          indent: 50, // Lùi vào bằng vị trí của icon
        ),
      ],
    );
  }).toList(); // 2️⃣ BƯỚC QUAN TRỌNG: Chuyển Iterable thành List<Widget>

  return containers;
}

  @override
  Widget build(BuildContext context) {
    final totalTop5 = topExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chi tiết tháng ${widget.month}",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xfff8f8f8),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 💰 Tổng Income và Outcome
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 5,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Thu nhập",
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text(
                          "${Common.formatNumber(_totalIncome.toString())} đ",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("Chi tiêu",
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text(
                          "${Common.formatNumber(_totalExpense.toString())} đ",
                          style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 30),
        
              // 🥧 Biểu đồ tròn
              Container(
                height: 350,
                width: size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 5,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Chi tiêu hàng đầu",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 40,
                          sections: topExpenses.map((item) {
                            final percent =
                                (item.amount / totalTop5 * 100).toStringAsFixed(1);
                            return PieChartSectionData(
                              color: item.color,
                              value: item.amount.toDouble(),
                              title: "$percent%",
                              radius: 60,
                              titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                      
                    // 🧾 Ghi chú legend
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 6,
                      children: topExpenses
                          .map((item) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    titleOf(item.category) ?? "",
                                    style: const TextStyle(fontSize: 14),
                                  )
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 5,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...buildExpenseList(listTransaction,context)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
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

List<TopExpenseModel> aggregateAndGetTop5Expenses(Map<String, dynamic> transactions) {
  Map<String, dynamic> data = transactions['data'] ?? {};

  // 1️⃣ Chỉ lấy các khoản chi tiêu (expense), loại bỏ income
  List<MapEntry<String, double>> expenseList = data.entries
      .where((e) => e.key.toLowerCase() != 'income')
      .map((e) => MapEntry(e.key, Common.parseDouble(e.value)))
      .toList();

  // 2️⃣ Sắp xếp giảm dần
  expenseList.sort((a, b) => b.value.compareTo(a.value));

  // 3️⃣ Lấy 5 khoản chi tiêu lớn nhất
  final top5 = expenseList.take(5).toList();

  // 4️⃣ Gán màu cho PieChart
  final List<Color> defaultColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple
  ];

  return List.generate(top5.length, (index) {
    return TopExpenseModel(
      category: top5[index].key,
      amount: top5[index].value,
      color: defaultColors[index % defaultColors.length], 
    );
  });
}
