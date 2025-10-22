import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/res/app_styles.dart';
import 'package:my_finance/utils.dart';

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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // api để call đống tiền
    getApi();
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
                    const Icon(Icons.notifications),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Total balance",
                      style: AppStyles.grayText15_400,
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
                            "My wallets",
                            style: AppStyles.titleText18_500,
                          ),
                          const Spacer(),
                          Text(
                            "See all",
                            style: AppStyles.linkText16_500,
                          ),
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
                            height: 50,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Money",
                            style: AppStyles.titleText16_500,
                          ),
                          const Spacer(),
                          Text(
                            "${Common.formatNumber(_balance.toString())} đ",
                            style: AppStyles.titleText16_500,
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
                      "Report this month",
                      style: AppStyles.grayText16_700,
                    ),
                    const Spacer(),
                    Text(
                      "See reports",
                      style: AppStyles.linkText16_500,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
          
                // ====== TabBar + TabBarView ======
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total spent",
                                  style: AppStyles.grayText15_400,
                                ),
                                Text(
                                  Common.formatNumber(_totalExpense.toString()),
                                  style: AppStyles.redText16,
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total income",
                                  style: AppStyles.grayText15_400,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  Common.formatNumber(_totalIncome.toString()),
                                  style: AppStyles.blueText16_500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            Center(child: Text("Chart 1")),
                            Center(child: Text("Chart 2")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          
                // Top spending
                Row(
                  children: [
                    Text(
                      "Top spending",
                      style: AppStyles.grayText16_700,
                    ),
                    const Spacer(),
                    Text(
                      "See details",
                      style: AppStyles.linkText16_500,
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
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total spent",
                                  style: AppStyles.grayText15_400,
                                ),
                                Text(
                                  Common.formatNumber("3171000"),
                                  style: AppStyles.redText16,
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total income",
                                  style: AppStyles.grayText15_400,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "0",
                                  style: AppStyles.blueText16_500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            Center(child: Text("Chart 1")),
                            Center(child: Text("Chart 2")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void getApi() {
    ApiUtil.getInstance()!.get(url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/home", onSuccess: (response){
      var data = response.data[0];
      
      _balance = data["balance"];
      _totalIncome = data['income'];
      _totalExpense = data['expense'];
      setState(() {
        
      });
    }, onError: (error){
      
    });
  }
}
