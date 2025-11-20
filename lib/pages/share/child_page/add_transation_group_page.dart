import 'dart:async';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/icon.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/res/app_colors.dart';

class AddTransactionGroupPage extends StatefulWidget {
  @override
  _AddTransactionGroupPageState createState() => _AddTransactionGroupPageState();
}

class _AddTransactionGroupPageState extends State<AddTransactionGroupPage> {
  final TextEditingController textController = TextEditingController();

  double amount = 0;
  String category = "food"; // default
  String note = "";
  DateTime date = DateTime.now();

  List<String> members = ["Hiển", "Trọng", "Đạt"];
  String selectedMember = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedMember = members[0];
  }

  @override
  void dispose() {
    textController.dispose();
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

  void onChanged(String input) {
    setState(() {
      amount = double.tryParse(input) ?? 0;
    });
  }

  Future<void> callApi(BuildContext thiscontext) async {
    await addExpense(amount: amount, category: category, dateTime: date,context: thiscontext, note: note);

    print(selectedMember);
    Navigator.pop(thiscontext); // quay lại màn hình trước
  }

  String formatDate(DateTime d) {
    if (DateTime.now().day == d.day) return "Today";
    if (DateTime.now().subtract(const Duration(days: 1)).day == d.day) {
      return "Yesterday";
    }
    if (DateTime.now().add(const Duration(days: 1)).day == d.day) {
      return "Tomorrow";
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
        title: const Text('Add Transaction'),
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
                          controller: textController,
                          onChanged: onChanged,
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
                          // value: selectedMember,
                          items: members.map((member) {
                            return DropdownMenuItem<String>(
                              value: member,
                              child: Text(
                                member,
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
                          decoration: const InputDecoration(
                              hintText: 'Write note'),
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
  // Nếu gọi API
  ApiUtil.getInstance()!.post(
    url: "https://67297e9b6d5fa4901b6d568f.mockapi.io/api/test/transaction",
    body:  expense.toJson(),
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