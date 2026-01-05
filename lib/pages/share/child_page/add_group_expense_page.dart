import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/icon.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';
import 'split_expense_page.dart';

/// Màn hình 1: Nhập thông tin cơ bản (số tiền, người trả, mô tả)
class AddGroupExpensePage extends StatefulWidget {
  final Group group;
  const AddGroupExpensePage({super.key, required this.group});

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  double amount = 0;
  String category = "food";
  String note = "";
  DateTime date = DateTime.now();

  List<Member> members = [];
  String selectedMemberId = '';
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    members = widget.group.members;
    if (members.isNotEmpty) {
      selectedMemberId = members[0].id;
    }
    _initCurrentMember();
  }

  Future<void> _initCurrentMember() async {
    try {
      final userId = await SharedPreferenceUtil.getUserId();
      if (mounted) {
        setState(() {
          currentUserId = userId;
        });
      }

      if (userId != null && userId.isNotEmpty) {
        final myMember = members.firstWhere(
          (m) => m.userId == userId,
          orElse: () => members.isNotEmpty ? members[0] : Member(id: '', name: ''),
        );
        if (mounted && myMember.id.isNotEmpty) {
          setState(() {
            selectedMemberId = myMember.id;
          });
        }
      }
    } catch (e) {
      print("❌ Error init current member: $e");
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void datePicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != date) {
      setState(() {
        date = picked;
      });
    }
  }

  String formatDate(DateTime d) {
    if (DateTime.now().day == d.day &&
        DateTime.now().month == d.month &&
        DateTime.now().year == d.year) {
      return "Hôm nay";
    }
    return "${d.day}/${d.month}/${d.year}";
  }

  void goToSplitPage() {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }
    if (selectedMemberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người chi tiền')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitExpensePage(
          group: widget.group,
          amount: amount,
          category: category,
          note: note.isEmpty ? category : note,
          date: date,
          paidByMemberId: selectedMemberId,
          paidByMember: members.firstWhere((m) => m.id == selectedMemberId),
          members: members,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thêm chi tiêu nhóm'),
        actions: [
          TextButton(
            onPressed: amount > 0 ? goToSplitPage : null,
            child: Text(
              'Tiếp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: amount > 0 ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nhập số tiền
                  Row(
                    children: [
                      const Icon(BootstrapIcons.cash_stack,
                          color: AppColors.blackIcon, size: 28),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          onChanged: (input) {
                            setState(() {
                              amount = double.tryParse(input) ?? 0;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: '0',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.green),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Chọn loại chi tiêu
                  Row(
                    children: [
                      const Icon(BootstrapIcons.question_lg,
                          size: 28, color: AppColors.blackIcon),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          value: category,
                          onChanged: (value) {
                            setState(() => category = value!);
                          },
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          items: ListIconGroup.map((ItemIcon item) {
                            return DropdownMenuItem<String>(
                              value: item.title,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: item.img,
                                  ),
                                  const SizedBox(width: 20),
                                  Text(titleOf(item.title) ?? ''),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Người chi tiền
                  Row(
                    children: [
                      const Icon(BootstrapIcons.person,
                          size: 28, color: AppColors.blackIcon),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMemberId.isEmpty ? null : selectedMemberId,
                          decoration: const InputDecoration(
                            hintText: 'Ai đã chi tiền?',
                            border: InputBorder.none,
                          ),
                          items: members.map((member) {
                            final displayName = member.userId == currentUserId
                                ? '${member.name} (bạn)'
                                : member.name;
                            return DropdownMenuItem<String>(
                              value: member.id,
                              child: Text(displayName),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedMemberId = value ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Ghi chú
                  Row(
                    children: [
                      const Icon(BootstrapIcons.text_left,
                          size: 28, color: AppColors.blackIcon),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(hintText: 'Ghi chú'),
                          style: const TextStyle(fontSize: 18),
                          onChanged: (value) {
                            setState(() {
                              note = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Ngày
                  InkWell(
                    onTap: datePicker,
                    child: Row(
                      children: [
                        const Icon(BootstrapIcons.calendar2_check,
                            size: 28, color: AppColors.blackIcon),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatDate(date),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Nút Next
            Container(
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: amount > 0 ? goToSplitPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amount > 0 ? Colors.green : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tiếp tục chọn cách chia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
