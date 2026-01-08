import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/icon.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/models/text_analysis_model.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/shared_preference.dart';
import 'split_expense_page.dart';

/// Model cho một transaction item
class TransactionItem {
  double amount;
  String category;
  String note;

  TransactionItem({
    this.amount = 0,
    this.category = 'food',
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'category': category,
      'note': note.isEmpty ? category : note,
    };
  }
}

/// Màn hình 1: Nhập thông tin cơ bản (nhiều transactions, người trả)
class AddGroupExpensePage extends StatefulWidget {
  final Group group;
  const AddGroupExpensePage({super.key, required this.group});

  @override
  State<AddGroupExpensePage> createState() => _AddGroupExpensePageState();
}

class _AddGroupExpensePageState extends State<AddGroupExpensePage> {
  final TextEditingController titleController = TextEditingController();

  // Danh sách transactions
  List<TransactionItem> transactions = [];
  List<TextEditingController> amountControllers = [];
  List<TextEditingController> noteControllers = [];

  DateTime date = DateTime.now();
  String title = '';

  List<Member> members = [];
  String selectedMemberId = '';
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    // Chỉ lấy những thành viên đã tham gia (joined = true)
    members = widget.group.members.where((m) => m.joined).toList();
    if (members.isNotEmpty) {
      selectedMemberId = members[0].id;
    }
    _initCurrentMember();

    // Thêm transaction đầu tiên mặc định
    _addTransaction();
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
    titleController.dispose();
    for (var controller in amountControllers) {
      controller.dispose();
    }
    for (var controller in noteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Thêm một transaction mới
  void _addTransaction({double? amount, String? category, String? note}) {
    setState(() {
      transactions.add(TransactionItem(
        amount: amount ?? 0,
        category: category ?? 'food',
        note: note ?? '',
      ));
      final amountCtrl = TextEditingController(
        text: amount != null && amount > 0 ? amount.toStringAsFixed(0) : '',
      );
      amountControllers.add(amountCtrl);
      noteControllers.add(TextEditingController(text: note ?? ''));
    });
  }

  // Xóa một transaction
  void _removeTransaction(int index) {
    if (transactions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 1 khoản chi tiêu')),
      );
      return;
    }
    setState(() {
      transactions.removeAt(index);
      amountControllers[index].dispose();
      amountControllers.removeAt(index);
      noteControllers[index].dispose();
      noteControllers.removeAt(index);
    });
  }

  // Tính tổng tiền
  double get totalAmount {
    return transactions.fold(0, (sum, t) => sum + t.amount);
  }

  void datePicker() async {
    final now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date.isAfter(now) ? now : date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
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
    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền cho ít nhất 1 khoản')),
      );
      return;
    }
    if (selectedMemberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người chi tiền')),
      );
      return;
    }

    // Lọc các transactions có amount > 0
    final validTransactions = transactions.where((t) => t.amount > 0).toList();

    // Tạo title mặc định nếu không nhập
    String expenseTitle = title.isNotEmpty
        ? title
        : validTransactions.map((t) => t.note.isEmpty ? titleOf(t.category) : t.note).join(', ');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitExpensePage(
          group: widget.group,
          title: expenseTitle,
          transactions: validTransactions.map((t) => t.toJson()).toList(),
          totalAmount: totalAmount,
          date: date,
          paidByMemberId: selectedMemberId,
          paidByMember: members.firstWhere((m) => m.id == selectedMemberId),
          members: members,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  // ========== TEXT ANALYSIS ==========
  void _showTextAnalysisBottomSheet() {
    final textController = TextEditingController();
    bool isAnalyzing = false;
    List<AnalyzedTransaction> analyzedTransactions = [];
    bool hasAnalyzed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Nhập văn bản chi tiêu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: hasAnalyzed && analyzedTransactions.any((t) => t.isSelected)
                              ? () {
                                  _applyAnalyzedTransactions(analyzedTransactions);
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            'Áp dụng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasAnalyzed && analyzedTransactions.any((t) => t.isSelected)
                                  ? AppColors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Input section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                      color: Colors.amber.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Phân tích tự động',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ví dụ: "ăn phở 50k, cafe 30k, grab về 25k"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: textController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập chi tiêu của bạn...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: isAnalyzing
                                        ? null
                                        : () async {
                                            final text = textController.text.trim();
                                            if (text.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Vui lòng nhập văn bản')),
                                              );
                                              return;
                                            }

                                            setModalState(() {
                                              isAnalyzing = true;
                                            });

                                            ApiUtil.getInstance()!.post(
                                              url: ApiEndpoint.analyzeText,
                                              body: {"text": text},
                                              onSuccess: (response) {
                                                final result = TextAnalysisResult.fromJson(response.data);
                                                setModalState(() {
                                                  analyzedTransactions = result.transactions;
                                                  hasAnalyzed = true;
                                                  isAnalyzing = false;
                                                });

                                                if (result.transactions.isEmpty) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Không tìm thấy giao dịch nào')),
                                                  );
                                                }
                                              },
                                              onError: (error) {
                                                setModalState(() {
                                                  isAnalyzing = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi: $error')),
                                                );
                                              },
                                            );
                                          },
                                    icon: isAnalyzing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.auto_awesome, size: 18),
                                    label: Text(isAnalyzing ? 'Đang phân tích...' : 'Phân tích'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Results section
                          if (hasAnalyzed) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tìm thấy ${analyzedTransactions.length} khoản',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${analyzedTransactions.where((t) => t.isSelected).length} được chọn',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...analyzedTransactions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final transaction = entry.value;
                              return _buildAnalyzedTransactionCard(
                                transaction,
                                index,
                                setModalState,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyzedTransactionCard(
    AnalyzedTransaction transaction,
    int index,
    StateSetter setModalState,
  ) {
    // Validate category
    String validCategory = transaction.editedCategory;
    final categoryExists = ListIconGroup.any((item) => item.title == validCategory);
    if (!categoryExists) {
      validCategory = 'other';
      transaction.editedCategory = 'other';
    }

    final categoryItem = ListIconGroup.firstWhere(
      (item) => item.title == validCategory,
      orElse: () => ListIconGroup.last,
    );

    return InkWell(
      onTap: () => _showEditAnalyzedTransactionDialog(transaction, setModalState),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: transaction.isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: transaction.isSelected ? Colors.green.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: transaction.isSelected,
              onChanged: (value) {
                setModalState(() {
                  transaction.isSelected = value ?? false;
                });
              },
              activeColor: AppColors.green,
            ),
            // Icon
            SizedBox(
              width: 36,
              height: 36,
              child: categoryItem.img,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryItem.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.editedNote,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${transaction.editedAmount.toStringAsFixed(0)}đ',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Edit icon
            const SizedBox(width: 8),
            Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showEditAnalyzedTransactionDialog(
    AnalyzedTransaction transaction,
    StateSetter setModalState,
  ) {
    final amountController = TextEditingController(
      text: transaction.editedAmount.toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: transaction.editedNote);

    // Validate category
    String selectedCategory = transaction.editedCategory;
    final categoryExists = ListIconGroup.any((item) => item.title == selectedCategory);
    if (!categoryExists) {
      selectedCategory = 'other';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Sửa khoản chi tiêu'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Số tiền
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Số tiền',
                        suffixText: 'đ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Danh mục
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ListIconGroup.map((item) {
                        return DropdownMenuItem(
                          value: item.title,
                          child: Row(
                            children: [
                              SizedBox(width: 24, height: 24, child: item.img),
                              const SizedBox(width: 12),
                              Text(item.description),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Cập nhật transaction
                    setModalState(() {
                      transaction.editedAmount =
                          double.tryParse(amountController.text) ?? transaction.editedAmount;
                      transaction.editedNote = noteController.text;
                      transaction.editedCategory = selectedCategory;
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyAnalyzedTransactions(List<AnalyzedTransaction> analyzedTransactions) {
    final selectedTransactions = analyzedTransactions.where((t) => t.isSelected).toList();

    if (selectedTransactions.isEmpty) return;

    // Xóa transaction mặc định nếu chưa nhập gì
    if (transactions.length == 1 && transactions[0].amount == 0) {
      setState(() {
        transactions.clear();
        for (var ctrl in amountControllers) {
          ctrl.dispose();
        }
        amountControllers.clear();
        for (var ctrl in noteControllers) {
          ctrl.dispose();
        }
        noteControllers.clear();
      });
    }

    // Thêm các transactions từ phân tích
    for (var t in selectedTransactions) {
      // Validate category cho ListIconGroup
      String validCategory = t.editedCategory;
      final categoryExists = ListIconGroup.any((item) => item.title == validCategory);
      if (!categoryExists) {
        validCategory = 'other';
      }

      _addTransaction(
        amount: t.editedAmount,
        category: validCategory,
        note: t.editedNote,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${selectedTransactions.length} khoản chi tiêu'),
        backgroundColor: AppColors.green,
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
            onPressed: totalAmount > 0 ? goToSplitPage : null,
            child: Text(
              'Tiếp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: totalAmount > 0 ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.line),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== THÔNG TIN CHUNG ==========
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề chi tiêu (optional)
                    Row(
                      children: [
                        const Icon(BootstrapIcons.card_heading,
                            size: 28, color: AppColors.blackIcon),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              hintText: 'Tiêu đề (tùy chọn)',
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 18),
                            onChanged: (value) {
                              setState(() {
                                title = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

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
                    const Divider(),

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

              const SizedBox(height: 16),

              // ========== DANH SÁCH TRANSACTIONS ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Các khoản chi tiêu (${transactions.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        // Nút nhập văn bản (Text Analysis)
                        TextButton.icon(
                          onPressed: _showTextAnalysisBottomSheet,
                          icon: Icon(Icons.auto_awesome,
                            size: 18, color: Colors.amber.shade700),
                          label: Text('AI', style: TextStyle(color: Colors.amber.shade700)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.amber.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút thêm thủ công
                        TextButton.icon(
                          onPressed: () => _addTransaction(),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Thêm'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Danh sách các transaction items
              ...transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final transaction = entry.value;
                return _buildTransactionItem(index, transaction);
              }),

              const SizedBox(height: 16),

              // ========== TỔNG TIỀN ==========
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
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
                    onPressed: totalAmount > 0 ? goToSplitPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: totalAmount > 0 ? Colors.green : Colors.grey[300],
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
      ),
    );
  }

  // Widget cho mỗi transaction item
  Widget _buildTransactionItem(int index, TransactionItem transaction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header với số thứ tự và nút xóa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Khoản ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              if (transactions.length > 1)
                IconButton(
                  onPressed: () => _removeTransaction(index),
                  icon: Icon(Icons.remove_circle_outline,
                    color: Colors.red.shade400, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Số tiền
          Row(
            children: [
              const Icon(BootstrapIcons.cash_stack,
                  color: AppColors.blackIcon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: amountControllers[index],
                  onChanged: (input) {
                    setState(() {
                      transaction.amount = double.tryParse(input) ?? 0;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: 'đ',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Loại chi tiêu
          Row(
            children: [
              const Icon(BootstrapIcons.tag,
                  size: 24, color: AppColors.blackIcon),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  value: _getValidCategory(transaction.category),
                  onChanged: (value) {
                    setState(() => transaction.category = value!);
                  },
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  items: ListIconGroup.map((ItemIcon item) {
                    return DropdownMenuItem<String>(
                      value: item.title,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: item.img,
                          ),
                          const SizedBox(width: 12),
                          Text(titleOf(item.title)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ghi chú
          Row(
            children: [
              const Icon(BootstrapIcons.text_left,
                  size: 24, color: AppColors.blackIcon),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: noteControllers[index],
                  decoration: const InputDecoration(
                    hintText: 'Ghi chú (tùy chọn)',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 15),
                  onChanged: (value) {
                    setState(() {
                      transaction.note = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Validate category - trả về category hợp lệ trong ListIconGroup
  String _getValidCategory(String category) {
    final exists = ListIconGroup.any((item) => item.title == category);
    return exists ? category : 'food';
  }
}
