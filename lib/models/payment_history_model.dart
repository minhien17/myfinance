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
  final String from; // Tên người
  final String? note;

  PaymentItem({
    required this.date,
    required this.type,
    required this.amount,
    required this.expenseTitle,
    required this.category,
    required this.from,
    this.note,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      type: json['type'] ?? '',
      amount: Common.parseDouble(json['amount']),
      expenseTitle: json['expenseTitle'] ?? '',
      category: json['category'] ?? '',
      from: json['from'] ?? '',
      note: json['note'],
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
