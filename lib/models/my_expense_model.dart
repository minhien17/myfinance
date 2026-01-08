import 'package:my_finance/utils.dart';

/// Model cho một transaction trong expense
class ExpenseTransaction {
  final String id;
  final double amount;
  final String category;
  final String note;
  final DateTime? dateTime;

  ExpenseTransaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.note,
    this.dateTime,
  });

  factory ExpenseTransaction.fromJson(Map<String, dynamic> json) {
    return ExpenseTransaction(
      id: json['id']?.toString() ?? '',
      amount: Common.parseDouble(json['amount']),
      category: json['category'] ?? 'other',
      note: json['note'] ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime'].toString())
          : null,
    );
  }
}

/// Model cho một share (phần chia) trong expense
class ExpenseShare {
  final String id;
  final String memberId;
  final String memberName;
  final String? membersUserId;
  final double amount;
  final bool isPaid;
  final DateTime? paidAt;
  // Payment proof fields
  final String? proofImageUrl;     // URL ảnh chứng minh thanh toán
  final String? proofStatus;       // pending, approved, rejected, null
  final DateTime? proofUploadedAt; // Thời gian upload ảnh

  ExpenseShare({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.membersUserId,
    required this.amount,
    required this.isPaid,
    this.paidAt,
    this.proofImageUrl,
    this.proofStatus,
    this.proofUploadedAt,
  });

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      memberName: json['memberName'] ?? '',
      membersUserId: json['membersUserId']?.toString(),
      amount: Common.parseDouble(json['amount']),
      isPaid: json['isPaid'] == true,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())
          : null,
      proofImageUrl: json['proofImageUrl']?.toString(),
      proofStatus: json['proofStatus']?.toString(),
      proofUploadedAt: json['proofUploadedAt'] != null
          ? DateTime.tryParse(json['proofUploadedAt'].toString())
          : null,
    );
  }

  /// Kiểm tra xem đã có ảnh chứng minh chưa
  bool get hasProof => proofImageUrl != null && proofImageUrl!.isNotEmpty;

  /// Kiểm tra xem ảnh chứng minh đang chờ duyệt
  bool get isProofPending => proofStatus == 'pending';
}

/// Model cho một expense (chi tiêu nhóm)
class MyExpenseModel {
  final String id;
  final String title;
  final String groupId;
  final String paidByMemberId;
  final String paidByMemberName;
  final String createdByUserId;
  final String splitType;
  final DateTime createdAt;
  final double totalAmount;
  final List<ExpenseTransaction> transactions;
  final List<ExpenseShare> shares;

  MyExpenseModel({
    required this.id,
    required this.title,
    required this.groupId,
    required this.paidByMemberId,
    required this.paidByMemberName,
    required this.createdByUserId,
    required this.splitType,
    required this.createdAt,
    required this.totalAmount,
    required this.transactions,
    required this.shares,
  });

  factory MyExpenseModel.fromJson(Map<String, dynamic> json) {
    return MyExpenseModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      groupId: json['groupId']?.toString() ?? '',
      paidByMemberId: json['paidByMemberId']?.toString() ?? '',
      paidByMemberName: json['paidByMemberName'] ?? '',
      createdByUserId: json['createdByUserId']?.toString() ?? '',
      splitType: json['splitType'] ?? 'equal',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      totalAmount: Common.parseDouble(json['totalAmount']),
      transactions: (json['transactions'] as List<dynamic>?)
          ?.map((e) => ExpenseTransaction.fromJson(e))
          .toList() ?? [],
      shares: (json['shares'] as List<dynamic>?)
          ?.map((e) => ExpenseShare.fromJson(e))
          .toList() ?? [],
    );
  }

  /// Lấy category chính (từ transaction đầu tiên hoặc 'other')
  String get mainCategory {
    if (transactions.isNotEmpty) {
      return transactions.first.category;
    }
    return 'other';
  }

  /// Kiểm tra xem expense này có phải do user hiện tại trả không
  bool isPaidByUser(String userId) {
    // Kiểm tra qua createdByUserId hoặc qua shares
    return createdByUserId == userId;
  }

  /// Lấy share của một user cụ thể
  ExpenseShare? getShareForUser(String memberId) {
    try {
      return shares.firstWhere((s) => s.memberId == memberId);
    } catch (e) {
      return null;
    }
  }
}

/// Model cho response của API my-expenses
class MyExpensesResponse {
  final List<MyExpenseModel> expenses;
  final MyExpensesSummary summary;

  MyExpensesResponse({
    required this.expenses,
    required this.summary,
  });

  factory MyExpensesResponse.fromJson(Map<String, dynamic> json) {
    return MyExpensesResponse(
      expenses: (json['expenses'] as List<dynamic>?)
          ?.map((e) => MyExpenseModel.fromJson(e))
          .toList() ?? [],
      summary: MyExpensesSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

/// Model cho summary của my-expenses
class MyExpensesSummary {
  final double totalPaid;      // Tổng tiền đã trả cho nhóm
  final double totalOwed;      // Tổng tiền phải trả (phần của mình)
  final double totalReceived;  // Tổng tiền đã nhận lại
  final double balance;        // Số dư (totalPaid - totalOwed)

  MyExpensesSummary({
    required this.totalPaid,
    required this.totalOwed,
    required this.totalReceived,
    required this.balance,
  });

  factory MyExpensesSummary.fromJson(Map<String, dynamic> json) {
    return MyExpensesSummary(
      totalPaid: Common.parseDouble(json['totalPaid']),
      totalOwed: Common.parseDouble(json['totalOwed']),
      totalReceived: Common.parseDouble(json['totalReceived']),
      balance: Common.parseDouble(json['balance']),
    );
  }
}
