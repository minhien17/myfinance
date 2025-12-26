import 'dart:async';

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/group_expense_model.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/icon.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/models/transaction_model.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';

import 'package:my_finance/models/group_model.dart';
// ...

class AddTransactionGroupPage extends StatefulWidget {
  final Group group;
  const AddTransactionGroupPage({super.key, required this.group});

  @override
  _AddTransactionGroupPageState createState() => _AddTransactionGroupPageState();
}

class _AddTransactionGroupPageState extends State<AddTransactionGroupPage> {
  final TextEditingController textController = TextEditingController();

  double amount = 0;
  String category = "food"; // default
  String note = "";
  DateTime date = DateTime.now();

  List<Member> members = [];
  String selectedMemberId = ''; // member ID
  String currentUserId = ''; // 🔥 userId của người đang đăng nhập

  bool isSplitBill = false;
  List<String> participantIds = []; // List participant IDs (member IDs)

  @override
  void initState() {
    super.initState();
    // Lấy danh sách thành viên từ Group object passed vào
    members = widget.group.members;

    // Set giá trị mặc định trước (để tránh rỗng khi user bấm nút Save ngay)
    if (members.isNotEmpty) {
      selectedMemberId = members[0].id;
    }

    // Sau đó mới tìm member của user hiện tại (async)
    _initCurrentMember();
  }

  Future<void> _initCurrentMember() async {
    try {
      // Lấy userId từ SharedPreference
      final userId = await SharedPreferenceUtil.getUserId();
      print("🔍 DEBUG - Current userId: $userId");
      print("🔍 DEBUG - Members: ${members.map((m) => 'id=${m.id}, name=${m.name}, userId=${m.userId}').toList()}");

      // 🔥 Lưu userId vào state để dùng cho việc hiển thị "(bạn)"
      if (mounted) {
        setState(() {
          currentUserId = userId;
        });
      }

      if (userId != null && userId.isNotEmpty) {
        // Tìm member có userId trùng với user hiện tại
        final myMember = members.firstWhere(
          (m) {
            print("🔍 Comparing: m.userId=${m.userId} == userId=$userId => ${m.userId == userId}");
            return m.userId == userId;
          },
          orElse: () {
            print("⚠️ Không tìm thấy member với userId=$userId");
            return members.isNotEmpty ? members[0] : Member(id: '', name: '');
          },
        );

        print("🔍 DEBUG - Selected member: id=${myMember.id}, name=${myMember.name}");

        if (mounted && myMember.id.isNotEmpty) {
          setState(() {
            selectedMemberId = myMember.id;
          });
          print("✅ Updated selectedMemberId = $selectedMemberId");
        }
      } else {
        print("⚠️ userId rỗng, fallback về memberName");
        // Fallback: tìm theo memberName nếu không có userId
        if (widget.group.memberName != null) {
          final me = members.firstWhere(
            (m) => m.name == widget.group.memberName,
            orElse: () => members.isNotEmpty ? members[0] : Member(id: '', name: ''),
          );
          if (mounted && me.id.isNotEmpty) {
            setState(() {
              selectedMemberId = me.id;
            });
          }
        }
      }
    } catch (e) {
      print("❌ Error init current member: $e");
    }
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
    if (isSplitBill) {
      await addGroupExpense(thiscontext);
    } else {
      await addIndividualExpense(thiscontext);
    }
  }

  Future<void> addIndividualExpense(BuildContext thiscontext) async {
    await addExpense(
      amount: amount, 
      category: category, 
      dateTime: date, 
      context: thiscontext, 
      note: note
    );
    Navigator.pop(thiscontext); 
  }

  Future<void> addGroupExpense(BuildContext thiscontext) async {
    // Validate paidByMemberId không được rỗng
    if (selectedMemberId.isEmpty) {
      ScaffoldMessenger.of(thiscontext).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người chi tiền')),
      );
      return;
    }

    // 🔥 Không bắt buộc phải chọn người nợ
    // Nếu không chọn ai, tức là người trả chi tiền cho chính mình
    // Nếu có chọn, người trả sẽ được tự động thêm vào participants

    // API: POST /groups/{groupId}/expenses
    showLoading(thiscontext);

    // 🔥 API yêu cầu paidByMemberId phải nằm trong participantMemberIds
    // Tạo list participants bao gồm người trả + người nợ
    List<String> allParticipants = [...participantIds];
    if (!allParticipants.contains(selectedMemberId)) {
      allParticipants.add(selectedMemberId);
    }

    final body = {
      "title": note.isEmpty ? category : note,
      "amount": amount,
      "category": category, // Thêm category
      "splitType": "equal",
      "paidByMemberId": selectedMemberId,
      "participantMemberIds": allParticipants, // Bao gồm cả người trả
    };

    print("🔍 DEBUG - Request body: $body");
    print("🔍 DEBUG - Group ID: ${widget.group.id}");
    print("🔍 DEBUG - Paid by: $selectedMemberId");

    ApiUtil.getInstance()!.post(
      url: "http://localhost:3001/groups/${widget.group.id}/expenses",
      body: body,
      onSuccess: (response) {
        print("✅ Add group expense success: ${response.data}");
        hideLoading();
        Navigator.pop(thiscontext, true);
      },
      onError: (error) {
        print("❌ Add group expense error: $error");
        hideLoading();
        ScaffoldMessenger.of(thiscontext).showSnackBar(
          SnackBar(content: Text('Lỗi: $error')),
        );
      },
    );
  }

  String formatDate(DateTime d) {
    if (DateTime.now().day == d.day) return "Hôm nay";
    if (DateTime.now().subtract(const Duration(days: 1)).day == d.day) {
      return "Hôm nay";
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
        title: const Text('Thêm chi tiêu'),
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
                  // Row(
                  //   children: [
                  //     const Icon(BootstrapIcons.person, color: AppColors.blackIcon, size: 28),
                  //     const SizedBox(width: 15),
                  //     Expanded(
                  //       child: DropdownButtonFormField<String>(
                  //         value: selectedMemberId.isNotEmpty ? selectedMemberId : null,
                  //         items: members.map((member) {
                  //           return DropdownMenuItem<String>(
                  //             value: member.id,
                  //             child: Text(
                  //               member.name,
                  //               style: const TextStyle(fontSize: 18, color: AppColors.blackIcon),
                  //             ),
                  //           );
                  //         }).toList(),
                  //         onChanged: (value) {
                  //           setState(() {
                  //             selectedMemberId = value!;
                  //           });
                  //         },
                  //         decoration: const InputDecoration(
                  //           hintText: 'Chọn thành viên',
                            
                  //         ),
                  //         dropdownColor: Colors.white,
                  //         style: const TextStyle(
                  //           fontSize: 18,
                  //           // color: Colors.orange,
                  //         ),
                  //       ),),
                  //   ],
                  // ),
                  // const SizedBox(height: 15),

                  /// Note
                  Row(
                    children: [
                      const Icon(BootstrapIcons.text_left,
                          size: 28, color: AppColors.blackIcon),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
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

                  const SizedBox(height: 15),

                  /// Split Bill toggle
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        const Icon(BootstrapIcons.people, color: AppColors.blackIcon, size: 28),
                        const SizedBox(width: 15),
                        const Text(
                          "Chia sẻ chi phí",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Switch(
                          value: isSplitBill,
                          onChanged: (val) {
                            setState(() {
                              isSplitBill = val;
                              if (!isSplitBill) {
                                // Khi tắt chia tiền, clear danh sách người nợ
                                participantIds = [];
                              }
                              // Khi bật, để trống cho user tự chọn
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  if (isSplitBill)
                    Padding(
                      padding: const EdgeInsets.only(left: 43, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1️⃣ Chọn người trả (dropdown)
                          const Text(
                            "1. Chọn người đã chi tiền:",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedMemberId.isEmpty ? null : selectedMemberId,
                            decoration: const InputDecoration(
                              hintText: 'Chọn người trả',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: members.map((member) {
                              // 🔥 Hiển thị "(bạn)" nếu đây là user hiện tại
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
                                // Khi đổi người trả, xóa người trả cũ khỏi participantIds nếu có
                                // và đảm bảo người trả mới không nằm trong participantIds
                                participantIds.remove(selectedMemberId);
                              });
                            },
                          ),
                          if (selectedMemberId.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                "⚠️ Vui lòng chọn người đã chi tiền",
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),

                          // 2️⃣ Chọn người nợ (checkbox) - Chỉ hiển thị sau khi đã chọn người trả
                          if (selectedMemberId.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            const Text(
                              "2. Chọn người nợ (người phải trả):",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            ...members.where((m) => m.id != selectedMemberId).map((member) {
                              final isSelected = participantIds.contains(member.id);
                              // 🔥 Hiển thị "(bạn)" nếu đây là user hiện tại
                              final displayName = member.userId == currentUserId
                                  ? '${member.name} (bạn)'
                                  : member.name;
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!participantIds.contains(member.id)) {
                                        participantIds.add(member.id);
                                      }
                                    } else {
                                      participantIds.remove(member.id);
                                    }
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            }).toList(),
                            // 🔥 Không bắt buộc chọn người nợ
                            // Nếu không chọn, người trả sẽ chi tiền cho chính mình
                          ],
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