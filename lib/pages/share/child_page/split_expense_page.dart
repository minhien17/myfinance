import 'dart:async';

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

  // ==================== DIALOG THÀNH CÔNG ====================
  void _showSuccessDialog() {
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
                // Icon thành công với animation
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
                  'Chia tiền thành công!',
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
                      _buildInfoRow(
                        Icons.attach_money,
                        'Số tiền',
                        '${widget.amount.toStringAsFixed(0)}đ',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.person,
                        'Người trả',
                        _getDisplayName(widget.paidByMember),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.category,
                        'Danh mục',
                        widget.category,
                      ),
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
                      // Pop 2 màn hình (về trang group)
                      Navigator.of(context).pop(true);
                      Navigator.of(context).pop(true);
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ==================== KIỂM TRA MEMBERS TRƯỚC KHI GỬI ====================
  Future<Map<String, dynamic>> _validateMembersBeforeSubmit(List<Map<String, dynamic>> participants) async {
    final completer = Completer<Map<String, dynamic>>();

    ApiUtil.getInstance()!.get(
      url: ApiEndpoint.groupMy,
      onSuccess: (response) {
        try {
          final List<dynamic> groups = response.data ?? [];
          final currentGroup = groups.firstWhere(
            (g) => (g['id'] ?? g['groupId'])?.toString() == widget.group.id,
            orElse: () => null,
          );

          if (currentGroup == null) {
            completer.complete({'isValid': false, 'leftMembers': <String>['Nhóm không tồn tại']});
            return;
          }

          // Lấy danh sách members đã joined từ API
          List<String> currentMemberIds = [];
          if (currentGroup['members'] != null) {
            for (var m in currentGroup['members']) {
              final member = Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {});
              if (member.joined) {
                currentMemberIds.add(member.id);
              }
            }
          }

          // Kiểm tra xem có participant nào đã rời nhóm không
          List<String> leftMembers = [];
          for (var p in participants) {
            final memberId = p['memberId']?.toString() ?? '';
            if (!currentMemberIds.contains(memberId)) {
              // Tìm tên member đã rời
              final member = widget.members.firstWhere(
                (m) => m.id == memberId,
                orElse: () => Member(id: '', name: 'Không xác định'),
              );
              leftMembers.add(member.name);
            }
          }

          if (leftMembers.isNotEmpty) {
            completer.complete({'isValid': false, 'leftMembers': leftMembers});
          } else {
            completer.complete({'isValid': true, 'leftMembers': <String>[]});
          }
        } catch (e) {
          print('Error validating members: $e');
          // Nếu lỗi, cho phép tiếp tục (server sẽ validate)
          completer.complete({'isValid': true, 'leftMembers': <String>[]});
        }
      },
      onError: (error) {
        print('Error fetching members: $error');
        // Nếu lỗi API, cho phép tiếp tục (server sẽ validate)
        completer.complete({'isValid': true, 'leftMembers': <String>[]});
      },
    );

    return completer.future;
  }

  void _showMembersChangedDialog(List<String> leftMembers) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 28),
              const SizedBox(width: 12),
              const Expanded(child: Text('Thành viên đã thay đổi')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Các thành viên sau đã rời khỏi nhóm:'),
              const SizedBox(height: 12),
              ...leftMembers.map((name) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_off, size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(name, style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng quay lại và chọn lại người tham gia chia tiền.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Pop 2 màn hình về TransactionGroupPage để refresh lại members
                Navigator.of(context).pop('members_changed');
                Navigator.of(context).pop('members_changed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Quay lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
            'memberName': member.name,
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
              'memberName': member.name,
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
              'memberName': member.name,
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
        'memberName': widget.paidByMember.name,
        'amount': 0,
      });
    }

    showLoading(context);

    // Kiểm tra danh sách members mới nhất từ API trước khi submit
    final validationResult = await _validateMembersBeforeSubmit(participants);
    if (!validationResult['isValid']) {
      hideLoading();
      _showMembersChangedDialog(validationResult['leftMembers'] as List<String>);
      return;
    }

    final Map<String, dynamic> body = {
      'title': widget.note,
      'note': widget.note,
      'amount': widget.amount,
      'category': widget.category,
      'splitType': splitType,
      'paidByMemberId': paidByMemberIdStr,
      'paidByUserId': widget.paidByMember.userId,
      'paidByMemberName': widget.paidByMember.name,
      'date': widget.date.toIso8601String(),
    };
    // paidByMemberName thì có thể có 2 người hoặc hơn

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
        // Hiển thị dialog thành công
        _showSuccessDialog();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
