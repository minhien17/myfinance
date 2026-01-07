import 'dart:async';  // Keep for Timer

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/debt_model.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/models/payment_history_model.dart';
import 'package:my_finance/pages/share/child_page/add_group_expense_page.dart';
import 'package:my_finance/pages/share/child_page/edit_transation_group_page.dart';
import 'package:my_finance/pages/share/child_page/view_report_page.dart';
import 'package:my_finance/pages/share/child_page/view_members_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';
import 'package:my_finance/utils.dart';

import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/member_model.dart';
// import 'package:my_finance/api/sse_service.dart';  // SSE disabled temporarily

class TransactionGroupPage extends StatefulWidget {
  final Group group;
  const TransactionGroupPage({super.key, required this.group});
  @override
  _TransactionGroupPageState createState() => _TransactionGroupPageState();
}

class _TransactionGroupPageState extends State<TransactionGroupPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final now = DateTime.now();
  late ScrollController _scrollController;

  String selectedMonth = '';
  
  List<String> months = [];
  List<TransactionModel> lists = [];
  List<PaymentItem> paymentsList = []; // Danh sách payment từ payment-history API
  bool _loading = true;

  List<DebtModel> myDebts = [];
  List<DebtModel> owedToMe = [];
  int currentTab = 0; // 0: Transactions, 1: Debts

  double _totalExpense = 0;
  double _myExpense = 0;
  PaymentSummary? paymentSummary; // Tổng kết từ payment-history API
  String owner = '';
  String currentUserId = ''; // 🔥 userId của người đang đăng nhập

  List<Member> groupMembers = []; // Lưu danh sách members để hiển thị tên trong phần nợ

  // State để lưu thông tin group có thể thay đổi
  late String groupName;
  late String groupCode;
  late String? groupOwnerId;

  // 🔄 Polling timer for real-time updates
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 10);

  // Flag to prevent double navigation when user deletes group themselves
  bool _isLeavingPage = false;

  void reLoadPage(){
    getListMonth();
    getListTransaction(selectedMonth);
    fetchDebts(selectedMonth);
  }

  // 🔄 Polling: Start periodic refresh
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      if (mounted && !_isLeavingPage) {
        print('🔄 Polling: Refreshing group data...');
        _pollData();
      }
    });
    print('🔄 Polling: Started with interval ${_pollingInterval.inSeconds}s');
  }

  // 🔄 Polling: Stop periodic refresh
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print('🔄 Polling: Stopped');
  }

  // 🔄 Poll data without showing loading indicator
  void _pollData() {
    // Refresh transactions and debts
    getListTransaction(selectedMonth);
    fetchDebts(selectedMonth);
    // Refresh members
    fetchGroupMembers();
  }

  Future<void> fetchDebts(String monthYear) async {
    // Parse monthYear format "MM/YYYY" to get month and year
    final parts = monthYear.split('/');
    if (parts.length != 2) return;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null) return;

    // GET /groups/{groupId}/expenses/my-debts
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpenseMyDebts(widget.group.id),
      onSuccess: (response) {
        final List<dynamic> data = response.data;
        final allDebts = data.map((e) => DebtModel.fromJson(e)).toList();

        // Filter by selected month
        final filteredDebts = allDebts.where((debt) {
          if (debt.createdAt == null) return false;
          return debt.createdAt!.month == month && debt.createdAt!.year == year;
        }).toList();

        setState(() {
          myDebts = filteredDebts;
        });
      },
      onError: (err) => print("Fetch debts error: $err"),
    );

    // GET /groups/{groupId}/expenses/owed-to-me
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpenseOwedToMe(widget.group.id),
      onSuccess: (response) {
        final List<dynamic> data = response.data;
        final allOwed = data.map((e) => DebtModel.fromJson(e)).toList();

        // Filter by selected month
        final filteredOwed = allOwed.where((debt) {
          if (debt.createdAt == null) return false;
          return debt.createdAt!.month == month && debt.createdAt!.year == year;
        }).toList();

        setState(() {
          owedToMe = filteredOwed;
        });
      },
      onError: (err) => print("Fetch owed error: $err"),
    );
  }

  void navigateToAddTransaction() {
    // Tạo Group mới với members được cập nhật từ API (groupMembers)
    // thay vì dùng widget.group.members (dữ liệu cũ)
    final updatedGroup = Group(
      id: widget.group.id,
      name: groupName,
      code: groupCode,
      number: groupMembers.where((m) => m.joined).length,
      totalMembers: groupMembers.length,
      members: groupMembers,
      memberName: widget.group.memberName,
      ownerId: groupOwnerId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGroupExpensePage(group: updatedGroup)),
    ).then((result) {
      // Luôn reload page và members khi quay lại
      reLoadPage();
      fetchGroupMembers();
    });
  }

  void markAsPaid(String shareId, {String? memberName, double? amount, String? expenseTitle}) {
    showLoading(context);
    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.groupExpenseMarkPaid(widget.group.id),
      body: {"shareId": shareId},
      onSuccess: (response) {
        hideLoading();
        reLoadPage();
        _showPaymentSuccessDialog(
          memberName: memberName ?? 'Thành viên',
          amount: amount ?? 0,
          expenseTitle: expenseTitle ?? '',
        );
      },
      onError: (err) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $err')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    );
  }

  void _showPaymentSuccessDialog({
    required String memberName,
    required double amount,
    required String expenseTitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon thành công
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                // Tiêu đề
                const Text(
                  'Xác nhận thành công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Thông tin chi tiết
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Từ: ',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          Expanded(
                            child: Text(
                              memberName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Số tiền: ',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          Expanded(
                            child: Text(
                              '${Common.formatNumber(amount.toString())}đ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      if (expenseTitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 18, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Khoản: ',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Expanded(
                              child: Text(
                                expenseTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Nút đóng
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Hoàn tất',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  void initGroupMembers() {
    // Sử dụng members có sẵn từ widget.group thay vì gọi API
    // vì widget.group.members đã có đầy đủ thông tin (id, name, userId, joined)
    if (mounted) {
      setState(() {
        groupMembers = widget.group.members ?? [];
      });
      print("🔍 DEBUG - Loaded ${groupMembers.length} members from widget.group");
      if (groupMembers.isNotEmpty) {
        print("📋 Members: ${groupMembers.map((m) => '${m.id}:${m.name}').join(', ')}");
      }
    }
  }

  // Fetch members và thông tin group từ API /my để cập nhật danh sách mới nhất
  void fetchGroupMembers() {
    print("🔄 Calling fetchGroupMembers for group: ${widget.group.id}");
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupMy,
      onSuccess: (response) {
        print("✅ fetchGroupMembers response from /my");
        if (!mounted) return;

        // Tìm group hiện tại trong danh sách
        final List<dynamic> groups = response.data ?? [];
        final currentGroup = groups.firstWhere(
          (g) => (g['id'] ?? g['groupId'])?.toString() == widget.group.id,
          orElse: () => null,
        );

        if (currentGroup != null) {
          // Cập nhật thông tin group
          final newOwnerId = (currentGroup['ownerId'] ?? currentGroup['ownerUserId'] ?? currentGroup['createdByUserId'])?.toString();
          final newGroupName = currentGroup['name']?.toString() ?? groupName;

          // Cập nhật members
          List<Member> fetchedMembers = [];
          if (currentGroup['members'] != null) {
            final List<dynamic> membersData = currentGroup['members'];
            fetchedMembers = membersData.map((m) {
              return Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {});
            }).toList();
          }

          setState(() {
            groupMembers = fetchedMembers;
            groupName = newGroupName;
            groupOwnerId = newOwnerId;
          });

          print("🔄 Fetched group info: name=$groupName, ownerId=$groupOwnerId, members=${groupMembers.length}");
        }
      },
      onError: (error) {
        print("❌ Error fetching members: $error");
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _scrollController = ScrollController();

    // Khởi tạo state từ widget.group
    groupName = widget.group.name;
    groupCode = widget.group.code;
    groupOwnerId = widget.group.ownerId;

    print("🔍 DEBUG - initState: group.id=${widget.group.id}, group.code=${widget.group.code}, group.members.length=${widget.group.members.length}");

    getOwner().then((_) {
      if (mounted) setState(() {});
    });

    // 🔥 Load userId hiện tại
    _loadCurrentUserId();

    // Sử dụng members có sẵn ban đầu
    print("🔍 DEBUG - About to call initGroupMembers with ${widget.group.members.length} members");
    initGroupMembers();

    // Gọi API để lấy danh sách members mới nhất (quan trọng khi vừa join group)
    fetchGroupMembers();

    selectedMonth = '${now.month.toString().padLeft(2, '0')}/${now.year}';
    setState(() {
      // Cuộn ListView đến cuối
      _scrollToEnd();
    });
    reLoadPage();

    // 🔄 Polling: Start periodic refresh
    _startPolling();
  }

  @override
  void dispose() {
    // 🔄 Polling: Stop periodic refresh
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Auto-refresh when app resumes
    if (state == AppLifecycleState.resumed) {
      print("🔄 App resumed - Auto refreshing data");
      reLoadPage();
    }
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
                            titleOf(expense.category),
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

  // Helper function để lấy tên member từ memberId
  String _getMemberName(String? memberId, {String defaultName = 'Thành viên đã rời'}) {
    if (memberId == null || memberId.isEmpty) {
      return defaultName;
    }

    try {
      final member = groupMembers.firstWhere((m) => m.id == memberId);
      // Hiển thị "(bạn)" nếu đây là user hiện tại
      return member.userId == currentUserId
          ? '${member.name} (bạn)'
          : member.name;
    } catch (e) {
      print('⚠️ Member not found for id=$memberId. Available: ${groupMembers.map((m) => m.id).join(', ')}');
      return defaultName;
    }
  }

  // 🔥 Hàm hiển thị payment history theo ngày
  List<Widget> buildPaymentHistoryList(List<PaymentItem> payments, BuildContext context) {
    // 1️⃣ Gom nhóm theo ngày (YYYY-MM-DD)
    Map<String, List<PaymentItem>> grouped = {};
    for (var payment in payments) {
      String dateKey = payment.date.toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(payment);
    }

    // 2️⃣ Tạo danh sách Widget cho từng nhóm
    List<Widget> containers = grouped.entries.map((entry) {
      String dateKey = entry.key;
      List<PaymentItem> dailyPayments = entry.value;

      // Chuyển dateKey -> DateTime để hiển thị
      DateTime date = DateTime.parse(dateKey);

      // ✅ Tính tổng tiền trong ngày
      double totalAmount = dailyPayments.fold(
        0,
        (sum, p) => sum + p.amount,
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
                const SizedBox(width: 5),
              ],
            ),

            const SizedBox(height: 10),

            // 3️⃣ Danh sách payment trong ngày đó
            ...dailyPayments.map((payment) {
              // Xác định màu dựa trên type (paid = đỏ, received = xanh)
              final Color amountColor = payment.type == "paid" ? Colors.red : Colors.green;
              final String typeText = payment.type == "paid" ? "Đã trả" : "Đã nhận";

              // Debug log
              if (payment.type == "paid") {
                print("🔍 Payment: ${payment.expenseTitle}, to=${payment.to}, toMemberId=${payment.toMemberId}");
              }

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
                child: Row(
                  children: [
                    itemLeading(payment.category),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hiển thị tên danh mục
                          Text(
                            titleOf(payment.category),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          // Hiển thị note/description nếu có và khác category
                          if (payment.expenseTitle.isNotEmpty &&
                              payment.expenseTitle != payment.category)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                payment.expenseTitle,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ),
                          Text(
                            payment.type == "paid"
                                ? "$typeText • ${(payment.to?.isNotEmpty == true) ? payment.to! : ((payment.toMemberId?.isNotEmpty == true) ? _getMemberName(payment.toMemberId) : 'cho nhóm')}"
                                : "$typeText • ${(payment.from?.isNotEmpty == true) ? payment.from! : ((payment.fromMemberId?.isNotEmpty == true) ? _getMemberName(payment.fromMemberId) : 'từ nhóm')}",
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      Common.formatNumber(payment.amount.toString()),
                      style: TextStyle(color: amountColor, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
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
          groupName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
  PopupMenuButton<String>(
    // 1. Giữ nguyên icon cũ của bạn
    icon: const Icon(Icons.more_vert), 
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: AppColors.background,
    ),
    // 2. Xử lý logic khi người dùng chọn menu
    onSelected: (String value) {
      if (value == 'add_member') {
        _showAddMemberSheet();
      } else if (value == 'out_group') {
        _showLeaveGroupDialog();
      } else if (value == 'transfer_ownership') {
        _showTransferOwnershipDialog();
      } else if (value == 'delete_group') {
        _showDeleteGroupDialog();
      }
    },
    
    // 3. Định nghĩa danh sách các lựa chọn trong menu
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      // Lựa chọn 1: Thêm người
      const PopupMenuItem<String>(
        value: 'add_member',
        child: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.blackIcon),
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
            Icon(Icons.remove, color: AppColors.blackIcon),
            SizedBox(width: 12),
            Text('Rời nhóm'),
          ],
        ),
      ),
      // Lựa chọn 4: Chuyển quyền trưởng nhóm (chỉ hiện nếu là chủ nhóm)
      if (groupOwnerId == currentUserId)
        const PopupMenuItem<String>(
          value: 'transfer_ownership',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.blackIcon),
              SizedBox(width: 12),
              Text('Chuyển quyền trưởng nhóm'),
            ],
          ),
        ),
      // Lựa chọn 5: Xóa nhóm (chỉ hiện nếu là chủ nhóm)
      if (groupOwnerId == currentUserId)
        const PopupMenuItem<String>(
          value: 'delete_group',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 12),
              Text('Xóa nhóm', style: TextStyle(color: Colors.red)),
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
      body: RefreshIndicator(
        onRefresh: () async {
          reLoadPage();
          fetchGroupMembers();
        },
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Đảm bảo luôn có thể kéo để refresh
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
                        fetchDebts(selectedMonth);
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
              // Summary Card
              _buildSummaryCard(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.white,
                child: Column(
                  children: [
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
                            navigateToAddTransaction();
                          },
                          child: const Text(
                            "Thêm khoản",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20,),

                      // 🔹 Nút View Members
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
                            final membersToPass = groupMembers.isNotEmpty
                                ? groupMembers
                                : widget.group.members;
                            print("🔍 DEBUG - Navigating to ViewMembersPage with ${membersToPass.length} members");
                            print("📋 Members to pass: ${membersToPass.map((m) => '${m.id}:${m.name}:joined=${m.joined}').join(', ')}");

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewMembersPage(
                                  groupId: widget.group.id,
                                  groupName: groupName,
                                  members: membersToPass,
                                  currentUserId: currentUserId,
                                  ownerId: groupOwnerId,
                                ),
                              ),
                            ).then((_) {
                              // Refresh lại danh sách members khi quay lại
                              fetchGroupMembers();
                            });
                          },
                          child: const Text(
                            "thành viên",
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
                padding: const EdgeInsets.only(top: 15, bottom: 20),
                color: AppColors.background,
                child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (currentTab == 0
                      ? Column(children: [...buildPaymentHistoryList(paymentsList, context)])
                      : _buildDebtList()),
              ),
            ]),
          ),
        ],
      ),
      ),
    );
  }

  void getSum() {}
  
  void getListMonth() {
    Set<String> monthSet = {};
    int completedCalls = 0;
    const int totalCalls = 3; // expenses, my-debts, owed-to-me

    void updateMonths() {
      completedCalls++;
      if (completedCalls < totalCalls) return;

      // Luôn thêm tháng hiện tại
      final now = DateTime.now();
      final currentMonthStr = "${now.month.toString().padLeft(2, '0')}/${now.year}";
      monthSet.add(currentMonthStr);

      // Tất cả API đã hoàn thành - cập nhật UI
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

      if (!mounted) return;
      setState(() {
        months = tempMonths;
        // Nếu selectedMonth chưa có trong list, chọn tháng hiện tại
        if (!months.contains(selectedMonth)) {
          selectedMonth = currentMonthStr;
        }
      });
    }

    void extractMonthsFromList(List<dynamic> data, String dateField) {
      for (var item in data) {
        try {
          if (item is Map<String, dynamic> && item[dateField] != null) {
            DateTime date = DateTime.parse(item[dateField].toString());
            String monthStr = "${date.month.toString().padLeft(2, '0')}/${date.year}";
            monthSet.add(monthStr);
          }
        } catch (e) {
          print("Error parsing date: $e");
        }
      }
    }

    // 1. Lấy tháng từ expenses
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpenses(widget.group.id),
      onSuccess: (response) {
        if (response.data != null && response.data is List) {
          extractMonthsFromList(response.data, 'dateTime');
        }
        updateMonths();
      },
      onError: (error) {
        print("Error getting expenses months: $error");
        updateMonths();
      },
    );

    // 2. Lấy tháng từ my-debts
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpenseMyDebts(widget.group.id),
      onSuccess: (response) {
        if (response.data != null && response.data is List) {
          extractMonthsFromList(response.data, 'createdAt');
        }
        updateMonths();
      },
      onError: (error) {
        print("Error getting my-debts months: $error");
        updateMonths();
      },
    );

    // 3. Lấy tháng từ owed-to-me
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpenseOwedToMe(widget.group.id),
      onSuccess: (response) {
        if (response.data != null && response.data is List) {
          extractMonthsFromList(response.data, 'createdAt');
        }
        updateMonths();
      },
      onError: (error) {
        print("Error getting owed-to-me months: $error");
        updateMonths();
      },
    );
  }

  void getListTransaction(String nameOfMonth) {
    setState(() {
      _loading = true;
    });

    // 🔥 Gọi API payment-history mới
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpensePaymentHistory(widget.group.id),
      params: {
        "monthYear": nameOfMonth, // Format: "MM/YYYY"
      },
      onSuccess: (response) {
        if (!mounted) return;

        print("✅ Payment history response: ${response.data}");

        final paymentHistory = PaymentHistoryModel.fromJson(response.data);

        // Debug: Print each payment's to/from fields
        for (var payment in paymentHistory.payments) {
          print('🔍 Payment: type=${payment.type}, to="${payment.to}", from="${payment.from}", toMemberId=${payment.toMemberId}, fromMemberId=${payment.fromMemberId}');
        }

        setState(() {
          paymentsList = paymentHistory.payments;
          paymentSummary = paymentHistory.summary;
          _loading = false;

          // Cập nhật tổng chi tiêu từ summary
          _totalExpense = paymentHistory.summary.totalPaid;
          _myExpense = paymentHistory.summary.totalPaid; // Hoặc có thể lấy từ net
        });
      },
      onError: (error) {
        print("❌ Lỗi khi gọi payment-history API: $error");
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

  // Summary Card hiển thị ở đầu trang (dưới thanh chọn tháng)
  Widget _buildSummaryCard() {
    double totalMyDebt = myDebts.fold(0, (sum, d) => sum + d.shareAmount);
    double totalOwedToMe = owedToMe.fold(0, (sum, d) => sum + d.shareAmount);
    double netBalance = totalOwedToMe - totalMyDebt;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: netBalance >= 0
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (netBalance >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            netBalance >= 0 ? 'Bạn được nhận lại' : 'Bạn cần trả',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Common.formatNumber(netBalance.abs().toString())}đ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.arrow_upward,
                label: 'Được nợ',
                amount: totalOwedToMe,
                color: Colors.white,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              _buildSummaryItem(
                icon: Icons.arrow_downward,
                label: 'Đang nợ',
                amount: totalMyDebt,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empty state
        if (myDebts.isEmpty && owedToMe.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Không có khoản nợ nào",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mọi khoản chi tiêu đã được thanh toán",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),

        // 1. Nhóm "Bạn được nợ" (hiển thị trước vì quan trọng hơn)
        if (owedToMe.isNotEmpty) ...[
          _buildDebtSection(
            title: "Người khác nợ bạn",
            subtitle: "${owedToMe.length} khoản",
            icon: Icons.arrow_circle_down,
            color: Colors.green,
            debts: owedToMe,
            isOwedToMe: true,
          ),
        ],

        // 2. Nhóm "Bạn đang nợ"
        if (myDebts.isNotEmpty) ...[
          _buildDebtSection(
            title: "Bạn đang nợ",
            subtitle: "${myDebts.length} khoản",
            icon: Icons.arrow_circle_up,
            color: Colors.red,
            debts: myDebts,
            isOwedToMe: false,
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${Common.formatNumber(amount.toString())}đ',
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDebtSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<DebtModel> debts,
    required bool isOwedToMe,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${Common.formatNumber(debts.fold(0.0, (sum, d) => sum + d.shareAmount).toString())}đ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // List items
          ...debts.map((debt) => _buildDebtItemNew(debt, isOwedToMe)),
        ],
      ),
    );
  }

  Widget _buildDebtItemNew(DebtModel debt, bool isOwedToMe) {
    final targetId = isOwedToMe ? debt.debtorMemberId : debt.paidByMemberId;
    // Sử dụng tên từ API nếu có, nếu không thì tìm trong groupMembers
    String memberName = isOwedToMe
        ? (debt.debtorName ?? "")
        : (debt.paidByName ?? "");

    if (memberName.isEmpty) {
      try {
        final member = groupMembers.firstWhere((m) => m.id == targetId);
        memberName = member.userId == currentUserId
            ? '${member.name} (bạn)'
            : member.name;
      } catch (e) {
        memberName = "Thành viên đã rời";
      }
    } else if (targetId != null) {
      // Kiểm tra nếu là user hiện tại
      try {
        final member = groupMembers.firstWhere((m) => m.id == targetId);
        if (member.userId == currentUserId) {
          memberName = '$memberName (bạn)';
        }
      } catch (e) {
        // Không tìm thấy member, giữ nguyên tên từ API
      }
    }

    // Format ngày
    String dateStr = "";
    if (debt.createdAt != null) {
      final d = debt.createdAt!;
      dateStr = "${d.day}/${d.month}";
    }

    return InkWell(
      onTap: isOwedToMe ? () => _showConfirmPaymentSheet(debt, memberName) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isOwedToMe
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Text(
                memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isOwedToMe ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debt.expenseTitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            // Amount + Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Common.formatNumber(debt.shareAmount.toString())}đ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOwedToMe ? Colors.green : Colors.red,
                  ),
                ),
                if (isOwedToMe)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Nhấn để xác nhận',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet thêm thành viên
  void _showAddMemberSheet() {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    Timer? debounceTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void searchUsers(String query) {
            if (query.trim().isEmpty) {
              setSheetState(() {
                searchResults = [];
                isSearching = false;
              });
              return;
            }

            setSheetState(() => isSearching = true);

            ApiUtil.getInstance()!.get(
              url: ApiEndpoint.authUsersSearch,
              params: {"q": query.trim()},
              onSuccess: (response) {
                final List<dynamic> data = response.data ?? [];
                setSheetState(() {
                  searchResults = data.map((u) => Map<String, dynamic>.from(u)).toList();
                  isSearching = false;
                });
              },
              onError: (error) {
                print("Search error: $error");
                setSheetState(() => isSearching = false);
              },
            );
          }

          void addMemberToGroup(Map<String, dynamic> user) {
            final userId = user["id"] ?? user["userId"] ?? "";
            final memberName = user["username"] ?? user["name"] ?? "Unknown";

            print("🔍 addMemberToGroup - user data: $user");
            print("🔍 addMemberToGroup - userId: $userId, memberName: $memberName");

            showLoading(context);
            ApiUtil.getInstance()!.post(
              url: ApiEndpoint.groupMembers(widget.group.id),
              body: {
                "userId": userId,
                "memberName": memberName,
              },
              onSuccess: (response) {
                hideLoading();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Đã thêm $memberName vào nhóm'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                // Reload members từ API
                fetchGroupMembers();
              },
              onError: (error) {
                hideLoading();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Lỗi: $error')),
                      ],
                    ),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            );
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Thêm thành viên',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // Search input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setSheetState(() {
                                  searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.green, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      debounceTimer?.cancel();
                      debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        searchUsers(value);
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Results
                Expanded(
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchController.text.isEmpty
                                        ? 'Nhập tên để tìm kiếm'
                                        : 'Không tìm thấy người dùng',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final user = searchResults[index];
                                final userId = user["id"] ?? user["userId"] ?? "";
                                final username = user["username"] ?? user["name"] ?? "Unknown";
                                final email = user["email"] ?? "";

                                // Check if already member
                                final isAlreadyMember = groupMembers.any((m) => m.userId == userId);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isAlreadyMember ? Colors.grey.shade100 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isAlreadyMember
                                          ? Colors.grey.shade300
                                          : AppColors.green.withOpacity(0.2),
                                      child: Text(
                                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: isAlreadyMember ? Colors.grey : AppColors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      username,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: email.isNotEmpty
                                        ? Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12))
                                        : null,
                                    trailing: isAlreadyMember
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Đã là thành viên',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: () => addMemberToGroup(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                            ),
                                            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
                                          ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Bottom sheet xác nhận thanh toán
  void _showConfirmPaymentSheet(DebtModel debt, String memberName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Xác nhận đã nhận tiền?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
                children: [
                  TextSpan(
                    text: memberName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const TextSpan(text: ' đã trả cho bạn '),
                  TextSpan(
                    text: '${Common.formatNumber(debt.shareAmount.toString())}đ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const TextSpan(text: '\ncho khoản "'),
                  TextSpan(
                    text: debt.expenseTitle,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const TextSpan(text: '"'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      markAsPaid(
                        debt.shareId,
                        memberName: memberName,
                        amount: debt.shareAmount,
                        expenseTitle: debt.expenseTitle,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xác nhận đã nhận',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Dialog xác nhận rời nhóm
  void _showLeaveGroupDialog() {
    // Đếm số thành viên đã join
    final joinedMembers = groupMembers.where((m) => m.joined == true).toList();
    final isLastMember = joinedMembers.length <= 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLastMember ? Colors.red.shade50 : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLastMember ? Icons.delete_forever : Icons.exit_to_app,
                size: 48,
                color: isLastMember ? Colors.red.shade400 : Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isLastMember ? 'Rời và xóa nhóm?' : 'Rời nhóm?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              isLastMember
                  ? 'Bạn là thành viên cuối cùng của nhóm "${groupName}".\n\nKhi bạn rời đi, nhóm sẽ tự động bị xóa cùng tất cả dữ liệu.'
                  : 'Bạn có chắc muốn rời khỏi nhóm "${groupName}"?\n\nBạn sẽ không thể xem các khoản chi tiêu và nợ của nhóm nữa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _leaveGroup(isLastMember);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastMember ? Colors.red : Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLastMember ? 'Rời và xóa nhóm' : 'Rời nhóm',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Gọi API rời nhóm
  void _leaveGroup(bool willDeleteGroup) {
    // Set flag BEFORE API call to prevent SSE from triggering pop
    _isLeavingPage = true;
    showLoading(context);
    ApiUtil.getInstance()!.delete(
      url: ApiEndpoint.groupLeave(widget.group.id),
      onSuccess: (response) {
        hideLoading();

        final data = response.data;
        final bool deleted = data['deleted'] == true;
        final bool transferred = data['transferred'] == true;
        final String? newOwnerName = data['newOwnerName'];

        String message;
        if (deleted) {
          message = 'Nhóm đã bị xoá (không còn thành viên)';
        } else if (transferred) {
          message = 'Đã rời nhóm. Quyền trưởng nhóm chuyển cho $newOwnerName';
        } else {
          message = 'Đã rời khỏi nhóm "${groupName}"';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Quay về trang SharePage
        Navigator.pop(context, true);
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $error')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  // Dialog xác nhận xóa nhóm (chỉ chủ nhóm)
  void _showDeleteGroupDialog() {
    // Kiểm tra quyền chủ nhóm
    if (groupOwnerId != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Chỉ chủ nhóm mới có thể xóa nhóm'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon cảnh báo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Xóa nhóm?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Bạn có chắc muốn xóa nhóm "${groupName}"?\n\nHành động này không thể hoàn tác. Tất cả dữ liệu chi tiêu, nợ và thành viên sẽ bị xóa vĩnh viễn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteGroup();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xóa nhóm',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Dialog chuyển quyền trưởng nhóm
  void _showTransferOwnershipDialog() {
    // Lọc danh sách thành viên đã tham gia (trừ current user)
    final eligibleMembers = groupMembers.where((m) =>
      m.joined == true && m.userId != currentUserId
    ).toList();

    if (eligibleMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Không có thành viên nào khác để chuyển quyền'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 32,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chuyển quyền trưởng nhóm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn thành viên để nhận quyền trưởng nhóm',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Member list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: eligibleMembers.length,
                itemBuilder: (context, index) {
                  final member = eligibleMembers[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.green.withOpacity(0.2),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: member.userId != null
                        ? Text(
                            'ID: ${member.userId!.substring(0, member.userId!.length > 8 ? 8 : member.userId!.length)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          )
                        : null,
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmTransferOwnership(member);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog xác nhận chuyển quyền
  void _confirmTransferOwnership(Member newOwner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            const Expanded(child: Text('Xác nhận chuyển quyền')),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
            children: [
              const TextSpan(text: 'Bạn có chắc muốn chuyển quyền trưởng nhóm cho '),
              TextSpan(
                text: newOwner.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const TextSpan(text: '?\n\nSau khi chuyển, bạn sẽ trở thành thành viên thường.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _transferOwnership(newOwner);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Gọi API chuyển quyền trưởng nhóm
  void _transferOwnership(Member newOwner) {
    showLoading(context);
    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.groupTransferOwnership(widget.group.id),
      body: {
        "newOwnerUserId": newOwner.userId,
      },
      onSuccess: (response) {
        hideLoading();

        // Cập nhật local state
        setState(() {
          groupOwnerId = newOwner.userId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Đã chuyển quyền trưởng nhóm cho ${newOwner.name}')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Reload để cập nhật UI
        fetchGroupMembers();
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $error')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }

  // Gọi API xóa nhóm
  void _deleteGroup() {
    // Set flag BEFORE API call to prevent SSE GROUP_DELETED from triggering pop
    _isLeavingPage = true;
    showLoading(context);
    ApiUtil.getInstance()!.delete(
      url: ApiEndpoint.groupById(widget.group.id),
      onSuccess: (response) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Đã xóa nhóm thành công'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        // Quay về trang trước (share_page)
        Navigator.pop(context, true); // true = đã xóa, cần refresh
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $error')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      },
    );
  }
}

Widget itemLeading(String type) {
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