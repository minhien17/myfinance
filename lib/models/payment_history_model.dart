import 'package:my_finance/utils.dart';

class PaymentHistoryModel {
  final String month;
  final List<PaymentItem> payments;
  final PaymentSummary summary;

  PaymentHistoryModel({
    required this.month,
    required this.payments,
    required this.summary,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      month: json['month'] ?? '',
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => PaymentItem.fromJson(e))
          .toList() ?? [],
      summary: PaymentSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class PaymentItem {
  final DateTime date;
  final String type; // "paid" hoặc "received"
  final double amount;
  final String expenseTitle;
  final String category;
  final String? from; // Tên người (cho "received")
  final String? to; // Tên người (cho "paid")
  final String? fromMemberId; // ID người trả (cho "received")
  final String? toMemberId; // ID người nhận (cho "paid")
  final String? note;

  PaymentItem({
    required this.date,
    required this.type,
    required this.amount,
    required this.expenseTitle,
    required this.category,
    this.from,
    this.to,
    this.fromMemberId,
    this.toMemberId,
    this.note,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    // Helper để parse field, convert "null" string thành null
    String? parseNullableString(dynamic value) {
      if (value == null) return null;
      if (value == 'null') return null;  // String "null"
      final str = value.toString();
      if (str.isEmpty || str == 'null') return null;
      return str;
    }

    return PaymentItem(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? '',
      amount: Common.parseDouble(json['amount']),
      expenseTitle: json['expenseTitle'] ?? '',
      category: json['category'] ?? '',
      from: parseNullableString(json['from']),
      to: parseNullableString(json['to']),
      fromMemberId: parseNullableString(json['fromMemberId']),
      toMemberId: parseNullableString(json['toMemberId']),
      note: parseNullableString(json['note']),
    );
  }
}

class PaymentSummary {
  final double totalPaid;
  final double totalReceived;
  final double net;

  PaymentSummary({
    required this.totalPaid,
    required this.totalReceived,
    required this.net,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalPaid: Common.parseDouble(json['totalPaid']),
      totalReceived: Common.parseDouble(json['totalReceived']),
      net: Common.parseDouble(json['net']),
    );
  }
}
