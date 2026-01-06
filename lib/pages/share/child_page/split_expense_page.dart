import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/member_model.dart';

/// Màn hình 2: Chọn cách chia tiền với 3 tab
class SplitExpensePage extends StatefulWidget {
  final Group group;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String paidByMemberId;
  final Member paidByMember;
  final List<Member> members;
  final String currentUserId;

  const SplitExpensePage({
    super.key,
    required this.group,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.paidByMemberId,
    required this.paidByMember,
    required this.members,
    required this.currentUserId,
  });

  @override
  State<SplitExpensePage> createState() => _SplitExpensePageState();
}

class _SplitExpensePageState extends State<SplitExpensePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Chia đều - chọn ai tham gia
  List<String> equalParticipantIds = [];

  // Tab 2: Chia chính xác - nhập số tiền cho từng người
  Map<String, double> exactAmounts = {};
  Map<String, TextEditingController> exactControllers = {};

  // Tab 3: Chia theo phần trăm
  Map<String, double> percentages = {};
  Map<String, TextEditingController> percentControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Mặc định chọn tất cả thành viên cho chia đều
    equalParticipantIds = widget.members.map((m) => m.id).toList();

    // Khởi tạo controllers cho tab chính xác
    for (var member in widget.members) {
      exactControllers[member.id] = TextEditingController();
      exactAmounts[member.id] = 0;
    }

    // Khởi tạo controllers cho tab phần trăm
    for (var member in widget.members) {
      percentControllers[member.id] = TextEditingController();
      percentages[member.id] = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in exactControllers.values) {
      controller.dispose();
    }
    for (var controller in percentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getDisplayName(Member member) {
    return member.userId == widget.currentUserId
        ? '${member.name} (bạn)'
        : member.name;
  }

  // ==================== TAB 1: CHIA ĐỀU ====================
  Widget _buildEqualSplitTab() {
    final perPerson = equalParticipantIds.isNotEmpty
        ? widget.amount / equalParticipantIds.length
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin tổng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${widget.amount.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Mỗi người', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${perPerson.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Chọn người tham gia:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Nút chọn tất cả / bỏ chọn tất cả
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    equalParticipantIds = widget.members.map((m) => m.id).toList();
                  });
                },
                icon: const Icon(Icons.select_all, size: 18),
                label: const Text('Chọn tất cả'),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    equalParticipantIds = [];
                  });
                },
                icon: const Icon(Icons.deselect, size: 18),
                label: const Text('Bỏ chọn'),
              ),
            ],
          ),

          // Danh sách thành viên
          ...widget.members.map((member) {
            final isSelected = equalParticipantIds.contains(member.id);
            final isPayer = member.id == widget.paidByMemberId;

            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Text(_getDisplayName(member)),
                  if (isPayer)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Người trả',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                ],
              ),
              subtitle: isSelected
                  ? Text(
                      '${perPerson.toStringAsFixed(0)}đ',
                      style: const TextStyle(color: Colors.blue),
                    )
                  : null,
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    equalParticipantIds.add(member.id);
                  } else {
                    equalParticipantIds.remove(member.id);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
    );
  }

  // ==================== TAB 2: CHIA CHÍNH XÁC ====================
  Widget _buildExactSplitTab() {
    final totalEntered = exactAmounts.values.fold(0.0, (sum, v) => sum + v);
    final remaining = widget.amount - totalEntered;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin tổng và còn lại
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: remaining == 0 ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${widget.amount.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Còn lại', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${remaining.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: remaining == 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (remaining != 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                remaining > 0
                    ? '⚠️ Còn ${remaining.toStringAsFixed(0)}đ chưa phân bổ'
                    : '⚠️ Vượt quá ${(-remaining).toStringAsFixed(0)}đ',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          const SizedBox(height: 20),

          const Text(
            'Nhập số tiền cho từng người:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Danh sách thành viên với input
          ...widget.members.map((member) {
            final isPayer = member.id == widget.paidByMemberId;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(member),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (isPayer)
                          Text(
                            'Người trả',
                            style: TextStyle(fontSize: 12, color: Colors.green[600]),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: exactControllers[member.id],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'đ',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          exactAmounts[member.id] = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== TAB 3: CHIA THEO PHẦN TRĂM ====================
  Widget _buildPercentSplitTab() {
    final totalPercent = percentages.values.fold(0.0, (sum, v) => sum + v);
    final remaining = 100 - totalPercent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin tổng và còn lại
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: remaining == 0 ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${widget.amount.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tổng %', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${totalPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: totalPercent == 100 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (remaining != 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                remaining > 0
                    ? '⚠️ Còn ${remaining.toStringAsFixed(0)}% chưa phân bổ'
                    : '⚠️ Vượt quá ${(-remaining).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ),
          const SizedBox(height: 20),

          const Text(
            'Nhập phần trăm cho từng người:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Danh sách thành viên với input
          ...widget.members.map((member) {
            final isPayer = member.id == widget.paidByMemberId;
            final percent = percentages[member.id] ?? 0;
            final amountForMember = widget.amount * percent / 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(member),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (isPayer)
                          Text(
                            'Người trả',
                            style: TextStyle(fontSize: 12, color: Colors.green[600]),
                          ),
                        Text(
                          '= ${amountForMember.toStringAsFixed(0)}đ',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: percentControllers[member.id],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: '%',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          percentages[member.id] = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== GỬI API ====================
  Future<void> _submitExpense() async {
    String splitType;
    List<Map<String, dynamic>> participants = [];

    switch (_tabController.index) {
      case 0: // Chia đều
        if (equalParticipantIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ít nhất 1 người tham gia')),
          );
          return;
        }
        splitType = 'equal';
        final perPerson = widget.amount / equalParticipantIds.length;
        for (var memberId in equalParticipantIds) {
          final member = widget.members.firstWhere((m) => m.id == memberId);
          participants.add({
            'memberId': memberId.toString(),
            'userId': member.userId,
            'amount': perPerson,
          });
        }
        break;

      case 1: // Chia chính xác
        final totalEntered = exactAmounts.values.fold(0.0, (sum, v) => sum + v);
        if ((totalEntered - widget.amount).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tổng số tiền chưa khớp')),
          );
          return;
        }
        splitType = 'exact';
        for (var entry in exactAmounts.entries) {
          if (entry.value > 0) {
            final member = widget.members.firstWhere((m) => m.id == entry.key);
            participants.add({
              'memberId': entry.key.toString(),
              'userId': member.userId,
              'amount': entry.value,
            });
          }
        }
        break;

      case 2: // Chia theo phần trăm
        final totalPercent = percentages.values.fold(0.0, (sum, v) => sum + v);
        if ((totalPercent - 100).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tổng phần trăm phải bằng 100%')),
          );
          return;
        }
        splitType = 'percent';
        for (var entry in percentages.entries) {
          if (entry.value > 0) {
            final member = widget.members.firstWhere((m) => m.id == entry.key);
            participants.add({
              'memberId': entry.key.toString(),
              'userId': member.userId,
              'amount': widget.amount * entry.value / 100,
              'percent': entry.value,
            });
          }
        }
        break;

      default:
        return;
    }

    // Đảm bảo người trả nằm trong participants
    final paidByMemberIdStr = widget.paidByMemberId.toString();
    if (!participants.any((p) => p['memberId'] == paidByMemberIdStr)) {
      participants.add({
        'memberId': paidByMemberIdStr,
        'userId': widget.paidByMember.userId,
        'amount': 0,
      });
    }

    showLoading(context);

    final Map<String, dynamic> body = {
      'title': widget.note,
      'note': widget.note,
      'amount': widget.amount,
      'category': widget.category,
      'splitType': splitType,
      'paidByMemberId': paidByMemberIdStr,
      'paidByUserId': widget.paidByMember.userId,
    };

    // Gửi đúng tên trường theo splitType
    switch (splitType) {
      case 'equal':
        body['participants'] = participants;
        break;
      case 'exact':
        body['exactSplits'] = participants;
        break;
      case 'percent':
        body['percentSplits'] = participants;
        break;
    }

    print('📤 Sending expense with splitType: $splitType');
    print('📤 Body: $body');
    print('📤 Participants: $participants');

    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.groupExpenses(widget.group.id),
      body: body,
      onSuccess: (response) {
        hideLoading();
        // Pop 2 màn hình (về trang group)
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
      },
      onError: (error) {
        hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chọn cách chia tiền'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Chia đều'),
            Tab(text: 'Chính xác'),
            Tab(text: 'Phần trăm'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Thông tin người trả
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Icon(BootstrapIcons.person_check, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${_getDisplayName(widget.paidByMember)} đã trả ${widget.amount.toStringAsFixed(0)}đ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEqualSplitTab(),
                _buildExactSplitTab(),
                _buildPercentSplitTab(),
              ],
            ),
          ),

          // Nút Lưu
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Lưu chi tiêu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
