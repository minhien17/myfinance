import 'package:my_finance/utils.dart';

class GroupExpense {
  final String? id;
  final String title;
  final double amount;
  final String splitType; // e.g., "equal"
  final String paidByMemberId;
  final List<String> participantMemberIds;
  final DateTime? createdAt;

  GroupExpense({
    this.id,
    required this.title,
    required this.amount,
    this.splitType = "equal",
    required this.paidByMemberId,
    required this.participantMemberIds,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'splitType': splitType,
      'paidByMemberId': paidByMemberId,
      'participantMemberIds': participantMemberIds,
    };
  }

  factory GroupExpense.fromJson(Map<String, dynamic> json) {
    return GroupExpense(
      id: json['id']?.toString(),
      title: json['title'] ?? '',
      amount: Common.parseDouble(json['amount']),
      splitType: json['splitType'] ?? 'equal',
      paidByMemberId: json['paidByMemberId']?.toString() ?? '',
      participantMemberIds: List<String>.from(json['participantMemberIds'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class GroupExpenseShare {
  final String id;
  final String memberId;
  final String? userId;
  final double amount;
  final bool isPaid;
  final DateTime? paidAt;

  GroupExpenseShare({
    required this.id,
    required this.memberId,
    this.userId,
    required this.amount,
    this.isPaid = false,
    this.paidAt,
  });

  factory GroupExpenseShare.fromJson(Map<String, dynamic> json) {
    return GroupExpenseShare(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      userId: json['userId']?.toString(),
      amount: Common.parseDouble(json['amount']),
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}
