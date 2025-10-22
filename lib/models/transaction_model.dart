class TransactionModel {
  String? _id;            // Định danh duy nhất cho mỗi khoản chi
  double? _amount;        // Số tiền chi tiêu
  String? _category;      // Mục chi tiêu
  String? _note;          // Ghi chú thêm (có thể null)
  DateTime? _dateTime;    // Thời gian phát sinh khoản chi
  String? _type;          // income / expense

  TransactionModel();

  // Constructor đầy đủ
  TransactionModel.full({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? dateTime,
    String? type,
  })  : _id = id,
        _amount = amount,
        _category = category,
        _note = note,
        _dateTime = dateTime,
        _type = type;

  // fromJson
  TransactionModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _amount = (json['amount'] as num?)?.toDouble();
    _category = json['category'];
    _note = json['note'];
    _dateTime = json['dateTime'] != null ? DateTime.parse(json['dateTime']) : null;
    _type = json['type'];
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'amount': _amount,
      'category': _category,
      'note': _note,
      'dateTime': _dateTime?.toIso8601String(),
      'type': _type,
    };
  }

  // -------- GETTER --------
  String get id => _id ?? "";
  double get amount => _amount ?? 0.0;
  String get category => _category ?? "other";
  String? get note => _note;
  DateTime get dateTime => _dateTime ?? DateTime.now();
  String get type => _type ?? "expense";

  // -------- GETTER TIỆN ÍCH --------
  bool get isIncome => type == "income";
  bool get isExpense => type == "expense";

  String get formattedDate =>
      "${dateTime.day}/${dateTime.month}/${dateTime.year}";

  String get shortInfo => "$category: $amount (${isIncome ? 'Income' : 'Expense'})";
}
