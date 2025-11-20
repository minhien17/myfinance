import 'package:flutter/material.dart';

class TransactionModel {
  String? _id;            // Định danh duy nhất cho mỗi khoản chi
  double? _amount;        // Số tiền chi tiêu
  String? _category;      // Mục chi tiêu
  String? _note;          // Ghi chú thêm (có thể null)
  DateTime? _dateTime;    // Thời gian phát sinh khoản chi
  String? _owner;

  TransactionModel();

  // Constructor đầy đủ
  TransactionModel.full({
    String? id,
    double? amount,
    String? category,
    String? note,
    DateTime? dateTime,
    String? owner,
  })  : _id = id,
        _amount = amount,
        _category = category,
        _note = note,
        _dateTime = dateTime,
        _owner = owner;

  // fromJson
  TransactionModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _amount = (json['amount'] as num?)?.toDouble();
    _category = (json['category'] ?? '').toString().toLowerCase();
    _note = json['note'];
    _dateTime = json['dateTime'] != null ? DateTime.parse(json['dateTime']) : null;
    _owner = json['owner'];
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      if (_id != null && _id!.isNotEmpty) 'id': _id,
      'amount': _amount,
      'category': _category,
      'note': _note,
      'dateTime': _dateTime?.toIso8601String(),
    };
  }

  // -------- GETTER --------
  String get id => _id ?? "";
  double get amount => _amount ?? 0.0;
  String get category => _category ?? "other";
  String? get note => _note;
  DateTime get dateTime => _dateTime ?? DateTime.now();
  String get owner => _owner ?? "Hiển";

  String get formattedDate =>
      "${dateTime.day}/${dateTime.month}/${dateTime.year}";

}


// 💡 Giả định Model Dữ liệu Top Chi tiêu đã tổng hợp
class TopExpenseModel {
  final String category;
  final double amount;
  final Color color; 

  TopExpenseModel({
    required this.category,
    required this.amount,
    required this.color,
  });

  // Chỉ để in ra kiểm tra
  @override
  String toString() => '{"category": "$category", "amount": $amount, "color": "$color"}';
}

// Bảng màu cố định cho Top 5
const List<Color> fixedColors = [
  Colors.redAccent,
  Colors.orange,
  Colors.blueAccent,
  Colors.green,
  Colors.purple,
];

