import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/notification/timezone.dart';
import 'package:my_finance/pages/transaction/report_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/res/app_styles.dart';
import 'package:my_finance/utils.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isVisible = true;
  double _totalExpense = 0; 
  double _totalIncome = 0;
  double _balance = 0;
  final now = DateTime.now();
  String selectedMonth = '';
  List<double> currentMonthTotals = [];
  List<double> previousMonthTotals = [];
  List<TransactionModel> listTop5 = [];

  late TabController _tabController;

  // Dữ liệu summary cho biểu đồ pie chart
  Map<String, dynamic> summaryData = {
    "month": "",
    "currency": "VND",
    "data": {},
    "totals": {
      "expense": 0,
      "income": 0
    }
  };

  getListTop5 (dynamic dataTran){
    final data = dataTran["data"] as Map<String, dynamic>;

    // sort giảm dần theo amount
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // lấy top 5
    final top5 = sortedEntries.take(3);

    // đổ vào TransactionModel.full
    return top5.map((e) {
      return TransactionModel.full(
        category: e.key,
        amount: Common.parseDouble(e.value), // Convert int/double to double
      );
    }).toList();
  }

  // TextStyle legendTextStyle = TextStyle(
  //     color: Colors.grey, 
  //     fontSize: 16.0,
  //     fontWeight: FontWeight.normal,
  //   );

  //   // Kích thước của chấm tròn
  // double dotSize = 10.0;
  //   // Khoảng cách giữa chấm tròn và chữ
  // double spacing = 6.0;



  // 1️⃣ Tạo fake API kiểu bạn muốn
  Map<String, dynamic> generateFakeApiData({int daysInMonth = 30}) {
    final Random random = Random();
    double runningCurrent = 0;
    double runningPrevious = 0;

    List<Map<String, dynamic>> currentMonth = [];
    List<Map<String, dynamic>> previousMonth = [];

    for (int day = 1; day <= daysInMonth; day++) {
      // Sinh số tiền ngẫu nhiên và tích lũy
      double currentAmount = random.nextInt(200000).toDouble();
      runningCurrent += currentAmount;
      currentMonth.add({"day": day, "total": runningCurrent});

      double previousAmount = random.nextInt(150000).toDouble();
      runningPrevious += previousAmount;
      previousMonth.add({"day": day, "total": runningPrevious});
    }

    return {
      "currentMonth": currentMonth,
      "previousMonth": previousMonth,
    };
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedMonth = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    // api để call đống tiền
    getApi();
    // fake 

    getDataChart();

    Map<String, dynamic> fakeApiData = generateFakeApiData(daysInMonth: 30);
    // Chỉ lấy tổng tiền (total) từ currentMonth / previousMonth
    currentMonthTotals = (fakeApiData['currentMonth'] as List)
        .map((e) => (e['total'] as num).toDouble())
        .toList();

    previousMonthTotals = (fakeApiData['previousMonth'] as List)
        .map((e) => (e['total'] as num).toDouble())
        .toList();
    
    
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleVisible() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ====== Tổng số dư ======
                Row(
                  children: [
                    Text(
                      _isVisible
                          ? "${Common.formatNumber(_balance.toString())} đ"
                          : "*********",
                      style: AppStyles.title,
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      onPressed: _toggleVisible,
                      icon: _isVisible
                          ? const Icon(Icons.visibility)
                          : const Icon(Icons.visibility_off),
                    ),
                    const Spacer(),
                    IconButton(onPressed: (){
                      showInstantNotification(); 
                    }, icon: Icon(Icons.notifications),)
                    
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Số dư",
                      style: AppStyles.grayText16_500.copyWith(fontSize: 14),
                    ),
                    Icon(Icons.question_mark_rounded, color: AppColors.grayText),
                  ],
                ),
                const SizedBox(height: 30),
          
                // ====== Ví của tôi ======
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Ví của tôi",
                            style: AppStyles.titleText18_500,
                          ),
                          const Spacer(),
                          
                        ],
                      ),
                      Container(
                        height: 1,
                        color: AppColors.grayText,
                        margin: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/wallet.png",
                            height: 30,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Tổng chi",
                            style: AppStyles.titleText16_500,
                          ),
                          const Spacer(),
                          Text(
                                  Common.formatNumber(_totalExpense.toString()),
                                  style: AppStyles.redText16.copyWith(fontWeight: FontWeight.w600),
                                ),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/ic_launcher.png",
                            height: 30,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Tổng thu",
                            style: AppStyles.titleText16_500,
                          ),
                          const Spacer(),
                          Text(
                                  Common.formatNumber(_totalIncome.toString()),
                                  style: AppStyles.blueText16_500,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
          
                const SizedBox(height: 30),
          
                // ====== Báo cáo tháng ======
                Row(
                  children: [
                    Text(
                      "Thống kê",
                      style: AppStyles.grayText16_500,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportPage(month: selectedMonth,
                              transactionsMap: summaryData, // Dữ liệu từ API /transactions/summary
                              ),
                            ),
                          );
                      },
                      child: Text(
                        "Xem chi tiết",
                        style: AppStyles.linkText16_500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
          
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
                          Text(
                            "Tổng chi: ",
                            style: AppStyles.titleText16_500,
                          ),

                          Text(
                                  Common.formatNumber(_totalExpense.toString()),
                                  style: AppStyles.redText16.copyWith(fontWeight: FontWeight.w600),
                                ),
                        ],
                      ),
                      Container(
                            margin: EdgeInsets.only(top: 40, right: 10, bottom: 20),
                            child: SpendingCompareChart(currentMonthTotals: currentMonthTotals, previousMonthTotals: previousMonthTotals,),
                          ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Mục "Tháng này" (Chấm tròn Đỏ)
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const Flexible(
                                    child: Text(
                                      'Tháng này',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 2. Mục "Trung bình 3 tháng trước"
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const Flexible(
                                    child: Text(
                                      'Trung bình 3 tháng trước',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
          
                // Top spending
                Row(
                  children: [
                    Text(
                      "Chi tiêu hàng đầu",
                      style: AppStyles.grayText16_500,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportPage(month: selectedMonth, 
                              transactionsMap: _getReportData(), 
                              ),
                            ),
                          );
                      },
                      child: Text(
                        "Xem chi tiết",
                        style: AppStyles.linkText16_500,
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 10),

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
                    ...buildExpenseList(listTop5,context)
                  ],
                ),
              )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<TransactionModel> _allTransactions = [];

  void getApi() {
    // 1. Lấy số dư thực tế
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3001/account/balance",
      onSuccess: (response) {
        if (response.data != null) {
          _balance = Common.parseDouble(response.data['balance']);
          if (mounted) setState(() {});
        }
      },
      onError: (error) => print("Balance API error: $error"),
    );

    // 2. Lấy danh sách giao dịch tháng hiện tại để tính toán
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3001/months",
      params: {
        "month": now.month,
        "year": now.year
      },
      onSuccess: (response) {
        if (response.data != null && response.data is List) {
          final List<dynamic> jsonList = response.data;
          _allTransactions = jsonList.map((json) => TransactionModel.fromJson(json)).toList();

          // Tổng thu chi đã được tính từ summary API trong getDataChart()
          // _totalIncome = 0;
          // _totalExpense = 0;

          // for (var item in _allTransactions) {
          //   if (item.category.toLowerCase() == "income") {
          //     _totalIncome += item.amount;
          //   } else {
          //     _totalExpense += item.amount;
          //   }
          // }

          // Cập nhật Top 5 chi tiêu - được tính từ summary API trong getDataChart()
          // final expenseList = _allTransactions.where((t) => t.category.toLowerCase() != "income").toList();
          // expenseList.sort((a, b) => b.amount.compareTo(a.amount));
          // listTop5 = expenseList.take(5).toList();

          if (mounted) setState(() {});
        }
      },
      onError: (error) => print("Transactions API error: $error"),
    );
  }

  Map<String, dynamic> _getReportData() {
    Map<String, double> categoryMap = {};
    for (var t in _allTransactions) {
      if (t.category.toLowerCase() != 'income') {
        categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
      }
    }
    return {
      "totals": {
        "income": _totalIncome,
        "expense": _totalExpense,
        "balance": _balance
      },
      "data": categoryMap
    };
  }

  void getDataChart() {
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3003/transactions/summary",
      params: {
        "monthYear": selectedMonth, // Format: "MM/YYYY"
      },
      onSuccess: (response) {
        print("✅ Summary API response: ${response.data}");

        if (response.data != null) {
          if (mounted) {
            setState(() {
              summaryData = response.data;
              listTop5 = getListTop5(summaryData);
              // Cập nhật tổng thu chi từ summary API
              _totalExpense = Common.parseDouble(summaryData['totals']['expense']);
              _totalIncome = Common.parseDouble(summaryData['totals']['income']);

              print("💰 Updated from summary API - Expense: $_totalExpense, Income: $_totalIncome");
            });
          }
        }
      },
      onError: (error) {
        print("❌ Summary API error: $error");
      },
    );
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
  
}


class SpendingCompareChart extends StatelessWidget {
  SpendingCompareChart({super.key, required this.currentMonthTotals, required this.previousMonthTotals});
  
  final List<double> currentMonthTotals;
  final List<double> previousMonthTotals;

  @override
  Widget build(BuildContext context) {



    final rawMax = [
      ...currentMonthTotals,
      ...previousMonthTotals,
    ].reduce((a, b) => a > b ? a : b);

    final maxY = (((rawMax + 999999) ~/ 1000000) * 1000000).toDouble();

    final midY = maxY ~/ 2;
    

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (LineBarSpot touchedSpot) {
                return AppColors.background; // màu nền cố định bạn muốn
              },
              fitInsideHorizontally: true,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final value = spot.y.toInt();
                  final color = spot.bar.color ?? Colors.white; // giữ đúng màu line

                  return LineTooltipItem(
                    "${Common.formatNumber(value.toString())} đ",
                    TextStyle(
                      color: color, // ✅ giữ màu của line
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            
          ),

          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  // ✅ giá trị đầu (bên trái)
                  if (value == meta.min) {
                    return const Text("1");
                  }
                  // ✅ giá trị cuối (bên phải)
                  if (value == meta.max) {
                    return const Text("30");
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 2, // ép chia làm 0, mid, max
                reservedSize: 45,
                getTitlesWidget: (value, _) {
                  if (value == 0) return const Text("0");
                  if ((value - midY).abs() < 0.5) return Text("${midY ~/ 1000000}M");
                  if ((value - maxY).abs() < 0.5) return Text("${(maxY ~/ 1000000)}M");
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            drawHorizontalLine: false,  // giữ đường ngang

            getDrawingHorizontalLine: (value) {
              if (value == 0) {
                return FlLine(
                  color: AppColors.blackIcon,
                  dashArray: [4, 0], // nét liền
                  strokeWidth: 2,
                );
              }
              return FlLine(
                strokeWidth: 1,
                dashArray: [4, 2], // nét đứt nhẹ
                color: Colors.grey.withOpacity(0.3),
              );
            },
          ),

          extraLinesData: ExtraLinesData(
            horizontalLines: [
              // 🔥 Đường đáy (nét liền)
              HorizontalLine(
                y: 0,
                color: AppColors.blackIcon,
                strokeWidth: 2,
                dashArray: [4, 0], // nét liền
              ),

              // 🔸 Đường giữa (nét đứt)
              HorizontalLine(
                y: midY.toDouble(),
                color: Colors.grey.withOpacity(0.4),
                strokeWidth: 1,
                dashArray: [4, 2],
              ),

              // 🔸 Đường trên (nét đứt)
              HorizontalLine(
                y: maxY.toDouble(),
                color: Colors.grey.withOpacity(0.4),
                strokeWidth: 1,
                dashArray: [4, 2],
              ),
            ],
          ),

          borderData: FlBorderData(show: false),
          
          lineBarsData: [
            // tháng này
            LineChartBarData(
              spots: List.generate(
                currentMonthTotals.length,
                (i) => FlSpot(i.toDouble(), currentMonthTotals[i].toDouble()),
              ),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
            // tháng trước
            LineChartBarData(
              spots: List.generate(
                previousMonthTotals.length,
                (i) => FlSpot(i.toDouble(), previousMonthTotals[i].toDouble()),
              ),
              isCurved: true,
              color: Colors.grey,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
        
      ),
    );
  }
}

  class ChartData {
  final int day;
  final double total;

  ChartData({required this.day, required this.total});
}