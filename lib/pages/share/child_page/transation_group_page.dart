import 'dart:async';  // For Timer (debounce)
import 'dart:io';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/debt_model.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/models/payment_history_model.dart';
import 'package:my_finance/models/my_expense_model.dart';
import 'package:my_finance/pages/share/child_page/add_group_expense_page.dart';
import 'package:my_finance/pages/share/child_page/edit_transation_group_page.dart';
import 'package:my_finance/pages/share/child_page/view_report_page.dart';
import 'package:my_finance/pages/share/child_page/view_members_page.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/services/websocket_service.dart';
import 'package:my_finance/shared_preference.dart';
import 'package:my_finance/utils.dart';

import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/member_model.dart';

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
  List<MyExpenseModel> myExpensesList = []; // Danh sách expenses từ my-expenses API
  MyExpensesSummary? myExpensesSummary; // Tổng kết từ my-expenses API
  bool _loading = true;

  List<DebtModel> myDebts = [];
  List<DebtModel> owedToMe = [];
  int currentTab = 0; // 0: Transactions, 1: Debts

  double _totalExpense = 0;
  double _myExpense = 0;
  PaymentSummary? paymentSummary; // Tổng kết từ payment-history API
  String owner = '';
  String currentUserId = ''; // 🔥 userId của người đang đăng nhập
  String currentMemberId = ''; // 🔥 memberId của user trong group này

  List<Member> groupMembers = []; // Lưu danh sách members để hiển thị tên trong phần nợ

  // Danh sách lời mời đang chờ của group (cho owner)
  List<Map<String, dynamic>> _groupPendingInvitations = [];

  // State để lưu thông tin group có thể thay đổi
  late String groupName;
  late String groupCode;
  late String? groupOwnerId;

  // Flag to prevent double navigation when user deletes group themselves
  bool _isLeavingPage = false;

  // 🔌 WebSocket service
  final WebSocketService _wsService = WebSocketService();

  // 📷 Image picker cho upload ảnh chứng minh
  final ImagePicker _imagePicker = ImagePicker();

  void reLoadPage(){
    getListMonth();
    getListTransaction(selectedMonth);
    // 🔥 Không cần gọi fetchDebts riêng vì mapExpensesToDebts()
    // đã được gọi trong getListTransaction sau khi có data
  }

  /// 🔥 Map từ myExpensesList sang myDebts và owedToMe
  /// - myDebts: User nợ người khác (người khác trả, user có share chưa thanh toán)
  /// - owedToMe: Người khác nợ user (user trả, người khác có share chưa thanh toán)
  void mapExpensesToDebts() {
    List<DebtModel> newMyDebts = [];
    List<DebtModel> newOwedToMe = [];

    print("🔍 mapExpensesToDebts - currentMemberId: $currentMemberId");
    print("🔍 myExpensesList count: ${myExpensesList.length}");

    // Nếu chưa có currentMemberId, không thể map
    if (currentMemberId.isEmpty) {
      print("⚠️ currentMemberId chưa được load, bỏ qua mapping");
      return;
    }

    for (var expense in myExpensesList) {
      // 🔥 Debug: In ra tất cả shares của expense
      print("📋 Expense: ${expense.title}");
      print("   paidByMemberId: ${expense.paidByMemberId}");
      print("   shares count: ${expense.shares.length}");
      for (var share in expense.shares) {
        print("   - Share: memberId=${share.memberId}, memberName=${share.memberName}, amount=${share.amount}, isPaid=${share.isPaid}");
      }

      // 🔥 Tìm share của user hiện tại bằng currentMemberId
      ExpenseShare? myShare;
      try {
        myShare = expense.shares.firstWhere(
          (s) => s.memberId == currentMemberId,
        );
      } catch (e) {
        myShare = null;
      }

      // 🔥 Xác định user có phải người trả không
      final bool isPayer = expense.paidByMemberId == currentMemberId;

      print("   myShare found: ${myShare != null}, isPayer: $isPayer");

      if (isPayer) {
        // User là người trả -> tìm những người khác chưa thanh toán (owedToMe)
        for (var share in expense.shares) {
          // Bỏ qua share của chính user
          if (share.memberId == currentMemberId) continue;
          // Chỉ lấy những share chưa thanh toán
          if (!share.isPaid) {
            print("  ➕ owedToMe: ${share.memberName} owes ${share.amount}");
            newOwedToMe.add(DebtModel(
              shareId: share.id,
              expenseId: expense.id,
              expenseTitle: expense.title.isNotEmpty ? expense.title : 'Chi tiêu nhóm',
              totalAmount: expense.totalAmount,
              shareAmount: share.amount,
              debtorMemberId: share.memberId,
              debtorName: share.memberName,
              isPaid: share.isPaid,
              createdAt: expense.createdAt,
              // 📷 Copy proof fields
              proofImageUrl: share.proofImageUrl,
              proofStatus: share.proofStatus,
              proofUploadedAt: share.proofUploadedAt,
            ));
          }
        }
      } else if (myShare != null && !myShare.isPaid) {
        // User không phải người trả VÀ user có share chưa thanh toán -> myDebts
        print("  ➕ myDebts: I owe ${expense.paidByMemberName} ${myShare.amount}");
        newMyDebts.add(DebtModel(
          shareId: myShare.id,
          expenseId: expense.id,
          expenseTitle: expense.title.isNotEmpty ? expense.title : 'Chi tiêu nhóm',
          totalAmount: expense.totalAmount,
          shareAmount: myShare.amount,
          paidByMemberId: expense.paidByMemberId,
          paidByName: expense.paidByMemberName,
          isPaid: myShare.isPaid,
          createdAt: expense.createdAt,
          // 📷 Copy proof fields
          proofImageUrl: myShare.proofImageUrl,
          proofStatus: myShare.proofStatus,
          proofUploadedAt: myShare.proofUploadedAt,
        ));
      }
    }

    print("✅ Result - myDebts: ${newMyDebts.length}, owedToMe: ${newOwedToMe.length}");

    setState(() {
      myDebts = newMyDebts;
      owedToMe = newOwedToMe;
    });
  }

  Future<void> fetchDebts(String monthYear) async {
    // 🔥 Sử dụng dữ liệu từ myExpensesList thay vì gọi API riêng
    // Hàm này được gọi sau khi getListTransaction hoàn thành
    mapExpensesToDebts();
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
      // 🔥 Sau khi có userId, gọi API lấy memberId của user trong group này
      _loadCurrentMemberId();
    }
  }

  /// 🔥 Gọi API lấy memberId của user trong group này
  void _loadCurrentMemberId() {
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupMyMemberId(widget.group.id),
      onSuccess: (response) {
        if (!mounted) return;
        // Response có thể là: { "memberId": "123" } hoặc trực tiếp "123"
        String? memberId;
        if (response.data is Map) {
          memberId = response.data['memberId']?.toString();
        } else {
          memberId = response.data?.toString();
        }
        if (memberId != null) {
          setState(() {
            currentMemberId = memberId!;
          });
          print("🔥 currentMemberId loaded: $currentMemberId");
          // Sau khi có memberId, map lại debts nếu đã có data
          if (myExpensesList.isNotEmpty) {
            mapExpensesToDebts();
          }
        }
      },
      onError: (error) {
        print("❌ Error loading currentMemberId: $error");
      },
    );
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

          // Fetch pending invitations nếu là owner
          _fetchGroupPendingInvitations();
        }
      },
      onError: (error) {
        print("❌ Error fetching members: $error");
      },
    );
  }

  // Lấy danh sách lời mời đang chờ của group (cho owner)
  void _fetchGroupPendingInvitations() {
    // Chỉ fetch nếu là owner
    if (currentUserId.isEmpty || groupOwnerId != currentUserId) {
      setState(() {
        _groupPendingInvitations = [];
      });
      return;
    }

    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupInvitations(widget.group.id),
      onSuccess: (response) {
        if (!mounted) return;
        try {
          final List<dynamic> data = response.data ?? [];
          setState(() {
            _groupPendingInvitations = data.map((item) => Map<String, dynamic>.from(item)).toList();
          });
          print('📨 Fetched ${_groupPendingInvitations.length} pending invitations for group');
        } catch (e) {
          print('Error parsing group pending invitations: $e');
        }
      },
      onError: (error) {
        print('Error fetching group pending invitations: $error');
      },
    );
  }

  // Hủy lời mời
  void _cancelInvitation(String invitationId) {
    showLoading(context);
    ApiUtil.getInstance()!.delete(
      url: ApiEndpoint.groupInvitationCancel(widget.group.id, invitationId),
      onSuccess: (response) {
        hideLoading();
        _fetchGroupPendingInvitations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy lời mời'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $error'),
            backgroundColor: Colors.red,
          ),
        );
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

    // 🔌 WebSocket: Setup listeners
    _setupWebSocket();
  }

  // 🔌 WebSocket: Setup và đăng ký listeners cho group này
  void _setupWebSocket() {
    _wsService.connect();

    // Join room của group để nhận updates
    _wsService.joinGroupRoom(widget.group.id, userId: currentUserId);
    _wsService.joinExpenseRoom(widget.group.id);

    // Khi có member mới tham gia
    _wsService.onMemberJoined = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Member joined - ${data['memberName']}');
      fetchGroupMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên mới'} đã tham gia nhóm', Colors.green);
    };

    // Khi member rời nhóm
    _wsService.onMemberLeft = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Member left - ${data['memberName']}');
      fetchGroupMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên'} đã rời nhóm', Colors.orange);
    };

    // Khi member được thêm vào
    _wsService.onMemberAdded = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Member added - ${data['memberName']}');
      fetchGroupMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên mới'} được thêm vào nhóm', Colors.green);
    };

    // Khi member bị xóa
    _wsService.onMemberRemoved = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Member removed - ${data['memberName']}');
      fetchGroupMembers();
      _showSnackBar('${data['memberName'] ?? 'Thành viên'} đã bị xóa khỏi nhóm', Colors.orange);
    };

    // Khi quyền sở hữu được chuyển
    _wsService.onOwnershipTransferred = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Ownership transferred');
      fetchGroupMembers();
      final newOwnerName = data['newOwnerName'] ?? 'thành viên khác';
      _showSnackBar('Quyền trưởng nhóm đã chuyển cho $newOwnerName', Colors.amber);
    };

    // Khi nhóm bị xóa
    _wsService.onGroupDeleted = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Group deleted');
      _showSnackBar('Nhóm đã bị xóa', Colors.red);
      Navigator.pop(context, true);
    };

    // Khi có chi tiêu mới
    _wsService.onExpenseCreated = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Expense created');
      reLoadPage();
      final expense = data['expense'];
      final title = expense?['title'] ?? 'Chi tiêu mới';
      _showSnackBar('Chi tiêu mới: $title', Colors.blue);
    };

    // Khi có thanh toán
    _wsService.onShareMarkedPaid = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Share marked paid');
      reLoadPage();
      final memberName = data['memberName'] ?? 'Thành viên';
      _showSnackBar('$memberName đã thanh toán', Colors.green);
    };

    // ========== INVITATION EVENTS ==========

    // Khi lời mời được chấp nhận (owner nhận được)
    _wsService.onInvitationAccepted = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Invitation accepted - ${data['invitedUserName']}');
      fetchGroupMembers();
      _fetchGroupPendingInvitations();
      final invitedName = data['invitedUserName'] ?? data['memberName'] ?? 'Thành viên';
      _showSnackBar('$invitedName đã chấp nhận lời mời', Colors.green);
    };

    // Khi lời mời bị từ chối (owner nhận được)
    _wsService.onInvitationRejected = (data) {
      if (_isLeavingPage) return;
      final eventGroupId = data['groupId']?.toString();
      if (eventGroupId != widget.group.id) return;

      print('🔌 WS TransactionGroup: Invitation rejected - ${data['invitedUserName']}');
      _fetchGroupPendingInvitations();
      final invitedName = data['invitedUserName'] ?? data['memberName'] ?? 'Thành viên';
      _showSnackBar('$invitedName đã từ chối lời mời', Colors.orange);
    };
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // 🔌 WebSocket: Leave rooms và clear callbacks
    _wsService.leaveGroupRoom(widget.group.id);
    _wsService.leaveExpenseRoom(widget.group.id);
    _wsService.clearGroupCallbacks(); // Không xóa onAddedToGroup
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

  // 🔥 Model cho payment event (đã trả hoặc đã nhận)
  // ignore: unused_element


  // 🔥 Hàm hiển thị my expenses theo ngày (bao gồm cả "đã trả" và "đã nhận")
  List<Widget> buildMyExpensesList(List<MyExpenseModel> expenses, BuildContext context) {
    if (expenses.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Chưa có chi tiêu nào trong tháng này',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      ];
    }

    // 🔥 Tạo danh sách payment events từ expenses
    // Mỗi expense có thể tạo ra nhiều events:
    // 1. "Đã trả" - khi user là người trả (paidByMemberId == currentMemberId)
    // 2. "Đã nhận" - khi user là người trả và có người khác đã thanh toán (share.isPaid && share.paidAt)
    // 3. "Nợ" - khi user không phải người trả
    List<Map<String, dynamic>> allEvents = [];

    for (var expense in expenses) {
      final bool isPayer = expense.paidByMemberId == currentMemberId;
      final String category = expense.mainCategory;

      if (isPayer) {
        // User là người trả → thêm event "Đã trả"
        allEvents.add({
          'type': 'paid', // Đã trả
          'date': expense.createdAt,
          'amount': expense.totalAmount,
          'title': expense.title.isNotEmpty ? expense.title : titleOf(category),
          'category': category,
          'expense': expense,
          'description': 'Bạn đã trả',
        });

        // Tìm những người đã thanh toán cho user → thêm event "Đã nhận"
        for (var share in expense.shares) {
          // Bỏ qua share của chính user
          if (share.memberId == currentMemberId) continue;
          // Chỉ lấy những share đã thanh toán
          if (share.isPaid && share.paidAt != null) {
            allEvents.add({
              'type': 'received', // Đã nhận
              'date': share.paidAt!,
              'amount': share.amount,
              'title': expense.title.isNotEmpty ? expense.title : titleOf(category),
              'category': category,
              'expense': expense,
              'fromName': share.memberName,
              'description': 'Nhận từ ${share.memberName}',
            });
          }
        }
      } else {
        // User không phải người trả → thêm event "Nợ" hoặc "Đã thanh toán"
        try {
          final myShare = expense.shares.firstWhere((s) => s.memberId == currentMemberId);
          allEvents.add({
            'type': myShare.isPaid ? 'paid_debt' : 'owed', // Đã trả nợ hoặc Nợ
            'date': myShare.isPaid && myShare.paidAt != null ? myShare.paidAt! : expense.createdAt,
            'amount': myShare.amount,
            'title': expense.title.isNotEmpty ? expense.title : titleOf(category),
            'category': category,
            'expense': expense,
            'toName': expense.paidByMemberName,
            'description': myShare.isPaid
                ? 'Đã trả cho ${expense.paidByMemberName}'
                : '${expense.paidByMemberName} đã trả cho bạn',
            'isPaid': myShare.isPaid,
          });
        } catch (e) {
          // User không có trong shares
        }
      }
    }

    // Sắp xếp theo ngày mới nhất
    allEvents.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // 1️⃣ Gom nhóm theo ngày (YYYY-MM-DD)
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var event in allEvents) {
      String dateKey = (event['date'] as DateTime).toIso8601String().split('T')[0];
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(event);
    }

    // Sắp xếp theo ngày mới nhất
    var sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // 2️⃣ Tạo danh sách Widget cho từng nhóm
    List<Widget> containers = sortedKeys.map((dateKey) {
      List<Map<String, dynamic>> dailyEvents = grouped[dateKey]!;

      // Chuyển dateKey -> DateTime để hiển thị
      DateTime date = DateTime.parse(dateKey);

      // ✅ Tính tổng tiền trong ngày
      double dailyIn = 0; // Tiền vào (nhận từ người khác trả nợ)
      double dailyOut = 0; // Tiền ra (bạn chi trả + bạn trả nợ)
      for (var event in dailyEvents) {
        final type = event['type'] as String;
        final amount = event['amount'] as double;
        if (type == 'received') {
          // Nhận tiền từ người khác trả nợ → tiền VÀO
          dailyIn += amount;
        } else if (type == 'paid' || type == 'paid_debt') {
          // Bạn chi trả cho nhóm hoặc trả nợ người khác → tiền RA
          dailyOut += amount;
        }
        // 'owed' không tính vì chưa chi thực tế, chỉ là khoản nợ
      }
      double netAmount = dailyIn - dailyOut;
      final bool isPositive = netAmount >= 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                  '${isPositive ? '+' : ''}${Common.formatNumber(netAmount.toString())}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),

            const SizedBox(height: 10),

            // 3️⃣ Danh sách events trong ngày đó
            ...dailyEvents.map((event) {
              final type = event['type'] as String;
              final amount = event['amount'] as double;
              final title = event['title'] as String;
              final category = event['category'] as String;
              final description = event['description'] as String;

              // Xác định màu và icon dựa trên type
              Color amountColor;
              IconData iconData;
              String prefix;

              switch (type) {
                case 'paid': // Bạn đã trả
                  amountColor = Colors.red;
                  iconData = Icons.arrow_upward;
                  prefix = '-';
                  break;
                case 'received': // Đã nhận từ người khác
                  amountColor = Colors.green;
                  iconData = Icons.arrow_downward;
                  prefix = '+';
                  break;
                case 'paid_debt': // Đã trả nợ cho người khác
                  amountColor = Colors.red;
                  iconData = Icons.arrow_upward;
                  prefix = '-';
                  break;
                case 'owed': // Nợ người khác
                default:
                  amountColor = Colors.orange;
                  iconData = Icons.schedule;
                  prefix = '-';
                  break;
              }

              // 🔥 Lấy expense để hiển thị chi tiết khi click
              final expense = event['expense'] as MyExpenseModel;

              return InkWell(
                onTap: () => _showExpenseDetailBottomSheet(expense),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
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
                      itemLeading(category),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tiêu đề expense
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Mô tả event
                            Row(
                              children: [
                                Icon(
                                  iconData,
                                  size: 14,
                                  color: amountColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // Hiển thị trạng thái nếu là khoản nợ
                            if (type == 'owed')
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '⏳ Chưa thanh toán',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Số tiền
                      Text(
                        '$prefix${Common.formatNumber(amount.toString())}',
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Icon mũi tên để biết có thể click
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
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

  // 🔥 Hiển thị chi tiết expense trong bottom sheet
  void _showExpenseDetailBottomSheet(MyExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bool isPayer = expense.paidByMemberId == currentMemberId;
        final category = expense.mainCategory;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  // Header với icon category
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(child: itemLeading(category)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề expense
                  Center(
                    child: Text(
                      expense.title.isNotEmpty ? expense.title : titleOf(category),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tổng số tiền
                  Center(
                    child: Text(
                      Common.formatNumber(expense.totalAmount.toString()),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ngày tạo và người trả
                  Center(
                    child: Text(
                      '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          isPayer ? 'Bạn đã trả' : 'Được trả bởi ${expense.paidByMemberName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),

                  // Danh sách transactions (chi tiết chi tiêu)
                  if (expense.transactions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Chi tiết chi tiêu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...expense.transactions.map((tx) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            itemLeading(tx.category),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.note.isNotEmpty ? tx.note : titleOf(tx.category),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    titleOf(tx.category),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Common.formatNumber(tx.amount.toString()),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Danh sách shares (phần chia)
                  const SizedBox(height: 16),
                  const Text(
                    'Phần chia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...expense.shares.map((share) {
                    final bool isCurrentUser = share.memberId == currentMemberId;
                    final bool isSharePayer = share.memberId == expense.paidByMemberId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppColors.green.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: isCurrentUser
                            ? Border.all(color: AppColors.green.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isCurrentUser
                                ? AppColors.green
                                : Colors.grey.shade400,
                            child: Text(
                              share.memberName.isNotEmpty
                                  ? share.memberName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tên thành viên
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isCurrentUser ? 'Bạn' : share.memberName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (isSharePayer) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Đã trả',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                // Trạng thái thanh toán
                                if (!isSharePayer) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        share.isPaid
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        size: 14,
                                        color: share.isPaid
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        share.isPaid
                                            ? 'Đã thanh toán'
                                            : 'Chưa thanh toán',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: share.isPaid
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Số tiền phần chia
                          Text(
                            Common.formatNumber(share.amount.toString()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: share.isPaid || isSharePayer
                                  ? Colors.black
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Nút đóng
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔥 Hàm hiển thị payment history theo ngày (giữ lại cho backward compatibility)
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
      // Lựa chọn 1: Mời thành viên
      const PopupMenuItem<String>(
        value: 'add_member',
        child: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.blackIcon),
            SizedBox(width: 12),
            Text('Mời thành viên'),
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
                        // mapExpensesToDebts() đã được gọi trong getListTransaction
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

                  // Section lời mời đang chờ (chỉ hiển thị cho owner)
                  if (_groupPendingInvitations.isNotEmpty && groupOwnerId == currentUserId) ...[
                    const SizedBox(height: 16),
                    _buildGroupPendingInvitationsSection(),
                  ],

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
                      ? Column(children: [...buildMyExpensesList(myExpensesList, context)])
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

    // 🔥 Gọi API my-expenses mới
    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupExpenseMyExpenses(widget.group.id),
      params: {
        "monthYear": nameOfMonth, // Format: "MM/YYYY"
      },
      onSuccess: (response) {
        if (!mounted) return;

        print("✅ My expenses response: ${response.data}");

        // Parse response - có thể là array trực tiếp hoặc object có expenses[]
        List<MyExpenseModel> expenses = [];
        MyExpensesSummary? summary;

        if (response.data is List) {
          // Response là array trực tiếp
          expenses = (response.data as List)
              .map((e) => MyExpenseModel.fromJson(e))
              .toList();
        } else if (response.data is Map) {
          // Response là object có expenses[] và summary
          final data = response.data as Map<String, dynamic>;
          if (data['expenses'] != null) {
            expenses = (data['expenses'] as List)
                .map((e) => MyExpenseModel.fromJson(e))
                .toList();
          }
          if (data['summary'] != null) {
            summary = MyExpensesSummary.fromJson(data['summary']);
          }
        }

        // Sắp xếp theo ngày mới nhất
        expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          myExpensesList = expenses;
          myExpensesSummary = summary;
          _loading = false;

          // Cập nhật tổng chi tiêu
          _totalExpense = expenses.fold(0, (sum, e) => sum + e.totalAmount);
          _myExpense = summary?.totalOwed ?? 0;
        });

        // 🔥 Map expenses sang debts cho tab "Còn lại"
        mapExpensesToDebts();
      },
      onError: (error) {
        print("❌ Lỗi khi gọi my-expenses API: $error");
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
            netBalance >= 0 ? 'Bạn sẽ được nhận lại' : 'Bạn cần trả',
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

  // Section hiển thị lời mời đang chờ của group (cho owner)
  Widget _buildGroupPendingInvitationsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.send, color: Colors.blue.shade600, size: 18),
              const SizedBox(width: 8),
              Text(
                'Lời mời đã gửi (${_groupPendingInvitations.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._groupPendingInvitations.map((invitation) => _buildGroupInvitationItem(invitation)),
        ],
      ),
    );
  }

  // Item lời mời đã gửi
  Widget _buildGroupInvitationItem(Map<String, dynamic> invitation) {
    final invitationId = invitation['id']?.toString() ?? invitation['invitationId']?.toString() ?? '';
    final inviteeName = invitation['inviteeName']?.toString() ??
        invitation['invitee']?['username']?.toString() ??
        invitation['suggestedMemberName']?.toString() ??
        'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, color: Colors.blue.shade600, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              inviteeName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _cancelInvitation(invitationId),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Hủy', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
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
      onTap: isOwedToMe
          ? () => _showConfirmPaymentSheet(debt, memberName)
          : () => _showUploadProofSheet(debt, memberName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          children: [
            // Avatar với badge ảnh chứng minh
            Stack(
              children: [
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
                // Badge ảnh chứng minh
                if (debt.hasProof)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: debt.isProofPending ? Colors.amber : Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        debt.isProofPending ? Icons.hourglass_empty : Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
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
                  // Hiển thị trạng thái ảnh chứng minh
                  if (debt.hasProof)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image,
                            size: 12,
                            color: debt.isProofPending ? Colors.amber.shade700 : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            debt.isProofPending ? 'Có ảnh - Chờ xác nhận' : 'Đã xác nhận',
                            style: TextStyle(
                              fontSize: 11,
                              color: debt.isProofPending ? Colors.amber.shade700 : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                      color: debt.hasProof ? Colors.amber.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      debt.hasProof ? 'Xem ảnh & xác nhận' : 'Nhấn để xác nhận',
                      style: TextStyle(
                        fontSize: 10,
                        color: debt.hasProof ? Colors.amber.shade700 : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (!isOwedToMe)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: debt.hasProof ? Colors.amber.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          debt.hasProof ? Icons.hourglass_empty : Icons.camera_alt,
                          size: 12,
                          color: debt.hasProof ? Colors.amber.shade700 : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          debt.hasProof
                              ? (debt.isProofPending ? 'Đang chờ' : 'Đã xác nhận')
                              : 'Gửi ảnh',
                          style: TextStyle(
                            fontSize: 10,
                            color: debt.hasProof ? Colors.amber.shade700 : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet mời thành viên
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

          void inviteUserToGroup(Map<String, dynamic> user) {
            final inviteeUserId = user["id"] ?? user["userId"] ?? "";
            final suggestedName = user["username"] ?? user["name"] ?? "Unknown";

            print("🔍 inviteUserToGroup - user data: $user");
            print("🔍 inviteUserToGroup - inviteeUserId: $inviteeUserId, suggestedName: $suggestedName");

            showLoading(context);
            ApiUtil.getInstance()!.post(
              url: ApiEndpoint.groupInvite(widget.group.id),
              body: {
                "invitedUserId": inviteeUserId,
                "suggestedMemberName": suggestedName,
                "invitedByMemberName": widget.group.memberName ?? "Thành viên",
              },
              onSuccess: (response) {
                hideLoading();
                Navigator.pop(context);
                _fetchGroupPendingInvitations();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.send, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Đã gửi lời mời đến $suggestedName'),
                      ],
                    ),
                    backgroundColor: Colors.blue.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
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
                    'Mời thành viên',
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
                                            onPressed: () => inviteUserToGroup(user),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                            ),
                                            child: const Text('Mời', style: TextStyle(color: Colors.white)),
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

            // Hiển thị ảnh chứng minh nếu có
            if (debt.hasProof) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Ảnh chứng minh thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Preview ảnh
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiEndpoint.getFullImageUrl(debt.proofImageUrl),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            alignment: Alignment.center,
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey.shade400),
                                const SizedBox(height: 4),
                                Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nút xem full
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProofImageDialog(ApiEndpoint.getFullImageUrl(debt.proofImageUrl));
                      },
                      icon: const Icon(Icons.fullscreen, size: 18),
                      label: const Text('Xem toàn màn hình'),
                    ),
                  ],
                ),
              ),
            ],

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

  // 📷 Dialog chọn nguồn ảnh (camera hoặc thư viện)
  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn ảnh chứng minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera
                InkWell(
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Chụp ảnh'),
                    ],
                  ),
                ),
                // Gallery
                InkWell(
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.photo_library,
                          size: 32,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Thư viện'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📷 Chọn và upload ảnh chứng minh thanh toán
  Future<void> _pickAndUploadProof(DebtModel debt) async {
    // 1. Hiện dialog chọn nguồn ảnh
    final source = await _showImageSourceDialog();
    if (source == null) return;

    // 2. Chọn ảnh
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image == null) return;

    // 3. Upload ảnh
    showLoading(context);
    ApiUtil.getInstance()!.postMultipart(
      url: ApiEndpoint.groupExpenseUploadProof(widget.group.id),
      fields: {'shareId': debt.shareId},
      imageFile: File(image.path),
      onSuccess: (response) {
        hideLoading();
        toastInfo(msg: 'Đã upload ảnh chứng minh thanh toán', bgColor: Colors.green);
        reLoadPage();
      },
      onError: (err) {
        hideLoading();
        toastInfo(msg: 'Lỗi upload: $err', bgColor: Colors.red);
      },
    );
  }

  // 📷 Bottom sheet cho người nợ - upload ảnh chứng minh
  void _showUploadProofSheet(DebtModel debt, String creditorName) {
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
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Khoản nợ của bạn',
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
                  const TextSpan(text: 'Bạn nợ '),
                  TextSpan(
                    text: creditorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const TextSpan(text: ' số tiền '),
                  TextSpan(
                    text: '${Common.formatNumber(debt.shareAmount.toString())}đ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
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
            const SizedBox(height: 24),

            // Trạng thái ảnh chứng minh
            if (debt.hasProof) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: debt.isProofPending ? Colors.amber.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: debt.isProofPending ? Colors.amber.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      debt.isProofPending ? Icons.hourglass_empty : Icons.check_circle,
                      color: debt.isProofPending ? Colors.amber.shade700 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.isProofPending ? 'Đang chờ xác nhận' : 'Đã được xác nhận',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: debt.isProofPending ? Colors.amber.shade700 : Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            debt.isProofPending
                                ? 'Ảnh chứng minh đã được gửi, đang chờ $creditorName xác nhận'
                                : 'Thanh toán đã được xác nhận',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Nút xem ảnh đã upload
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showProofImageDialog(ApiEndpoint.getFullImageUrl(debt.proofImageUrl));
                },
                icon: const Icon(Icons.image),
                label: const Text('Xem ảnh đã gửi'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              // Hướng dẫn upload
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload ảnh chuyển khoản để $creditorName có thể xác nhận thanh toán',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

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
                      'Đóng',
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
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickAndUploadProof(debt);
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      debt.hasProof ? 'Gửi ảnh mới' : 'Upload ảnh chứng minh',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  // 📷 Xem ảnh chứng minh full screen
  void _showProofImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Ảnh chứng minh thanh toán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Image
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Không thể tải ảnh',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
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