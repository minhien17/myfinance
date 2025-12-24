import 'dart:async';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/debt_model.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/pages/share/child_page/add_transation_group_page.dart';
import 'package:my_finance/pages/share/child_page/edit_transation_group_page.dart';
import 'package:my_finance/pages/share/child_page/view_report_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';
import 'package:my_finance/utils.dart';

import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/member_model.dart';
// ... imports

class TransactionGroupPage extends StatefulWidget {
  final Group group;
  final String? joinedMemberName;
  const TransactionGroupPage({super.key, required this.group, this.joinedMemberName});
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

  List<DebtModel> myDebts = [];
  List<DebtModel> owedToMe = [];
  int currentTab = 0; // 0: Transactions, 1: Debts

  double _totalExpense = 0;
  double _myExpense = 0;
  String owner = '';
  String currentUserId = ''; // 🔥 userId của người đang đăng nhập

  List<Member> groupMembers = []; // Lưu danh sách members để hiển thị tên trong phần nợ

  void reLoadPage(){
    getListMonth();
    getListTransaction(selectedMonth);
    fetchDebts();
  }

  Future<void> fetchDebts() async {
    // GET /groups/{groupId}/expenses/my-debts
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3001/groups/${widget.group.id}/expenses/my-debts",
      onSuccess: (response) {
        final List<dynamic> data = response.data;
        setState(() {
          myDebts = data.map((e) => DebtModel.fromJson(e)).toList();
        });
      },
      onError: (err) => print("Fetch debts error: $err"),
    );

    // GET /groups/{groupId}/expenses/owed-to-me
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3001/groups/${widget.group.id}/expenses/owed-to-me",
      onSuccess: (response) {
        final List<dynamic> data = response.data;
        setState(() {
          owedToMe = data.map((e) => DebtModel.fromJson(e)).toList();
        });
      },
      onError: (err) => print("Fetch owed error: $err"),
    );
  }

  Future<void> fetchGroupDetailsAndNavigate() async {
    // Nếu đã có groupMembers thì dùng luôn, không cần fetch lại
    if (groupMembers.isNotEmpty) {
      final fullGroup = Group(
        id: widget.group.id,
        name: widget.group.name,
        code: widget.group.code,
        number: widget.group.number,
        totalMembers: widget.group.totalMembers,
        members: groupMembers,
        memberName: widget.group.memberName,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddTransactionGroupPage(group: fullGroup)),
      ).then((_) => reLoadPage());
      return;
    }

    // Nếu chưa có thì fetch
    showLoading(context);

    ApiUtil.getInstance()!.get(
      url: "http://localhost:3004/join/${widget.group.code}",
      onSuccess: (response) {
        Navigator.of(context).pop(); // Đóng loading

        try {
          final groupData = response.data;

          // Parse members từ response
          List<Member> members = [];
          if (groupData["members"] != null) {
            final List<dynamic> membersData = groupData["members"];
            for (var m in membersData) {
              members.add(Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {}));
            }
          }

          // Update groupMembers state
          setState(() {
            groupMembers = members;
          });

          // Tạo Group object mới với đầy đủ members
          final fullGroup = Group(
            id: widget.group.id,
            name: widget.group.name,
            code: widget.group.code,
            number: widget.group.number,
            totalMembers: widget.group.totalMembers,
            members: members,
            memberName: widget.group.memberName,
          );

          print("🔍 DEBUG - Fetched ${members.length} members for group ${widget.group.name}");

          // Mở AddTransactionGroupPage với Group đã có đầy đủ members
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionGroupPage(group: fullGroup)),
          ).then((_) => reLoadPage());
        } catch (e) {
          print("❌ Error parsing group details: $e");
          toastInfo(msg: "Lỗi khi tải thông tin nhóm");
        }
      },
      onError: (error) {
        Navigator.of(context).pop(); // Đóng loading
        print("❌ Error fetching group details: $error");
        toastInfo(msg: "Lỗi khi tải thông tin nhóm");
      },
    );
  }

  void markAsPaid(String shareId) {
    showLoading(context);
    ApiUtil.getInstance()!.post(
      url: "http://localhost:3001/groups/${widget.group.id}/expenses/mark-paid",
      body: {"shareId": shareId},
      onSuccess: (response) {
        hideLoading();
        reLoadPage();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã nhận tiền thành công!')),
        );
      },
      onError: (err) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $err')),
        );
      }
    );
  }

  Future<void> getOwner() async {
    owner = await SharedPreferenceUtil.getUsername();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await SharedPreferenceUtil.getUserId();
    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }
  }

  void fetchGroupMembers() {
    // Fetch full group details để có đầy đủ members cho việc hiển thị tên
    print("🔍 DEBUG - Fetching group members with code: ${widget.group.code}");

    if (widget.group.code.isEmpty) {
      print("❌ ERROR - Group code is empty! Cannot fetch members.");
      return;
    }

    ApiUtil.getInstance()!.get(
      url: "http://localhost:3004/join/${widget.group.code}",
      onSuccess: (response) {
        print("✅ DEBUG - Received response from /join API");
        try {
          final groupData = response.data;
          print("🔍 DEBUG - Response data: $groupData");

          // Parse members từ response
          List<Member> members = [];
          if (groupData["members"] != null) {
            final List<dynamic> membersData = groupData["members"];
            print("🔍 DEBUG - Found ${membersData.length} members in response");
            for (var m in membersData) {
              members.add(Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {}));
            }
          } else {
            print("⚠️ WARNING - groupData['members'] is null!");
          }

          // Update groupMembers state
          if (mounted) {
            setState(() {
              groupMembers = members;
            });
          }

          print("🔍 DEBUG - Loaded ${members.length} members for debt display");
        } catch (e) {
          print("❌ Error parsing group members: $e");
        }
      },
      onError: (error) {
        print("❌ Error fetching group members: $error");
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    print("🔍 DEBUG - initState: group.id=${widget.group.id}, group.code=${widget.group.code}");

    getOwner().then((_) {
      if (mounted) setState(() {});
    });

    // 🔥 Load userId hiện tại
    _loadCurrentUserId();

    // Fetch group members để hiển thị tên trong phần nợ
    fetchGroupMembers();

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
                        members: widget.group.members, // 🔥 Truyền members từ API
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
          widget.group.name,
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
                        Text(widget.joinedMemberName ?? widget.group.memberName ?? (owner.isNotEmpty ? owner : "Bạn"), style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.title)),
                        
                        Text("Nhóm", style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold,)),
                        
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(Common.formatNumber(_myExpense.toString()),
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
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            fetchGroupDetailsAndNavigate();
                          },
                          child: const Text(
                            "Thêm chi tiêu",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20,),

                      // 🔹 Nút View Detail
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ViewReportPage(groupId: widget.group.id, groupName: widget.group.name)),
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
                  
                  const SizedBox(height: 20),
                    
                  // Tab selection
                  Row(
                    children: [
                      _buildTabItem("Giao dịch", 0),
                      _buildTabItem("Khoản nợ", 1),
                    ],
                  ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                color: AppColors.background,
                child: _loading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : (currentTab == 0 
                      ? Column(children: [...buildExpenseList(lists, context)])
                      : _buildDebtList()),
              ),
            ]),
          ),
        ],
      ),
    );
  }
  
  void getSum() {}
  
  void getListMonth() {
    // 🔥 Gọi API để lấy danh sách tháng có dữ liệu từ group expenses
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3001/groups/${widget.group.id}/expenses",
      onSuccess: (response) {
        if (response.data != null && response.data is List) {
          Set<String> monthSet = {};

          // Lấy danh sách tháng từ group expenses
          for (var expense in response.data) {
            try {
              // ✅ Kiểm tra expense là Map trước khi parse
              if (expense is Map<String, dynamic> && expense['dateTime'] != null) {
                DateTime date = DateTime.parse(expense['dateTime'].toString());
                String monthStr = "${date.month.toString().padLeft(2, '0')}/${date.year}";
                monthSet.add(monthStr);
              }
            } catch (e) {
              print("Error parsing date in getListMonth: $e, expense: $expense");
            }
          }

          // Convert Set to List và sort
          List<String> tempMonths = monthSet.toList();
          tempMonths.sort((a, b) {
            var aParts = a.split('/');
            var bParts = b.split('/');
            int aYear = int.parse(aParts[1]);
            int bYear = int.parse(bParts[1]);
            int aMonth = int.parse(aParts[0]);
            int bMonth = int.parse(bParts[0]);

            if (aYear != bYear) return aYear.compareTo(bYear);
            return aMonth.compareTo(bMonth);
          });

          // ✅ Nếu API trả về rỗng, dùng fallback
          if (tempMonths.isEmpty) {
            tempMonths = _generateFallbackMonths();
          }

          if (!mounted) return;
          setState(() {
            months = tempMonths;
            // Nếu tháng hiện tại chưa có trong list, chọn tháng cuối cùng
            if (!months.contains(selectedMonth) && months.isNotEmpty) {
              selectedMonth = months.last;
            }
          });
        }
      },
      onError: (error) {
        print("Error getting months: $error");
        if (!mounted) return;
        setState(() {
          months = _generateFallbackMonths();
        });
      },
    );
  }

  // ⚠️ Helper: Tạo danh sách tháng fallback
  List<String> _generateFallbackMonths() {
    List<String> tempMonths = [];
    DateTime now = DateTime.now();
    for (int i = -6; i <= 6; i++) {
      DateTime d = DateTime(now.year, now.month + i);
      tempMonths.add("${d.month.toString().padLeft(2, '0')}/${d.year}");
    }
    return tempMonths;
  }
  
  void getListTransaction(String nameOfMonth) {
    setState(() {
      _loading = true;
    });
    ApiUtil.getInstance()!.get(
    url: "http://localhost:3001/groups/${widget.group.id}/expenses",
    onSuccess: (response) {
      List<dynamic> jsonList = response.data;
      if (!mounted) return;
      
      final allTransactions = jsonList.map((json) => TransactionModel.fromJson(json)).toList();
      
      // Filter by selected month client-side if API doesn't support it
      final filtered = allTransactions.where((t) {
        final monthStr = "${t.dateTime.month.toString().padLeft(2, '0')}/${t.dateTime.year}";
        return monthStr == nameOfMonth;
      }).toList();

      setState(() {
        lists = filtered;
        _loading = false;
        
        _totalExpense = 0;
        _myExpense = 0;
        for (var t in filtered) {
          _totalExpense += t.amount;
          if (t.owner == owner) {
            _myExpense += t.amount;
          }
        }
      });
    },
    onError: (error) {
      print("Lỗi khi gọi API: $error");
      if (mounted) setState(() => _loading = false);
    },
  );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.green : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.green : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (myDebts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Bạn đang nợ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...myDebts.map((d) => _buildDebtItem(d, false)),
        ],
        if (owedToMe.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Bạn được nợ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...owedToMe.map((d) => _buildDebtItem(d, true)),
        ],
        if (myDebts.isEmpty && owedToMe.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("Không có khoản nợ nào."),
            ),
          ),
      ],
    );
  }

  Widget _buildDebtItem(DebtModel debt, bool isOwedToMe) {
    String memberName = "";
    final targetId = isOwedToMe ? debt.debtorMemberId : debt.paidByMemberId;

    try {
      // Dùng groupMembers state thay vì widget.group.members
      final member = groupMembers.firstWhere((m) => m.id == targetId);
      // 🔥 Hiển thị "(bạn)" nếu đây là user hiện tại
      memberName = member.userId == currentUserId
          ? '${member.name} (bạn)'
          : member.name;
    } catch (e) {
      // Fallback: hiển thị ID nếu không tìm thấy member
      memberName = targetId ?? "Unknown";
      print("⚠️ Không tìm thấy member với ID=$targetId trong ${groupMembers.length} members");
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(debt.expenseTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  isOwedToMe ? "Thành viên: $memberName" : "Trả cho: $memberName",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${Common.formatNumber(debt.shareAmount.toString())} đ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOwedToMe ? Colors.green : Colors.red,
                ),
              ),
              if (isOwedToMe)
                TextButton(
                  onPressed: () => markAsPaid(debt.shareId),
                  child: const Text("Xác nhận đã nhận", style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
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