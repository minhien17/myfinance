import 'package:my_finance/utils.dart';

class DebtModel {
  final String shareId;
  final String expenseId;
  final String expenseTitle;
  final double totalAmount;
  final double shareAmount;
  final String? paidByMemberId; // Used for "My Debts"
  final String? debtorMemberId; // Used for "Owed to me"
  final bool isPaid;
  final DateTime? createdAt;

  DebtModel({
    required this.shareId,
    required this.expenseId,
    required this.expenseTitle,
    required this.totalAmount,
    required this.shareAmount,
    this.paidByMemberId,
    this.debtorMemberId,
    required this.isPaid,
    this.createdAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      shareId: json['shareId']?.toString() ?? '',
      expenseId: json['expenseId']?.toString() ?? '',
      expenseTitle: json['expenseTitle'] ?? '',
      totalAmount: Common.parseDouble(json['totalAmount']),
      shareAmount: Common.parseDouble(json['shareAmount'] ?? json['myShare']),
      paidByMemberId: json['paidByMemberId']?.toString(),
      debtorMemberId: json['debtorMemberId']?.toString(),
      isPaid: json['isPaid'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
