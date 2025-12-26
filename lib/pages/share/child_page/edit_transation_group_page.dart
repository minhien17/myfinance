import 'dart:async';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/icon.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';

class EditTransactionGroupPage extends StatefulWidget {
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String owner;
  final List<Member> members; // 🔥 Thêm members từ API

  const EditTransactionGroupPage({
    Key? key,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.owner,
    required this.members, // 🔥 Required members
  }) : super(key: key);
  @override
  _EditTransactionGroupPageState createState() => _EditTransactionGroupPageState();
}

class _EditTransactionGroupPageState extends State<EditTransactionGroupPage> {
  TextEditingController amountTextController = TextEditingController();
  TextEditingController noteTextController = TextEditingController();

  double amount = 0;
  String category = "food"; // default
  String note = "";
  String selectedMember = '';
  String currentUserId = ''; // 🔥 userId của người đang đăng nhập

  // ⚠️ BACKUP: Hard-coded members (giữ lại cho trường hợp cần)
  // List<String> members = ["Hiển", "Trọng", "Đạt"];

  List<Member> members = []; // 🔥 Danh sách members từ API
  DateTime date = DateTime.now();

  @override
  void dispose() {
    amountTextController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await SharedPreferenceUtil.getUserId();
    if (mounted) {
      setState(() {
        currentUserId = userId;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // 🔥 Load members từ API
    members = widget.members;

    // 🔥 Load userId hiện tại
    _loadCurrentUserId();

    amount = widget.amount;
    // Kiểm tra category hợp lệ cho Dropdown
    bool isValidCategory = ListIcon.any((element) => element.title == widget.category);
    category = isValidCategory ? widget.category : "other";

    note = widget.note;
    date = widget.date;
    selectedMember = widget.owner;

    amountTextController = TextEditingController(text: amount.toString());
    noteTextController = TextEditingController(text: note.toString());

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

  void onChanged(String input) {
    setState(() {
      amount = double.tryParse(input) ?? 0;
    });
  }

  Future<void> callApi(BuildContext thiscontext) async {
    // print("$amount + $category + $note");
    await addExpense(amount: amount, category: category, dateTime: date,context: thiscontext, note: note);
    
    Navigator.pop(thiscontext); // quay lại màn hình trước
  }

  String formatDate(DateTime d) {
    if (DateTime.now().day == d.day) return "Hôm nay";
    if (DateTime.now().subtract(const Duration(days: 1)).day == d.day) {
      return "Hôm qua";
    }
    if (DateTime.now().add(const Duration(days: 1)).day == d.day) {
      return "Ngày mai";
    }
    return "${d.day}/${d.month}/${d.year}";
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
        title: const Text('Sửa chi tiêu'),
      ),
      body: Container(
        
        padding: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.line)
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Nhập số tiền
                  Row(
                    children: [
                      const Icon(BootstrapIcons.cash_stack, color: AppColors.blackIcon, size: 28),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: amountTextController,
                          onChanged: onChanged,
                          decoration: const InputDecoration(
                            hintText: '0',
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  /// Chọn loại
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
                                    color: Colors.black87, // Set text color
                                    fontSize: 16, // Set font size
                                    fontWeight:
                                        FontWeight.bold, // Set font weight
                                  ),
                                  items: ListIcon.map((ItemIcon item) {
                                    return DropdownMenuItem<String>(
                                        value: item.title,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: item.img,
                                            ),
                                            const SizedBox(
                                              width: 20,
                                              height: 25,
                                            ),
                                            Text(titleOf(item.title) ??
                                                ''),
                                          ],
                                        ));
                                  }).toList(),
                                  
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(BootstrapIcons.person, color: AppColors.blackIcon, size: 28),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMember,
                          items: members.map((member) { // 🔥 Sử dụng members từ API
                            // 🔥 Hiển thị "(bạn)" nếu đây là user hiện tại
                            final displayName = member.userId == currentUserId
                                ? '${member.name} (bạn)'
                                : member.name;
                            return DropdownMenuItem<String>(
                              value: member.name,
                              child: Text(
                                displayName,
                                style: const TextStyle(fontSize: 18, color: AppColors.blackIcon),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMember = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Chọn thành viên',

                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            fontSize: 18,
                            // color: Colors.orange,
                          ),
                        ),),
                    ],
                  ),
                  const SizedBox(height: 15),


                  /// Note
                  Row(
                    children: [
                      const Icon(BootstrapIcons.text_left,
                          size: 28, color: AppColors.blackIcon),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: noteTextController,
                          decoration: const InputDecoration(
                              hintText: 'Ghi chú'),
                          style: const TextStyle(fontSize: 18),
                          onChanged: (value) {
                            setState(() {
                              note = value;
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),

                  /// Date
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
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /// Nút Add
            Container(
              // padding: EdgeInsets.all(10),
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                height: 40,
                child: ElevatedButton(
                  onPressed: amount == 0 ? null : () => callApi(context),
                  
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amount == 0 ? null : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      
                    ),
                    
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: amount == 0 ? null : Colors.white,
                      fontSize: 18
                    ),
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

Future<void> addExpense({
  required double amount,
  required String category,
  required String note,
  required DateTime dateTime,
  required BuildContext context,
}) async {
  final expense = TransactionModel.full(
    id: DateTime.now().millisecondsSinceEpoch.toString(), // fake id
    amount: amount,
    category: category,
    note: note,
    dateTime: dateTime,
  );

  showLoading(context);

   // 3. Sử dụng Completer để đợi API hoàn thành
  final completer = Completer<void>();
  ApiUtil.getInstance()!.post(
    url: "http://localhost:3001/",
    body: {
      "amount": amount,
      "category": category,
      "note": note,
      "dateTime": dateTime.toIso8601String(),
    },
    onSuccess: (response) {
      
      print("✅ Add expense success: ${response.data}");
      completer.complete(); 
      // hideLoading();
    },
    onError: (error) {
      print("❌ Add expense error: $error");
      completer.completeError(error); 
      // hideLoading();
    },
  );

  try {
    // 5. ĐỢI API HOÀN THÀNH (Đây là bước QUAN TRỌNG NHẤT)
    await completer.future;

  } catch (e) {
    // Bắt lỗi nếu completer.completeError được gọi
    // Thêm logic thông báo lỗi ở đây (ví dụ: toastInfo)

  } finally {
    // 6. ẨN LOADING (Đảm bảo được gọi trong mọi trường hợp)
    if (context.mounted) {
      hideLoading();
    }
    
    // Tùy chọn: Đóng màn hình hiện tại sau khi hoàn thành
    // if (context.mounted) {
    //   Navigator.of(context).pop(); 
    // }
  }

}