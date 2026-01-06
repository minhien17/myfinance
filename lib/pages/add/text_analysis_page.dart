import 'package:flutter/material.dart';
import 'package:my_finance/api/api_end_point.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/common/flutter_toast.dart';
import 'package:my_finance/common/loading_dialog.dart';
import 'package:my_finance/models/list_icon.dart';
import 'package:my_finance/models/text_analysis_model.dart';
import 'package:my_finance/res/app_colors.dart';
import 'package:my_finance/utils.dart';

class TextAnalysisPage extends StatefulWidget {
  const TextAnalysisPage({super.key});

  @override
  State<TextAnalysisPage> createState() => _TextAnalysisPageState();
}

class _TextAnalysisPageState extends State<TextAnalysisPage> {
  final TextEditingController _textController = TextEditingController();
  List<AnalyzedTransaction> _transactions = [];
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;

  // Phân tích văn bản
  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      toastInfo(msg: "Vui lòng nhập văn bản");
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.analyzeAndSave,
      body: {"text": text},
      onSuccess: (response) {
        final result = TextAnalysisResult.fromJson(response.data);

        // Debug: In ra dữ liệu backend trả về
        for (var t in result.transactions) {
          print('Backend: category=${t.category}, sentence="${t.sentence}", matchedText="${t.matchedText}", editedNote="${t.editedNote}"');
        }

        setState(() {
          _transactions = result.transactions;
          _hasAnalyzed = true;
          _isAnalyzing = false;
        });

        if (_transactions.isEmpty) {
          toastInfo(msg: "Không tìm thấy giao dịch nào");
        }
      },
      onError: (error) {
        setState(() {
          _isAnalyzing = false;
        });
        toastInfo(msg: "Lỗi phân tích: $error");
      },
    );
  }

  // Lưu các giao dịch đã chọn
  Future<void> _saveSelectedTransactions() async {
    final selectedTransactions =
        _transactions.where((t) => t.isSelected).toList();

    if (selectedTransactions.isEmpty) {
      toastInfo(msg: "Vui lòng chọn ít nhất 1 giao dịch");
      return;
    }

    showLoading(context);

    final body = {
      "transactions":
          selectedTransactions.map((t) => t.toSaveJson()).toList(),
    };

    ApiUtil.getInstance()!.post(
      url: ApiEndpoint.saveAnalyzedTransactions,
      body: body,
      onSuccess: (response) {
        hideLoading();
        toastInfo(msg: "Đã lưu ${selectedTransactions.length} giao dịch");
        Navigator.pop(context, true); // Trả về true để reload trang chính
      },
      onError: (error) {
        hideLoading();
        toastInfo(msg: "Lỗi lưu: $error");
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhập văn bản'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasAnalyzed && _transactions.isNotEmpty)
            TextButton(
              onPressed: _saveSelectedTransactions,
              child: const Text(
                'Lưu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Phần nhập text
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập văn bản chi tiêu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ví dụ: "mua tạp dề 50k. ăn phở 90k và cafe 35k"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nhập chi tiêu của bạn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _analyzeText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Phân tích',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách giao dịch đã phân tích
          if (_hasAnalyzed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm thấy ${_transactions.length} giao dịch',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_transactions.where((t) => t.isSelected).length} được chọn',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return _buildTransactionCard(transaction, index);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionCard(AnalyzedTransaction transaction, int index) {
    final categoryItem = ListIcon.firstWhere(
      (item) => item.title == transaction.editedCategory,
      orElse: () => ListIcon.last,
    );

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
        onTap: () => _showEditDialog(transaction),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: transaction.isSelected,
              onChanged: (value) {
                setState(() {
                  transaction.isSelected = value ?? false;
                });
              },
              activeColor: AppColors.green,
            ),
            // Icon danh mục
            SizedBox(
              width: 30,
              height: 30,
              child: categoryItem.img,
            ),
            const SizedBox(width: 12),
            // Thông tin giao dịch
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryItem.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.editedNote,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Số tiền
            Text(
              Common.formatNumber(transaction.editedAmount.toString()),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Nút edit
            IconButton(
              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
              onPressed: () => _showEditDialog(transaction),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(AnalyzedTransaction transaction) {
    final TextEditingController amountController =
        TextEditingController(text: transaction.editedAmount.toString());
    final TextEditingController noteController =
        TextEditingController(text: transaction.editedNote);

    // Validate category - nếu không tồn tại trong ListIcon thì dùng 'other'
    String selectedCategory = transaction.editedCategory;
    final categoryExists = ListIcon.any((item) => item.title == selectedCategory);
    if (!categoryExists) {
      selectedCategory = 'other';
      transaction.editedCategory = 'other';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sửa giao dịch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: ListIcon.map((item) {
                        return DropdownMenuItem(
                          value: item.title,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: item.img,
                              ),
                              const SizedBox(width: 8),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      transaction.editedAmount =
                          double.tryParse(amountController.text) ??
                              transaction.editedAmount;
                      transaction.editedNote = noteController.text;
                      transaction.editedCategory = selectedCategory;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
